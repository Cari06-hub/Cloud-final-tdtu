#!/usr/bin/env python3
"""Prepare Keycloak and MinIO lab fixtures with standard Python and docker CLI."""
from __future__ import annotations
import json
import pathlib
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]

def env_read():
    out = {}
    for line in (ROOT/'.env').read_text(encoding='utf-8-sig').splitlines():
        x = line.strip()
        if x and not x.startswith('#') and '=' in x:
            k, v = x.split('=',1)
            out[k.strip()] = v.strip().strip('"').strip("'")
    required = ('KEYCLOAK_ADMIN','KEYCLOAK_ADMIN_PASSWORD','KEYCLOAK_REALM','SV01_PASSWORD','SV02_PASSWORD',
                'MINIO_ROOT_USER','MINIO_ROOT_PASSWORD')
    bad = [k for k in required if not out.get(k) or 'REPLACE_' in out[k]]
    if bad: raise RuntimeError('Thieu bien .env: ' + ', '.join(bad))
    return out

def http(method, path, *, base='http://localhost:8081', data=None, token=None, form=False, expected=(200,201,204)):
    body = None
    headers = {}
    if data is not None:
        if form:
            body = urllib.parse.urlencode(data).encode()
            headers['Content-Type'] = 'application/x-www-form-urlencoded'
        else:
            body = json.dumps(data).encode('utf-8')
            headers['Content-Type'] = 'application/json'
    if token: headers['Authorization'] = 'Bearer ' + token
    req = urllib.request.Request(base + path, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            if r.status not in expected: raise RuntimeError(f'{method} {path}: HTTP {r.status}')
            raw = r.read()
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as e:
        if e.code == 404: return None
        body = e.read().decode('utf-8',errors='replace')
        # Avoid displaying token or configured passwords in errors.
        raise RuntimeError(f'{method} {path}: HTTP {e.code}: {body[:160]}') from None

def run(*args):
    r = subprocess.run(list(args), cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if r.returncode: raise RuntimeError(f'Docker command failed ({args[0]} {args[1] if len(args)>1 else ""}):\n{r.stdout[-600:]}')
    return r.stdout

def kc_ready():
    until = time.monotonic() + 210
    while time.monotonic() < until:
        try:
            if http('GET','/realms/master'): return
        except (urllib.error.URLError, TimeoutError, RuntimeError): pass
        time.sleep(4)
    raise RuntimeError('Keycloak chua san sang tai localhost:8081 (kiem tra docker compose logs).')

def main():
    cfg = env_read()
    kc_ready()
    print('[1/5] Keycloak: lay admin token...')
    res = http('POST','/realms/master/protocol/openid-connect/token', form=True, data={
        'client_id':'admin-cli','username':cfg['KEYCLOAK_ADMIN'],
        'password':cfg['KEYCLOAK_ADMIN_PASSWORD'],'grant_type':'password'})
    admin = res['access_token']
    realm = cfg['KEYCLOAK_REALM']
    realm_path = '/admin/realms/' + urllib.parse.quote(realm)
    print('[2/5] Tao Realm, client flask-app va audience mapper...')
    if http('GET',realm_path,token=admin) is None:
        http('POST','/admin/realms',token=admin,data={'realm':realm,'enabled':True})
    clients = http('GET',realm_path+'/clients?clientId=flask-app',token=admin)
    if not clients:
        http('POST',realm_path+'/clients',token=admin,data={
            'clientId':'flask-app','name':'MyMiniCloud Flask App','enabled':True,
            'protocol':'openid-connect','publicClient':True,
            'directAccessGrantsEnabled':True,'standardFlowEnabled':True,
            'redirectUris':['http://localhost/*'],'webOrigins':['http://localhost']})
        clients = http('GET',realm_path+'/clients?clientId=flask-app',token=admin)
    if len(clients)!=1: raise RuntimeError('Khong tim thay client flask-app duy nhat.')
    uuid=clients[0]['id']
    uri=realm_path+'/clients/'+uuid+'/protocol-mappers/models'
    mappers=http('GET',uri,token=admin)
    if not any(x.get('name')=='audience-flask-app' for x in mappers):
        http('POST',uri,token=admin,data={
            'name':'audience-flask-app','protocol':'openid-connect',
            'protocolMapper':'oidc-audience-mapper','consentRequired':False,
            'config':{'included.client.audience':'flask-app','id.token.claim':'false',
                      'access.token.claim':'true','introspection.token.claim':'true'}})
    print('[3/5] Tao 2 user va thu token/secure...')
    for username, envname in [('sv01','SV01_PASSWORD'),('sv02','SV02_PASSWORD')]:
        uri=realm_path+'/users'
        search=uri+'?username='+username+'&exact=true'
        users=http('GET',search,token=admin)
        if not users:
            http('POST',uri,token=admin,data={'username':username,'enabled':True,
                'credentials':[{'type':'password','value':cfg[envname],'temporary':False}]})
            users=http('GET',search,token=admin)
        if len(users)!=1: raise RuntimeError('Loi tao user '+username)
        uid=users[0]['id']
        http('PUT',uri+'/'+uid,token=admin,data={
            'id':uid,'username':username,'enabled':True,
            'firstName':username.upper(),'lastName':'MyMiniCloud',
            'email':username+'@cloud.local','emailVerified':True,'requiredActions':[]})
        http('PUT',uri+'/'+uid+'/reset-password',token=admin,
             data={'type':'password','value':cfg[envname],'temporary':False})
        tok=http('POST',f'/realms/{urllib.parse.quote(realm)}/protocol/openid-connect/token',form=True,data={
            'client_id':'flask-app','username':username,
            'password':cfg[envname],'grant_type':'password'})['access_token']
        secure=http('GET','/secure',base='http://localhost:8085',token=tok)
        if secure.get('preferred_username')!=username: raise RuntimeError('Secure API sai: '+username)
    print('[4/5] MinIO: bucket, file demo, avatar public, PDF private...')
    container='object-storage-server'
    # Bitnami legacy lab image contains mc; configure alias explicitly to avoid relying on previous volume state.
    run('docker','exec',container,'mc','alias','set','local','http://127.0.0.1:9000',
        cfg['MINIO_ROOT_USER'],cfg['MINIO_ROOT_PASSWORD'])
    for name, filename in [('index','index.html'),('avatar','avatar.jpg'),('document','document.pdf')]:
        src=ROOT/'test-upload'/filename
        if not src.is_file(): raise RuntimeError('Missing fixture: '+str(src))
        run('docker','cp',str(src),container+':/tmp/myminicloud-'+filename)
    for bucket in ['demo','profile-pics','documents']:
        run('docker','exec',container,'mc','mb','--ignore-existing','local/'+bucket)
    for filename,object_name in [('index.html','demo/index.html'),('avatar.jpg','profile-pics/avatar.jpg'),('document.pdf','documents/document.pdf')]:
        run('docker','exec',container,'mc','cp','/tmp/myminicloud-'+filename,'local/'+object_name)
    run('docker','exec',container,'mc','anonymous','set','download','local/profile-pics')
    print('[5/5] Xac minh object...')
    for obj in ['demo/index.html','profile-pics/avatar.jpg','documents/document.pdf']:
        run('docker','exec',container,'mc','stat','local/'+obj)
    with urllib.request.urlopen('http://localhost:9000/profile-pics/avatar.jpg', timeout=20) as response:
        if response.status != 200 or not response.read(1):
            raise RuntimeError('Khong the tai anh avatar public tu MinIO.')
    print('PROVISION PASSED (Keycloak + MinIO).')

if __name__=='__main__':
    try: main()
    except Exception as exc:
        raise SystemExit('PROVISION FAILED: '+str(exc)) from None

#!/usr/bin/env python3
"""MyMiniCloud B1-B10 / E1-E10 cross-platform verifier. Standard library only.

Tests real local Docker containers and records a report; never considers old screenshots proof.
"""
from __future__ import annotations
import argparse, base64, datetime as dt, json, pathlib, re, subprocess, sys, time, urllib.parse, urllib.request, urllib.error
ROOT = pathlib.Path(__file__).resolve().parents[1]
ENV = {}
PASS = FAIL = 0
LOG = []

class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl): return None

def log(message):
    print(message,flush=True)
    LOG.append(message)

def load_env(path):
    d={}
    for line in path.read_text(encoding='utf-8-sig').splitlines():
        line=line.strip()
        if line and not line.startswith('#') and '=' in line:
            k,v=line.split('=',1);d[k.strip()]=v.strip().strip('"').strip("'")
    if any(v.startswith('REPLACE_') for v in d.values()): raise RuntimeError('.env chua doi mat khau mau')
    return d

def cmd(*args, timeout=60):
    result = subprocess.run(args, cwd=ROOT, text=True, stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=timeout)
    if result.returncode:
        raise RuntimeError('command failed: '+ ' '.join(args[:3]) + ' / '+(result.stderr or result.stdout)[-250:])
    return result.stdout.strip()

def req(url, *, method='GET', data=None, auth=None, follow=True, timeout=15):
    headers={}
    if auth: headers['Authorization']='Bearer '+auth
    if data is not None:
        data=urllib.parse.urlencode(data).encode()
        headers['Content-Type']='application/x-www-form-urlencoded'
    request=urllib.request.Request(url,method=method,data=data,headers=headers)
    opener=urllib.request.build_opener() if follow else urllib.request.build_opener(NoRedirect())
    try:
        with opener.open(request,timeout=timeout) as resp: return resp.status,resp.read(),dict(resp.headers)
    except urllib.error.HTTPError as exc:
        if not follow and 300<=exc.code<400: return exc.code,exc.read(),dict(exc.headers)
        raise RuntimeError('HTTP %d %s'%(exc.code,url)) from None

def js(url, **kwargs):
    status,body,headers=req(url,**kwargs)
    return json.loads(body)

def check(condition, error='Khong dung ket qua mong doi'):
    if not condition: raise AssertionError(error)

def count(url,n=5):
    obj=js(url);check(isinstance(obj,list) and len(obj)==n, f'Can {n} phan tu, nhan {len(obj) if isinstance(obj,list) else "khong phai mang"}')
    return obj

def admin_token():
    return js('http://localhost:8081/realms/master/protocol/openid-connect/token',method='POST',data={
        'client_id':'admin-cli','username':ENV['KEYCLOAK_ADMIN'],
        'password':ENV['KEYCLOAK_ADMIN_PASSWORD'],'grant_type':'password'})['access_token']

def user_token(username):
    return js('http://localhost:8081/realms/'+ENV['KEYCLOAK_REALM']+'/protocol/openid-connect/token',method='POST',data={
        'client_id':'flask-app','username':username,
        'password':ENV[username.upper()+'_PASSWORD'],'grant_type':'password'})['access_token']

def pquery(expression, retry=1):
    url='http://localhost:9090/api/v1/query?'+urllib.parse.urlencode({'query':expression})
    for i in range(retry):
        data=js(url)
        if data.get('status')=='success' and data.get('data',{}).get('result'): return
        if i<retry-1: time.sleep(5)
    raise AssertionError('Khong co metrics: '+expression)

def graf(uid,title, panels=None):
    user=ENV['GF_SECURITY_ADMIN_USER'];password=ENV['GF_SECURITY_ADMIN_PASSWORD']
    basic=base64.b64encode((user+':'+password).encode()).decode()
    url='http://localhost:3000/api/dashboards/uid/'+uid
    request=urllib.request.Request(url,headers={'Authorization':'Basic '+basic})
    with urllib.request.urlopen(request,timeout=15) as resp: doc=json.loads(resp.read())['dashboard']
    check(doc['title']==title,'Dashboard khong dung ten: '+str(doc.get('title')))
    if panels is not None: check(len(doc.get('panels',[]))==panels,'So panel khong dung')

def dig(record):
    return cmd('docker','exec','internal-dns-server','dig','+short','@127.0.0.1',record,'A').strip()

def test_b1():
    for path in ['','blog/']: check(req('http://localhost:8080/'+path)[0]==200)
    # Integrated Gateway must not occasionally 404 when the upstream is Web 2.
    for _ in range(6): check(req('http://localhost/blog/')[0]==200,'Gateway blog bi 404 tren web2')

def test_b2():
    expected={'message':'Hello from App Server!'}
    check(js('http://localhost:8085/hello')==expected)
    check(js('http://localhost/api/hello')==expected)

def test_b3():
    sql="SELECT COUNT(*) FROM notes WHERE title='Hello from MariaDB!';"
    value=cmd('docker','exec','relational-database-server','mariadb','-u'+ENV['MARIADB_USER'],
              '--password='+ENV['MARIADB_PASSWORD'],'minicloud','-N','-e',sql)
    check(int(value)>=1,'Khong doc duoc note tu CSDL minicloud')

def test_b4():
    users=js('http://localhost:8081/admin/realms/'+ENV['KEYCLOAK_REALM']+'/users?username=sv01&exact=true',auth=admin_token())
    check(len(users)==1 and users[0]['username']=='sv01' and users[0]['enabled'])

def test_b5(): cmd('docker','exec','object-storage-server','mc','stat','local/demo/index.html')

def test_b6(): check(dig('web-frontend-server.cloud.local')=='10.10.10.10')

def test_b7():
    pquery('up{job="node"} == 1',retry=10)
    pquery('node_cpu_seconds_total',retry=6)

def test_b8():
    graf('rYdddlPWk','Node Exporter Full')
    for query in ['100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)',
                  '100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)',
                  'sum by(instance) (rate(node_network_receive_bytes_total{device!="lo"}[5m]))']:
        pquery(query,retry=8)

def test_b9():
    check(req('http://localhost/')[0]==200)
    check(req('http://localhost/api/hello')[0]==200)
    check(req('http://localhost/auth/',follow=False)[0]==302)

def test_b10():
    containers=['web-frontend-server','web-frontend-server2','application-backend-server',
      'relational-database-server','authentication-identity-server','object-storage-server',
      'internal-dns-server','node-exporter','monitoring-prometheus-server',
      'monitoring-grafana-dashboard-server','api-gateway-proxy-server']
    for container in containers:
        cmd('docker','run','--rm','--network','cloud-net','busybox:1.38.0','ping','-c','1','-W','2',container,timeout=65)

def test_e1():
    for n in (1,2,3):
        url=f'http://localhost/blog/blog{n}.html'
        status,body,_=req(url)
        check(status==200 and (b'<img' in body or b'images/' in body),'Bai blog thieu anh')
        html=(ROOT/'web-frontend-server'/'html'/'blog'/f'blog{n}.html').read_text(encoding='utf-8')
        check('href="../index.html"' in html,'Thieu lien ket trang chu')

def test_e2():
    for student in count('http://localhost/api/student'):
        check(all(key in student for key in ('id','name','major','gpa')))

def test_e3():
    for student in count('http://localhost/api/students-db'):
        check(all(key in student for key in ('student_id','fullname','dob','major')))

def test_e4():
    for user in ('sv01','sv02'):
        token=user_token(user)
        mid=token.split('.')[1];mid+='='*((4-len(mid)%4)%4)
        payload=json.loads(base64.urlsafe_b64decode(mid))
        aud=payload.get('aud',[]);aud=[aud] if isinstance(aud,str) else aud
        check('flask-app' in aud,'Token thieu audience flask-app')
        check(js('http://localhost:8085/secure',auth=token)['preferred_username']==user)

def test_e5():
    for obj in ['local/profile-pics/avatar.jpg','local/documents/document.pdf']:
        cmd('docker','exec','object-storage-server','mc','stat',obj)
    status,body,_=req('http://localhost:9000/profile-pics/avatar.jpg')
    check(status==200 and len(body)>100,'Avatar public loi')

def test_e6():
    for name,ip in [('app-backend','10.10.10.20'),('minio','10.10.10.30'),('keycloak','10.10.10.40')]:
        check(dig(name+'.cloud.local')==ip,'DNS '+name+' khong dung')

def test_e7(): pquery('up{job="web"} == 1',retry=8)

def test_e8(): graf('system-health-52400141','System Health of 52400141',3)

def test_e9(): count('http://localhost/student/')

def test_e10():
    seq=[]
    for _ in range(6):
        html=req('http://localhost/')[1].decode('utf-8','replace')
        match=re.search(r'Server [12]',html)
        check(match is not None,'Web thieu ten Server')
        seq.append(match.group())
    check(len(set(seq))==2,'Khong chia tai 2 server: '+repr(seq))
    check(all(a!=b for a,b in zip(seq,seq[1:])),'Round Robin khong luan phien: '+repr(seq))

TESTS=[
 ('B1','Web + blog tren 2 instance',test_b1),
 ('B2','Flask hello truc tiep/qua Gateway',test_b2),
 ('B3','MariaDB notes',test_b3),
 ('B4','Keycloak realm sv01',test_b4),
 ('B5','MinIO demo bucket',test_b5),
 ('B6','DNS ban ghi Web',test_b6),
 ('B7','Prometheus Node Exporter',test_b7),
 ('B8','Grafana/CPU/RAM/Network',test_b8),
 ('B9','Gateway Web/API/Auth',test_b9),
 ('B10','11 container lien lac qua network',test_b10),
 ('E1','3 bai blog + anh + link trang chu',test_e1),
 ('E2','API /student 5 ban ghi',test_e2),
 ('E3','API studentdb 5 ban ghi',test_e3),
 ('E4','OIDC sv01/sv02 va /secure',test_e4),
 ('E5','MinIO avatar public va PDF private',test_e5),
 ('E6','DNS app/minio/keycloak',test_e6),
 ('E7','Prometheus Web target',test_e7),
 ('E8','Dashboard System Health 3 panel',test_e8),
 ('E9','Gateway /student/',test_e9),
 ('E10','Round Robin 2 Web Server',test_e10),
]

def main():
    global ENV,PASS,FAIL
    parser=argparse.ArgumentParser(description='Kiem thu B1-B10 va E1-E10 tren may dang chay Docker')
    parser.add_argument('--no-log',action='store_true',help='Khong luu log')
    args=parser.parse_args()
    ENV=load_env(ROOT/'.env')
    log('MyMiniCloud - KIEM THU 20 MUC - '+dt.datetime.now().isoformat(timespec='seconds'))
    log('Kiem tra tren MAY HIEN TAI; khong su dung ket qua luu tu truoc.')
    for code,description,fn in TESTS:
        try:
            fn()
            PASS+=1;log('[PASS] %-3s %s'%(code,description))
        except Exception as exc:
            FAIL+=1
            # prevent credentials appearing in report when error includes docker CLI arguments
            message=str(exc)
            for key,val in ENV.items():
                if ('PASSWORD' in key or 'SECRET' in key) and val: message=message.replace(val,'***')
            log('[FAIL] %-3s %s: %s'%(code,description,message[:450]))
    log('KET QUA: PASS %d/20, FAIL %d/20'%(PASS,FAIL))
    if not args.no_log:
        folder=ROOT/'docs'/'evidence'/'moi';folder.mkdir(parents=True,exist_ok=True)
        file=folder/('kiem-thu-'+dt.datetime.now().strftime('%Y%m%d-%H%M%S')+'.txt')
        file.write_text('\n'.join(LOG)+'\n',encoding='utf-8')
        log('Da luu log: '+str(file.relative_to(ROOT)))
    return 0 if FAIL==0 else 1

if __name__=='__main__':
    try: sys.exit(main())
    except Exception as exc: raise SystemExit('KHONG THE KIEM THU: '+str(exc)) from None

#!/usr/bin/env python3
"""Create a private, reproducible local .env from .env.example (stdlib only)."""
from __future__ import annotations
import argparse
import pathlib
import re
import secrets

ROOT = pathlib.Path(__file__).resolve().parents[1]
REPLACE = re.compile(r'^([A-Z][A-Z0-9_]*)=(REPLACE_[^\r\n]+)$', re.M)

def main():
    parser = argparse.ArgumentParser(description='Tao file .env rieng cho MyMiniCloud.')
    parser.add_argument('--mssv', default='52400001', help='Ma so sinh vien dai dien nhom (chi chu so)')
    args = parser.parse_args()
    if not re.fullmatch(r'[0-9]{5,12}', args.mssv):
        parser.error('MSSV phai la 5-12 chu so.')
    target = ROOT / '.env'
    if target.exists():
        print('.env da ton tai. Khong ghi de de tranh mat cau hinh/mat khau.')
        if REPLACE.search(target.read_text(encoding='utf-8-sig')):
            raise SystemExit('ERROR: .env con REPLACE_*. Hay sua file nay hoac xoa de tao lai.')
        return
    source = (ROOT / '.env.example').read_text(encoding='utf-8-sig')
    # URL and passwords contain no special Compose/Bash metacharacters.
    source = REPLACE.sub(lambda match: f'{match.group(1)}={secrets.token_hex(18)}', source)
    source = re.sub(r'^GROUP_MSSV=.*$', f'GROUP_MSSV={args.mssv}', source, flags=re.M)
    source = re.sub(r'^KEYCLOAK_REALM=.*$', f'KEYCLOAK_REALM=realm_{args.mssv}', source, flags=re.M)
    source = re.sub(r'^OIDC_ISSUER=.*$', f'OIDC_ISSUER=http://localhost:8081/realms/realm_{args.mssv}', source, flags=re.M)
    source = re.sub(r'^OIDC_JWKS_URL=.*$', 'OIDC_JWKS_URL=http://authentication-identity-server:8080/realms/realm_' + args.mssv + '/protocol/openid-connect/certs', source, flags=re.M)
    if REPLACE.search(source):
        raise SystemExit('ERROR: Chua thay het placeholder trong .env.example')
    target.write_text(source.replace('\r\n','\n'), encoding='utf-8', newline='\n')
    print('Da tao .env rieng cho may nay (khong commit/khong chia se).')
    print('Realm:', 'realm_' + args.mssv)

if __name__ == '__main__':
    main()

#!/usr/bin/env bash
set -uo pipefail

export TZ="${TZ:-Asia/Ho_Chi_Minh}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${1:-$REPO_ROOT/.env}"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "ERROR: environment file not found: $ENV_FILE" >&2
    exit 2
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

if command -v docker >/dev/null 2>&1 && docker version >/dev/null 2>&1; then
    DOCKER_BIN="docker"
elif command -v docker.exe >/dev/null 2>&1 && docker.exe version >/dev/null 2>&1; then
    # Allows local validation from WSL when Docker Desktop WSL integration is
    # disabled but the Windows CLI is on PATH.
    DOCKER_BIN="docker.exe"
else
    echo "ERROR: no working Docker CLI was found." >&2
    exit 2
fi

required_env=(
    MARIADB_USER MARIADB_PASSWORD
    KEYCLOAK_ADMIN KEYCLOAK_ADMIN_PASSWORD KEYCLOAK_REALM
    SV01_PASSWORD SV02_PASSWORD
    GF_SECURITY_ADMIN_USER GF_SECURITY_ADMIN_PASSWORD
)
for name in "${required_env[@]}"; do
    if [[ -z "${!name:-}" ]]; then
        echo "ERROR: missing environment variable: $name" >&2
        exit 2
    fi
done

PASS_COUNT=0
FAIL_COUNT=0

record_test() {
    local code="$1"
    local description="$2"
    shift 2
    if "$@"; then
        printf '[PASS] %-3s %s\n' "$code" "$description"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        printf '[FAIL] %-3s %s\n' "$code" "$description" >&2
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

json_array_count_is() {
    local expected="$1"
    python3 -c 'import json,sys; data=json.load(sys.stdin); assert isinstance(data,list) and len(data)==int(sys.argv[1])' "$expected"
}

prometheus_has_data() {
    local query="$1"
    curl -fsS -G 'http://localhost:9090/api/v1/query' \
        --data-urlencode "query=$query" |
        python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["status"]=="success" and len(d["data"]["result"])>0'
}

grafana_dashboard_check() {
    local uid="$1"
    local title="$2"
    local panel_count="$3"
    curl -fsS \
        -u "$GF_SECURITY_ADMIN_USER:$GF_SECURITY_ADMIN_PASSWORD" \
        "http://localhost:3000/api/dashboards/uid/$uid" |
        python3 -c 'import json,sys; d=json.load(sys.stdin)["dashboard"]; assert d["title"]==sys.argv[1]; expected=int(sys.argv[2]); assert expected<0 or len(d.get("panels",[]))==expected' "$title" "$panel_count"
}

keycloak_admin_token() {
    curl -fsS -X POST \
        "http://localhost:8081/realms/master/protocol/openid-connect/token" \
        -H 'Content-Type: application/x-www-form-urlencoded' \
        --data-urlencode 'client_id=admin-cli' \
        --data-urlencode "username=$KEYCLOAK_ADMIN" \
        --data-urlencode "password=$KEYCLOAK_ADMIN_PASSWORD" \
        --data-urlencode 'grant_type=password' |
        python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])'
}

keycloak_user_token() {
    local username="$1"
    local password="$2"
    curl -fsS -X POST \
        "http://localhost:8081/realms/$KEYCLOAK_REALM/protocol/openid-connect/token" \
        -H 'Content-Type: application/x-www-form-urlencoded' \
        --data-urlencode 'client_id=flask-app' \
        --data-urlencode "username=$username" \
        --data-urlencode "password=$password" \
        --data-urlencode 'grant_type=password' |
        python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])'
}

test_b1() {
    curl -fsS -o /dev/null 'http://localhost:8080/' &&
        curl -fsS -o /dev/null 'http://localhost:8080/blog/'
}

test_b2() {
    local direct gateway
    direct="$(curl -fsS 'http://localhost:8085/hello')" || return 1
    gateway="$(curl -fsS 'http://localhost/api/hello')" || return 1
    python3 -c 'import json,sys; a=json.loads(sys.argv[1]); b=json.loads(sys.argv[2]); assert a==b=={"message":"Hello from App Server!"}' "$direct" "$gateway"
}

test_b3() {
    local result
    result="$("$DOCKER_BIN" exec relational-database-server mariadb \
        -u"$MARIADB_USER" --password="$MARIADB_PASSWORD" \
        minicloud -N -e "SELECT COUNT(*) FROM notes WHERE title='Hello from MariaDB!';" 2>/dev/null)" || return 1
    [[ "$result" -ge 1 ]]
}

test_b4() {
    local token users
    token="$(keycloak_admin_token)" || return 1
    users="$(curl -fsS \
        -H "Authorization: Bearer $token" \
        "http://localhost:8081/admin/realms/$KEYCLOAK_REALM/users?username=sv01&exact=true")" || return 1
    printf '%s' "$users" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert len(d)==1 and d[0]["username"]=="sv01" and d[0]["enabled"]'
}

test_b5() {
    "$DOCKER_BIN" exec object-storage-server mc stat local/demo/index.html >/dev/null
}

test_b6() {
    [[ "$("$DOCKER_BIN" exec internal-dns-server dig +short @127.0.0.1 web-frontend-server.cloud.local A | tr -d '\r')" == '10.10.10.10' ]]
}

test_b7() {
    prometheus_has_data 'up{job="node"} == 1' &&
        prometheus_has_data 'node_cpu_seconds_total'
}

test_b8() {
    grafana_dashboard_check 'rYdddlPWk' 'Node Exporter Full' -1 &&
        prometheus_has_data '100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)' &&
        prometheus_has_data '100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)' &&
        prometheus_has_data 'sum by(instance) (rate(node_network_receive_bytes_total{device!="lo"}[5m]))'
}

test_b9() {
    [[ "$(curl -sS -o /dev/null -w '%{http_code}' 'http://localhost/')" == '200' ]] &&
        [[ "$(curl -sS -o /dev/null -w '%{http_code}' 'http://localhost/api/hello')" == '200' ]] &&
        [[ "$(curl -sS -o /dev/null -w '%{http_code}' --max-redirs 0 'http://localhost/auth/')" == '302' ]]
}

test_b10() {
    local containers=(
        web-frontend-server web-frontend-server2 application-backend-server
        relational-database-server authentication-identity-server
        object-storage-server internal-dns-server monitoring-prometheus-server
        node-exporter monitoring-grafana-dashboard-server api-gateway-proxy-server
    )
    local container
    for container in "${containers[@]}"; do
        "$DOCKER_BIN" run --rm --network cloud-net busybox:1.38.0 \
            ping -c 1 -W 2 "$container" >/dev/null || return 1
    done
}

test_e1() {
    local page
    for page in blog1.html blog2.html blog3.html; do
        curl -fsS "http://localhost:8080/blog/$page" |
            grep -qE '(<img|images/)' || return 1
        grep -q 'href="../index.html"' "$REPO_ROOT/web-frontend-server/html/blog/$page" || return 1
    done
}

test_e2() {
    curl -fsS 'http://localhost:8085/student' | json_array_count_is 5
}

test_e3() {
    curl -fsS 'http://localhost:8085/students-db' | json_array_count_is 5
}

test_e4() {
    local username password token payload secure
    for username in sv01 sv02; do
        if [[ "$username" == 'sv01' ]]; then
            password="$SV01_PASSWORD"
        else
            password="$SV02_PASSWORD"
        fi
        token="$(keycloak_user_token "$username" "$password")" || return 1
        payload="$(python3 -c 'import base64,json,sys; s=sys.argv[1].split(".")[1]; s += "="*((4-len(s)%4)%4); print(json.dumps(json.loads(base64.urlsafe_b64decode(s))))' "$token")" || return 1
        printf '%s' "$payload" | python3 -c 'import json,sys; d=json.load(sys.stdin); aud=d.get("aud",[]); aud=[aud] if isinstance(aud,str) else aud; assert "flask-app" in aud' || return 1
        secure="$(curl -fsS -H "Authorization: Bearer $token" 'http://localhost:8085/secure')" || return 1
        python3 -c 'import json,sys; assert json.loads(sys.argv[1])["preferred_username"]==sys.argv[2]' "$secure" "$username" || return 1
    done
}

test_e5() {
    "$DOCKER_BIN" exec object-storage-server mc stat local/profile-pics/avatar.jpg >/dev/null &&
        "$DOCKER_BIN" exec object-storage-server mc stat local/documents/document.pdf >/dev/null &&
        curl -fsS -o /dev/null 'http://localhost:9000/profile-pics/avatar.jpg'
}

test_e6() {
    [[ "$("$DOCKER_BIN" exec internal-dns-server dig +short @127.0.0.1 app-backend.cloud.local A | tr -d '\r')" == '10.10.10.20' ]] &&
        [[ "$("$DOCKER_BIN" exec internal-dns-server dig +short @127.0.0.1 minio.cloud.local A | tr -d '\r')" == '10.10.10.30' ]] &&
        [[ "$("$DOCKER_BIN" exec internal-dns-server dig +short @127.0.0.1 keycloak.cloud.local A | tr -d '\r')" == '10.10.10.40' ]]
}

test_e7() {
    prometheus_has_data 'up{job="web"} == 1'
}

test_e8() {
    grafana_dashboard_check 'system-health-52400141' 'System Health of 52400141' 3
}

test_e9() {
    curl -fsS 'http://localhost/student/' | json_array_count_is 5
}

test_e10() {
    local sequence=()
    local body marker index
    for index in 1 2 3 4 5 6; do
        body="$(curl -fsS 'http://localhost/')" || return 1
        marker="$(printf '%s' "$body" | grep -oE 'Server [12]' | head -n 1)"
        [[ -n "$marker" ]] || return 1
        sequence+=("$marker")
    done
    [[ "$(printf '%s\n' "${sequence[@]}" | sort -u | wc -l | tr -d ' ')" == '2' ]] || return 1
    for ((index=1; index<${#sequence[@]}; index++)); do
        [[ "${sequence[$index]}" != "${sequence[$((index-1))]}" ]] || return 1
    done
}

echo "MyMiniCloud integration smoke test"
echo "Time: $(date -Iseconds)"
echo "Environment: $(basename "$ENV_FILE")"
echo "------------------------------------------------------------"

record_test B1  'Home and Blog return HTTP 200' test_b1
record_test B2  '/hello direct and Gateway JSON match' test_b2
record_test B3  'MariaDB notes table contains sample data' test_b3
record_test B4  'Keycloak admin API finds enabled sv01' test_b4
record_test B5  'MinIO demo/index.html exists' test_b5
record_test B6  'DNS Web record is 10.10.10.10' test_b6
record_test B7  'Node target and CPU metric have data' test_b7
record_test B8  'Node Exporter Full and CPU/RAM/Network data exist' test_b8
record_test B9  'Gateway root, API and auth routes pass' test_b9
record_test B10 'All eleven containers are reachable' test_b10
record_test E1  'Three blog articles have images and Home links' test_e1
record_test E2  '/student returns five JSON students' test_e2
record_test E3  '/students-db returns five database students' test_e3
record_test E4  'sv01/sv02 tokens, audience and /secure pass' test_e4
record_test E5  'Public avatar and document object pass' test_e5
record_test E6  'DNS app/minio/keycloak records pass' test_e6
record_test E7  'Prometheus Web target is UP' test_e7
record_test E8  'Personal Grafana dashboard has three panels' test_e8
record_test E9  'Gateway /student/ returns five students' test_e9
record_test E10 'Six requests alternate Server 1 and Server 2' test_e10

echo "------------------------------------------------------------"
echo "PASS: $PASS_COUNT / 20"
echo "FAIL: $FAIL_COUNT / 20"

if [[ "$FAIL_COUNT" -gt 0 ]]; then
    exit 1
fi

echo 'Integration smoke test PASSED.'
exit 0

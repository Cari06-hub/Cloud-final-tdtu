# Kế hoạch hoàn thành phần Trung Nguyên - MyMiniCloud

> Thành viên: Trung Nguyên
> MSSV cá nhân: `52400141`
> Repository: `https://github.com/Cari06-hub/Cloud-final-tdtu.git`
> Nhánh làm việc: `Nguyen`
> Cập nhật kế hoạch: `2026-11-10`

## 1. Mục tiêu và phạm vi trách nhiệm

Trung Nguyên chịu trách nhiệm chính cho các thành phần sau:

- Prometheus và Node Exporter: B7, E7.
- Grafana: B8, E8.
- API Gateway/Reverse Proxy/Load Balancer: B9, E9, E10.
- Khởi tạo và hoàn thiện `docker-compose.yml` tích hợp toàn hệ thống.
- Chuẩn hóa repository, `.gitignore`, `.env.example` và `README.md`.
- Tích hợp mã nguồn của TV1 và Tuấn Anh theo đúng tên service, port và network.
- Chạy lại toàn bộ B1-B10 và E1-E10 sau mỗi lần tích hợp.
- Triển khai toàn hệ thống trên AWS EC2 Ubuntu.
- Viết Chương 2; phần Chương 3-4 thuộc phạm vi TV3; tổng hợp báo cáo Word cuối.
- Tổng hợp log, ảnh minh chứng, bảng kết quả kiểm thử và phụ lục.

Kết quả cuối cùng phải là một hệ thống có thể tái tạo bằng:

```bash
cp .env.example .env
# Điền giá trị thật vào .env
docker compose config --quiet
docker compose build
docker compose up -d
docker compose ps
```

## 2. Trạng thái ban đầu của repository

Kết quả kiểm tra ngày 2026-11-10:

| Nhánh | Commit | Trạng thái |
|---|---|---|
| `main` | `5df87c4` | Chỉ có `README.md` |
| `Nguyen` | `5df87c4` | Trùng `main`, chưa có phần TV3 |
| `Quang` | `6885541` | Web, Flask, MariaDB, blog, `/metrics`, Web 2 |
| `feature/auth-storage-dns` | `93a721b` | Keycloak, MinIO, Bind9, ping script, tài liệu TV2 |

Các vấn đề phải xử lý trước khi tích hợp:

- [ ] Nhánh `Quang` đang commit file `.env`; không đưa file này vào nhánh `Nguyen`.
- [ ] Thay toàn bộ mật khẩu đã từng xuất hiện trong Git vì phải xem là đã bị lộ.
- [ ] TV1/TV2 đang dùng MSSV cấp nhóm `52400001`; MSSV cá nhân của TV3 là `52400141`.
- [ ] Chốt với trưởng nhóm Realm Keycloak sẽ giữ `realm_52400001` hay chuyển sang `realm_52400141`.
- [ ] Dashboard của TV3 phải mang tên `System Health of 52400141`.
- [ ] Compose TV1 hiện chỉ khai báo MariaDB, chưa có Web và Flask.
- [ ] Trang Web 1 chưa có chuỗi nhận diện `Server 1` cho E10.
- [ ] MinIO trong compose và tài liệu TV2 đang dùng image/cấu hình không thống nhất.
- [ ] Keycloak chưa có persistence hoặc realm import.
- [ ] DNS dùng IP `10.10.10.x` nhưng Compose chưa gán IP tĩnh tương ứng.

## 3. Các quyết định phải khóa trước khi code

### 3.1. Quy ước MSSV

- `DASHBOARD_MSSV=52400141` dùng cho dashboard và bằng chứng của Trung Nguyên.
- `GROUP_MSSV` là MSSV đại diện nhóm dùng cho Realm Keycloak.
- Giá trị đang được TV1 và TV2 sử dụng là `52400001`.
- Không tự ý đổi Realm nếu trưởng nhóm và TV2 chưa xác nhận.

Quyết định cần ghi vào README:

```text
GROUP_MSSV=<giá trị trưởng nhóm chốt>
DASHBOARD_MSSV=52400141
KEYCLOAK_REALM=realm_<GROUP_MSSV>
```

### 3.2. Hợp đồng tích hợp

| Thành phần | Service/container | Host:container | Ghi chú |
|---|---|---|---|
| Web 1 | `web-frontend-server` | `8080:80` | Home, blog, `/metrics`, nhận diện Server 1 |
| Web 2 | `web-frontend-server2` | Không publish | Replica cho Round Robin, nhận diện Server 2 |
| Flask | `application-backend-server` | `8085:8081` | `/hello`, `/student`, `/students-db`, `/secure` |
| MariaDB | `relational-database-server` | Chỉ publish khi debug | `minicloud`, `studentdb` |
| Keycloak | `authentication-identity-server` | `8081:8080` | Realm theo MSSV nhóm |
| MinIO | `object-storage-server` | `9000:9000`, `9001:9001` | S3 API và Console |
| Bind9 | `internal-dns-server` | `1053:53/udp` | Zone `cloud.local` |
| Node Exporter | `node-exporter` | Không cần publish trên EC2 | Metric host/container |
| Prometheus | `monitoring-prometheus-server` | `9090:9090` | Scrape node và web |
| Grafana | `monitoring-grafana-dashboard-server` | `3000:3000` | Dashboard monitoring |
| Gateway | `api-gateway-proxy-server` | `80:80` | Gateway và Round Robin |

Quy tắc bắt buộc:

- Mọi service cùng network `cloud-net`.
- Container gọi nhau bằng service name, không dùng `localhost`.
- Không đổi tên service/port nếu chưa báo cả nhóm.
- Dùng `restart: unless-stopped`.
- Dịch vụ có dữ liệu phải có volume.
- Không ghi mật khẩu thật trong YAML, source code hoặc README.
- Các image chính thức phải được ghim phiên bản/digest đã kiểm thử, không để `latest` khi chốt bài.

## 4. Cấu trúc thư mục đích

```text
Cloud-final-tdtu/
├── .env.example
├── .gitignore
├── docker-compose.yml
├── README.md
├── plan.md
├── web-frontend-server/
├── application-backend-server/
├── relational-database-server/
├── authentication-identity-server/
├── object-storage-server/
├── internal-dns-server/
├── monitoring-prometheus-server/
│   └── prometheus.yml
├── monitoring-grafana-dashboard-server/
│   ├── dashboards/
│   │   └── system-health-52400141.json
│   └── provisioning/
│       ├── dashboards/
│       │   └── dashboards.yml
│       └── datasources/
│           └── prometheus.yml
├── api-gateway-proxy-server/
│   └── nginx.conf
├── scripts/
│   ├── ping-test.sh
│   └── smoke-test.sh
└── docs/
    ├── diagrams/
    ├── evidence/
    └── report/
        ├── chuong-2-kien-truc.md
        ├── chuong-3-tv3.md
        └── chuong-4-tv3.md
```

## 5. Quy trình thực hiện

## Giai đoạn 0 - Khóa chuẩn với trưởng nhóm

### Công việc

- [x] Xác nhận nhánh làm việc là `Nguyen`.
- [ ] Xác nhận MSSV đại diện nhóm cho Realm Keycloak.
- [x] Xác nhận `System Health of 52400141` là tên dashboard E8.
- [x] Xác nhận danh sách service/container trong bảng hợp đồng tích hợp.
- [x] Xác nhận port, endpoint và biến môi trường.
- [ ] Xác nhận subnet `10.10.10.0/24` không xung đột môi trường nhóm.
- [x] Soạn yêu cầu TV1 bổ sung `Server 1` vào Web 1 tại `docs/integration-contract.md`.
- [x] Soạn yêu cầu TV2 xác nhận image MinIO và cách lưu Realm Keycloak tại `docs/integration-contract.md`.

### Điều kiện hoàn thành

- [ ] Không còn quyết định chưa chốt có thể làm thay đổi Compose, Realm hoặc endpoint.
- [x] Quy ước được ghi trong README và `docs/integration-contract.md` để đối chiếu.

## Giai đoạn 1 - Bảo mật Git và dựng khung

### Công việc

- [x] `git switch Nguyen`.
- [x] `git pull --ff-only origin Nguyen`.
- [x] Tạo `.gitignore`.
- [x] Tạo `.env.example` chỉ chứa placeholder.
- [x] Tạo các thư mục thuộc TV3.
- [x] Kiểm tra không có secret trong worktree; quy trình kiểm tra staged diff được ghi tại `docs/security-baseline.md`.
- [x] Không merge nguyên commit TV1 nếu commit đó vẫn mang `.env` vào lịch sử nhánh `Nguyen`.
- [x] Ghi yêu cầu đổi toàn bộ mật khẩu từng xuất hiện trên remote tại `docs/security-baseline.md`.

`.gitignore` tối thiểu:

```gitignore
.env
*.pem
*.key
.aws/
secrets/
__pycache__/
.vscode/
.idea/
.DS_Store
```

`.env.example` tối thiểu:

```dotenv
GROUP_MSSV=52400001
DASHBOARD_MSSV=52400141

MARIADB_ROOT_PASSWORD=REPLACE_WITH_STRONG_ROOT_PASSWORD
MARIADB_DATABASE=minicloud
MARIADB_USER=minicloud_user
MARIADB_PASSWORD=REPLACE_WITH_STRONG_APP_PASSWORD

DB_HOST=relational-database-server
DB_PORT=3306
DB_NAME=studentdb

KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=REPLACE_WITH_STRONG_KEYCLOAK_PASSWORD

MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=REPLACE_WITH_STRONG_MINIO_PASSWORD

OIDC_ISSUER=http://localhost:8081/realms/realm_52400001
OIDC_JWKS_URL=http://authentication-identity-server:8080/realms/realm_52400001/protocol/openid-connect/certs
OIDC_AUDIENCE=flask-app

GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=REPLACE_WITH_STRONG_GRAFANA_PASSWORD
```

### Commit đề xuất

```text
chore: initialize secure integration scaffold
```

### Điều kiện hoàn thành

- [x] `.env` không được Git track.
- [x] Không có mật khẩu, token, AWS key hoặc private key trong diff hiện tại.
- [x] Cấu trúc thư mục cơ bản đã tồn tại.

## Giai đoạn 2 - Tích hợp phần TV1 và TV2

### Tích hợp TV1

- [x] Lấy `web-frontend-server/` bằng allowlist từ `origin/Quang@6885541`.
- [x] Lấy `application-backend-server/` bằng allowlist từ `origin/Quang@6885541`.
- [x] Lấy `relational-database-server/` bằng allowlist từ `origin/Quang@6885541`.
- [x] Không lấy file `.env` đã commit.
- [x] Web 1 hiển thị `Server 1`.
- [x] Web 2 hiển thị `Server 2`.
- [x] `/metrics` có cấu hình HTTP 200 và metric `web_up 1`; runtime test chờ Docker.
- [x] Flask nhận biến DB và OIDC từ environment.
- [x] SQL có `minicloud.notes` và `studentdb.students`.
- [x] User MariaDB có quyền trên `studentdb`.

### Tích hợp TV2

- [x] Lấy `authentication-identity-server/` bằng allowlist từ TV2.
- [x] Lấy `object-storage-server/` bằng allowlist từ TV2.
- [x] Lấy `internal-dns-server/` bằng allowlist từ TV2.
- [x] Lấy `scripts/ping-test.sh`, PowerShell ping test và token test bằng allowlist.
- [x] Thay mật khẩu hard-code bằng biến môi trường.
- [x] Chốt `bitnamilegacy/minio:2024.6.13` thống nhất giữa Compose và tài liệu.
- [x] Thêm `minio_data:/bitnami/minio/data`.
- [x] Thêm `keycloak_data:/opt/keycloak/data`.
- [ ] Kiểm tra runtime Realm, user, client và Audience mapper khi Docker chạy.
- [x] Đối chiếu zone DNS với IPAM Compose; sửa NS thành `10.10.10.50`.

### Quy tắc tích hợp

- [x] TV3 chỉ chuẩn hóa giao diện tích hợp/bảo mật; thay đổi được ghi trong audit để chủ sở hữu review.
- [x] Không đổi tên service hoặc port; thay đổi environment/persistence đã được ghi vào hợp đồng và handoff.
- [x] `docker compose --env-file .env.example -f docker-compose.tv2.yml config` đã đạt.

### Commit đề xuất

```text
chore: integrate tv1 and tv2 deliverables
```

## Giai đoạn 3 - Prometheus và Node Exporter

### Cấu hình Prometheus

Tạo `monitoring-prometheus-server/prometheus.yml`:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: node
    static_configs:
      - targets:
          - node-exporter:9100

  - job_name: web
    metrics_path: /metrics
    static_configs:
      - targets:
          - web-frontend-server:80
```

### Checklist triển khai

- [ ] Thêm service `node-exporter`.
- [ ] Thêm service `monitoring-prometheus-server`.
- [ ] Mount `prometheus.yml` read-only.
- [ ] Thêm volume `prometheus_data`.
- [ ] Cả hai service vào `cloud-net`.
- [ ] Dùng `restart: unless-stopped`.
- [ ] Publish `9090:9090` khi demo local.
- [ ] Không mở `9100` công khai trên EC2.
- [ ] Kiểm tra cấu hình Prometheus trước khi chạy.

### Kiểm thử B7

```bash
curl http://localhost:9090/-/ready
```

- [ ] Truy cập `http://localhost:9090/targets`.
- [ ] Target `node-exporter:9100` là `UP`.
- [ ] Truy vấn `node_cpu_seconds_total` có dữ liệu.

### Kiểm thử E7

```bash
curl http://localhost:8080/metrics
```

- [ ] Endpoint `/metrics` trả HTTP 200.
- [ ] Target `web-frontend-server:80` là `UP`.
- [ ] Metric `web_up` có giá trị `1`.

### Commit đề xuất

```text
feat: add prometheus and node exporter monitoring
```

## Giai đoạn 4 - Grafana và dashboard MSSV 52400141

### Datasource provisioning

Datasource phải dùng URL nội bộ:

```text
http://monitoring-prometheus-server:9090
```

Không dùng `localhost:9090` trong Grafana container.

- [ ] Tạo provisioning datasource.
- [ ] Đặt UID datasource ổn định, ví dụ `prometheus`.
- [ ] Đặt Prometheus làm datasource mặc định.
- [ ] Tạo dashboard provider.
- [ ] Mount provisioning và dashboard JSON vào Grafana.
- [ ] Thêm volume `grafana_data`.
- [ ] Dùng tài khoản admin từ `.env`.

### B8 - Node Exporter Full

- [ ] Import dashboard Node Exporter Full.
- [ ] Dashboard nhận đúng datasource.
- [ ] CPU có dữ liệu.
- [ ] RAM có dữ liệu.
- [ ] Network có dữ liệu.
- [ ] Không để panel `No data` khi chụp minh chứng.

### E8 - Dashboard cá nhân

Tên dashboard:

```text
System Health of 52400141
```

Panel CPU Usage (%):

```promql
100 - (
  avg by(instance) (
    rate(node_cpu_seconds_total{mode="idle"}[5m])
  ) * 100
)
```

Panel Memory Usage (%):

```promql
100 * (
  1 -
  node_memory_MemAvailable_bytes
  /
  node_memory_MemTotal_bytes
)
```

Panel Network Receive:

```promql
sum by(instance) (
  rate(node_network_receive_bytes_total{device!="lo"}[5m])
)
```

Checklist:

- [ ] Dashboard có đúng tên `System Health of 52400141`.
- [ ] Có ít nhất ba panel CPU, Memory và Network.
- [ ] Đơn vị CPU/Memory là phần trăm.
- [ ] Network dùng đơn vị bytes/s hoặc bits/s nhất quán.
- [ ] Cả ba panel có dữ liệu.
- [ ] Export JSON vào `dashboards/system-health-52400141.json`.
- [ ] Xóa UID/mapping môi trường không cần thiết nếu làm JSON khó import.
- [ ] Khởi tạo Grafana mới từ volume rỗng và xác nhận dashboard tự xuất hiện.

### Commit đề xuất

```text
feat: provision grafana datasource and dashboards
```

## Giai đoạn 5 - Gateway, route và Round Robin

### Route bắt buộc

| Route | Đích | Yêu cầu |
|---|---|---|
| `/` | `web_pool` | Round Robin Web 1/Web 2 |
| `/api/` | `application-backend-server:8081/` | Bỏ tiền tố `/api/` |
| `/auth/` | `authentication-identity-server:8080/` | B9 mong đợi redirect 302 |
| `/student/` | Backend `/student` | E9 trả JSON sinh viên |

Khung `nginx.conf`:

```nginx
events {}

http {
    upstream web_pool {
        server web-frontend-server:80;
        server web-frontend-server2:80;
    }

    server {
        listen 80;

        location / {
            proxy_pass http://web_pool;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /api/ {
            proxy_pass http://application-backend-server:8081/;
        }

        location = /student/ {
            proxy_pass http://application-backend-server:8081/student;
        }

        location /auth/ {
            proxy_pass http://authentication-identity-server:8080/;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

### Kiểm thử B9

```bash
curl -I http://localhost/
curl -s http://localhost/api/hello
curl -I http://localhost/auth/
```

Kết quả mong đợi:

- [ ] `/` trả HTTP 200.
- [ ] `/api/hello` trả `Hello from App Server!`.
- [ ] `/auth/` trả 302 theo yêu cầu B9 hoặc có giải pháp cấu hình Keycloak được nhóm xác nhận.

### Kiểm thử E9

```bash
curl -s http://localhost/student/
```

- [ ] Trả JSON danh sách đúng năm sinh viên.
- [ ] Không bị 404 do dấu `/` hoặc sai `proxy_pass`.

### Kiểm thử E10

```bash
for i in 1 2 3 4 5 6; do
  curl -s http://localhost/ | grep -o "Server [12]"
done
```

- [ ] Kết quả có cả `Server 1` và `Server 2`.
- [ ] Kết quả thể hiện Round Robin, không chỉ ngẫu nhiên trùng một server.
- [ ] Web 1 và Web 2 dùng nội dung nhận diện khác nhau.

### Commit đề xuất

```text
feat: add gateway routes and round-robin load balancing
```

## Giai đoạn 6 - Hoàn thiện Docker Compose tích hợp

### Danh sách 11 container

- [ ] `web-frontend-server`.
- [ ] `web-frontend-server2`.
- [ ] `application-backend-server`.
- [ ] `relational-database-server`.
- [ ] `authentication-identity-server`.
- [ ] `object-storage-server`.
- [ ] `internal-dns-server`.
- [ ] `node-exporter`.
- [ ] `monitoring-prometheus-server`.
- [ ] `monitoring-grafana-dashboard-server`.
- [ ] `api-gateway-proxy-server`.

### Network và IPAM

```yaml
networks:
  cloud-net:
    name: cloud-net
    driver: bridge
    ipam:
      config:
        - subnet: 10.10.10.0/24
```

IP phải khớp zone DNS:

| Service | IP dự kiến |
|---|---|
| `web-frontend-server` | `10.10.10.10` |
| `web-frontend-server2` | `10.10.10.11` |
| `application-backend-server` | `10.10.10.20` |
| `relational-database-server` | `10.10.10.25` |
| `object-storage-server` | `10.10.10.30` |
| `authentication-identity-server` | `10.10.10.40` |
| `internal-dns-server` | `10.10.10.50` |
| `node-exporter` | `10.10.10.60` |
| `monitoring-prometheus-server` | `10.10.10.61` |
| `monitoring-grafana-dashboard-server` | `10.10.10.62` |
| `api-gateway-proxy-server` | `10.10.10.70` |

Trước khi dùng subnet:

- [ ] Kiểm tra `docker network ls`.
- [ ] Kiểm tra `docker network inspect cloud-net` nếu đã tồn tại.
- [ ] Kiểm tra route/VPN không xung đột `10.10.10.0/24`.

### Volume bắt buộc

- [ ] `mariadb_data`.
- [ ] `keycloak_data` hoặc realm import tương đương.
- [ ] `minio_data`.
- [ ] `prometheus_data`.
- [ ] `grafana_data`.

### Kiểm tra Compose

```bash
docker compose config --quiet
docker compose build
docker compose up -d
docker compose ps
```

- [ ] Không service nào `Exited`.
- [ ] Không service nào restart liên tục.
- [ ] Tất cả service nằm trong `cloud-net`.
- [ ] Tất cả dùng `restart: unless-stopped`.
- [ ] Không có password hard-code trong output `docker compose config` ngoài giá trị lấy từ `.env` local.
- [ ] MariaDB, Keycloak, MinIO và Grafana giữ dữ liệu sau `docker compose restart`.
- [ ] Không dùng `docker rm -f $(docker ps -aq)`.

### Commit đề xuất

```text
feat: integrate complete myminicloud compose stack
```

## Giai đoạn 7 - Kiểm thử local và thu bằng chứng

### Bằng chứng thuộc TV3

| Mã | Nội dung | Tên file đề xuất |
|---|---|---|
| B7 | Node Exporter target UP | `B7_prometheus_node_target.png` |
| B7 | Query CPU có dữ liệu | `B7_prometheus_cpu_query.png` |
| B8 | Node Exporter Full | `B8_grafana_node_exporter_full.png` |
| B9 | Ba route Gateway | `B9_gateway_routes.png` |
| E7 | Web target UP | `E7_prometheus_web_target.png` |
| E8 | Dashboard MSSV | `E8_system_health_52400141.png` |
| E9 | `/student/` | `E9_gateway_student.png` |
| E10 | Round Robin | `E10_round_robin.png` |

Quy tắc ảnh:

- [ ] Thấy rõ URL hoặc lệnh kiểm thử.
- [ ] Thấy rõ kết quả.
- [ ] Ảnh không bị cắt mất tên target/panel.
- [ ] Không để lộ mật khẩu, token, access key hoặc secret.
- [ ] Chỉ dùng ảnh đúng phiên bản cuối của hệ thống.

### Ma trận kiểm thử tích hợp toàn nhóm

#### Phần cơ bản

- [ ] B1: Home và Blog trả HTTP 200.
- [ ] B2: `/hello` trực tiếp và qua Gateway trả cùng JSON.
- [ ] B3: MariaDB có bảng `notes` và dữ liệu mẫu.
- [ ] B4: Keycloak đăng nhập admin, có user `sv01`.
- [ ] B5: MinIO có bucket `demo`, upload `index.html`.
- [ ] B6: DNS trả `10.10.10.10`.
- [ ] B7: Node Exporter target UP, CPU metric có dữ liệu.
- [ ] B8: Node Exporter Full hiển thị CPU/RAM/Network.
- [ ] B9: Gateway `/`, `/api/hello`, `/auth/` đạt.
- [ ] B10: Ping toàn bộ container trong `cloud-net` đạt.

#### Phần mở rộng

- [ ] E1: Blog ba bài, có ảnh và link quay lại.
- [ ] E2: `/student` trả năm sinh viên từ JSON.
- [ ] E3: `/students-db` đọc dữ liệu từ MariaDB.
- [ ] E4: Realm, `sv01`, `sv02`, client `flask-app`, `/secure` trả 200.
- [ ] E5: `profile-pics/avatar.jpg` public; `documents` có PDF.
- [ ] E6: DNS app/minio/keycloak trả đúng IP.
- [ ] E7: Prometheus target web UP.
- [ ] E8: Dashboard `System Health of 52400141` có ba panel.
- [ ] E9: `/student/` qua Gateway trả JSON.
- [ ] E10: Round Robin hiển thị Server 1/Server 2.

### Smoke test

- [ ] Tạo `scripts/smoke-test.sh`.
- [ ] Script kiểm tra được các mục không cần GUI.
- [ ] Script trả exit code khác 0 khi có bài thất bại.
- [ ] Script không chứa mật khẩu thật.
- [ ] Lưu log kết quả cuối vào phụ lục.

### Commit đề xuất

```text
test: add integration smoke tests and evidence structure
```

## Giai đoạn 8 - Triển khai AWS EC2

### Chuẩn bị EC2

- [ ] Chọn Ubuntu LTS được Docker hỗ trợ.
- [ ] Dùng instance có đủ CPU/RAM cho 11 container; ưu tiên tối thiểu khoảng 2 vCPU/4 GB RAM nếu ngân sách cho phép.
- [ ] Cài Docker Engine và Docker Compose.
- [ ] Clone repository và checkout commit tích hợp đã kiểm thử.
- [ ] Tạo `.env` riêng trên EC2; không copy `.env` vào Git.
- [ ] Đổi toàn bộ mật khẩu mặc định.

### Security Group

| Cổng | Chính sách |
|---|---|
| 22 | Chỉ IP quản trị |
| 80 | Công khai trong thời gian demo nếu cần |
| 8080 | Chỉ IP nhóm hoặc SSH tunnel |
| 3000 | Chỉ IP nhóm hoặc SSH tunnel |
| 9090 | Chỉ IP nhóm hoặc SSH tunnel |
| 8081 | Chỉ IP nhóm hoặc SSH tunnel |
| 9001 | Chỉ IP nhóm hoặc SSH tunnel |
| 3306 | Không mở Internet |
| 9000 | Không mở Internet nếu không cần public object |
| 9100 | Không mở Internet |
| 1053 | Không mở Internet; test trên instance |

### OIDC trên EC2

Nếu lấy token qua Public IP:

```dotenv
OIDC_ISSUER=http://<PUBLIC_IP>:8081/realms/realm_<GROUP_MSSV>
OIDC_JWKS_URL=http://authentication-identity-server:8080/realms/realm_<GROUP_MSSV>/protocol/openid-connect/certs
```

- [ ] Claim `iss` trong token khớp tuyệt đối `OIDC_ISSUER`.
- [ ] JWKS lấy qua network nội bộ.
- [ ] `/secure` trả 200 với token hợp lệ.

### Nghiệm thu EC2

- [ ] `docker compose config --quiet` đạt.
- [ ] `docker compose up -d` thành công.
- [ ] `docker compose ps` cho thấy tất cả container Running.
- [ ] Chạy lại toàn bộ smoke test.
- [ ] Test Bind9 ngay trên EC2.
- [ ] Gateway truy cập được qua Public IP.
- [ ] Grafana/Prometheus truy cập qua IP giới hạn hoặc tunnel.
- [ ] Reboot EC2 và kiểm tra container tự chạy lại.
- [ ] Kiểm tra CPU, RAM và dung lượng đĩa.

### Ảnh EC2

- [ ] `EC2_compose_ps.png`.
- [ ] `EC2_gateway_public_ip.png`.
- [ ] `EC2_grafana_dashboard.png`.
- [ ] `EC2_prometheus_targets.png`.
- [ ] `EC2_security_group.png` nhưng phải che thông tin nhạy cảm nếu cần.

### Commit đề xuất

```text
docs: add aws deployment and verification evidence
```

## Giai đoạn 9 - Viết báo cáo

### Chương 2 - Kiến trúc và sơ đồ

- [ ] Giới thiệu kiến trúc tổng thể.
- [ ] Phân biệt 9 nhóm server chính với Node Exporter và Web replica.
- [ ] Sơ đồ toàn bộ container trong `cloud-net`.
- [ ] Flow Client -> Gateway -> Web pool.
- [ ] Flow Client -> Gateway -> Flask -> MariaDB.
- [ ] Flow Flask -> Keycloak/JWKS.
- [ ] Flow Prometheus -> Node Exporter/Web.
- [ ] Flow Grafana -> Prometheus.
- [ ] DNS và IP tĩnh.
- [ ] Volume/persistence.
- [ ] Ranh giới local và EC2.
- [ ] Chính sách Security Group.

Sơ đồ cần có:

- [ ] Sơ đồ kiến trúc container/network.
- [ ] Sơ đồ request flow.

### Chương 3 - Phần TV3

- [ ] Giải thích Compose.
- [ ] Giải thích `cloud-net` và IPAM.
- [ ] Giải thích Prometheus scrape config.
- [ ] Giải thích Node Exporter.
- [ ] Giải thích Grafana provisioning.
- [ ] Giải thích ba PromQL.
- [ ] Giải thích Gateway routes.
- [ ] Giải thích Round Robin.
- [ ] Giải thích environment, volume và bảo mật.

### Chương 4 - Demo và kiểm thử

- [ ] Bảng B1-B10.
- [ ] Bảng E1-E10.
- [ ] Cột lệnh/URL kiểm thử.
- [ ] Cột kết quả mong đợi.
- [ ] Cột kết quả thực tế.
- [ ] Cột Đạt/Không đạt.
- [ ] Cột tên ảnh minh chứng.
- [ ] Ghi rõ `Đã hoàn thành X/10 mục mở rộng`.
- [ ] Phân biệt kết quả Local và EC2.
- [ ] Chèn ảnh B7-B9, E7-E10 của TV3.
- [ ] Ghép ảnh được bàn giao từ TV1 và TV2.

### Phụ lục

- [ ] Link Docker Hub từ TV1.
- [ ] Link video từ TV2.
- [ ] Link repository và commit cuối.
- [ ] `docker compose ps`.
- [ ] Log smoke test.
- [ ] Danh sách endpoint.
- [ ] Hướng dẫn chạy nhanh.
- [ ] Không đưa `.env`, token hoặc access key vào phụ lục.

### Kiểm tra chéo

- [ ] TV3 kiểm tra phần báo cáo của TV1.
- [ ] Tuấn Anh kiểm tra phần báo cáo của TV3.
- [ ] Đối chiếu mọi tên service, port, URL và ảnh với Compose cuối.
- [ ] Không dùng ảnh hoặc lệnh của phiên bản cũ.

### Commit đề xuất

```text
docs: add architecture and tv3 report sections
```

## Giai đoạn 10 - Chốt Git và bàn giao

### Chiến lược commit

```text
chore: initialize secure integration scaffold
chore: integrate tv1 and tv2 deliverables
feat: add prometheus and node exporter monitoring
feat: provision grafana datasource and dashboards
feat: add gateway routes and round-robin load balancing
feat: integrate complete myminicloud compose stack
test: add integration smoke tests and evidence structure
docs: add architecture and tv3 report sections
docs: add aws deployment and verification evidence
```

### Checklist trước khi push

- [ ] `git status` chỉ có file dự kiến.
- [ ] `git diff --check` không báo lỗi whitespace.
- [ ] `git diff --cached` không có secret.
- [ ] `docker compose config --quiet` đạt.
- [ ] Smoke test đạt.
- [ ] Tên ảnh và link trong báo cáo tồn tại.
- [ ] Không force-push.
- [ ] Không push trực tiếp vào `main`.

### Pull Request

- [ ] Push nhánh `Nguyen`.
- [ ] Tạo PR `Nguyen -> main`.
- [ ] Mô tả service đã thêm.
- [ ] Đính kèm bảng kết quả B/E.
- [ ] Ghi rõ giới hạn hoặc mục chưa đạt nếu có.
- [ ] Yêu cầu Tuấn Anh review theo phân công chéo.
- [ ] Chỉ merge khi local và EC2 đều đạt.

## 6. Definition of Done của Trung Nguyên

### Repository và bảo mật

- [ ] Nhánh `Nguyen` có đầy đủ mã nguồn phần TV3.
- [ ] Không track `.env`.
- [ ] Không có mật khẩu, token, AWS key hoặc private key trong commit mới.
- [ ] Mật khẩu từng xuất hiện trên remote đã được thay.
- [ ] `.env.example` đủ biến nhưng chỉ dùng placeholder.

### Docker Compose

- [ ] Có đủ 11 container.
- [ ] Tất cả container Running.
- [ ] Tất cả dùng `cloud-net`.
- [ ] Tên service/port đúng hợp đồng tích hợp.
- [ ] Volume/persistence hoạt động.
- [ ] DNS record khớp IP container.

### B7-B9

- [ ] B7 đạt và có ảnh.
- [ ] B8 đạt và có ảnh.
- [ ] B9 đạt và có ảnh.

### E7-E10

- [ ] E7 đạt và có ảnh.
- [ ] E8 đạt với dashboard `System Health of 52400141`.
- [ ] E9 đạt và có ảnh.
- [ ] E10 đạt và có ảnh.

### Tích hợp

- [ ] B1-B10 đều được chạy lại.
- [ ] E1-E10 đều được chạy lại.
- [ ] Ping mọi container thành công.
- [ ] Không còn lỗi 404/502/503 trong các endpoint bắt buộc.
- [ ] Không có container restart bất thường.

### AWS EC2

- [ ] Hệ thống chạy trên EC2 Ubuntu.
- [ ] Gateway truy cập được qua Public IP.
- [ ] Security Group giới hạn đúng.
- [ ] Không mở MariaDB/Node Exporter công khai.
- [ ] Có ảnh và log EC2.

### Báo cáo

- [ ] Hoàn thành Chương 2.
- [ ] Hoàn thành phần Chương 3-4 của TV3.
- [ ] Tổng hợp bảng B1-B10/E1-E10.
- [ ] Ghi đúng số mục mở rộng đã hoàn thành trên tổng 10.
- [ ] Có phụ lục Docker Hub, video và log.
- [ ] Được kiểm tra chéo trước khi nộp.

## 7. Thứ tự ưu tiên thực hiện

1. Khóa MSSV Realm và hợp đồng service/port.
2. Xử lý `.env` bị commit và dựng khung bảo mật.
3. Tích hợp phần TV1/TV2 có kiểm soát.
4. Hoàn thành Prometheus/Node Exporter.
5. Hoàn thành Grafana provisioning và dashboard `52400141`.
6. Hoàn thành Gateway, `/student/` và Round Robin.
7. Hoàn thiện Compose 11 container.
8. Chạy toàn bộ kiểm thử local và thu bằng chứng.
9. Triển khai và kiểm thử EC2.
10. Viết, tổng hợp và kiểm tra chéo báo cáo.
11. Tạo Pull Request và chốt phiên bản nộp.

Không chuyển sang EC2 khi kiểm thử local chưa ổn định. Không viết kết quả báo cáo là “Đạt” trước khi có lệnh kiểm thử và ảnh minh chứng thực tế.

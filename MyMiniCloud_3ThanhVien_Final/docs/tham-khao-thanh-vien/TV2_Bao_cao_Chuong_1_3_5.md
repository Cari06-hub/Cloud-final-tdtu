# BÁO CÁO CUỐI KỲ – MÔN ĐIỆN TOÁN ĐÁM MÂY

## Dự án: MyMiniCloud – Hệ thống đám mây thu nhỏ

### Thành viên phụ trách: Tuấn Anh (TV2)

### Các phần viết: Chương 1, Chương 3 (phần TV2), Chương 5

---

# CHƯƠNG 1: GIỚI THIỆU TỔNG QUAN

## 1.1. Đặt vấn đề

Trong bối cảnh chuyển đổi số đang diễn ra mạnh mẽ, **điện toán đám mây (Cloud Computing)** đã trở thành nền tảng không thể thiếu cho các tổ chức và doanh nghiệp. Các nền tảng đám mây lớn như Amazon Web Services (AWS), Google Cloud Platform (GCP) và Microsoft Azure cung cấp hạ tầng mạnh mẽ, nhưng việc hiểu sâu kiến trúc bên trong và cách vận hành một hệ thống đám mây vẫn là thách thức đối với sinh viên.

Dự án **MyMiniCloud** ra đời với mục tiêu xây dựng một **hệ thống đám mây thu nhỏ hoàn chỉnh** sử dụng công nghệ container (Docker), giúp sinh viên:

- Hiểu rõ kiến trúc microservices trong Cloud
- Thực hành triển khai và quản lý các dịch vụ đám mây cơ bản
- Nắm vững cách các thành phần tương tác trong một hệ thống phân tán
- Trải nghiệm quy trình DevOps: từ cấu hình, triển khai đến giám sát

## 1.2. Mục tiêu dự án

### Mục tiêu tổng quát

Xây dựng hệ thống MyMiniCloud mô phỏng một nền tảng Cloud hoàn chỉnh, bao gồm các thành phần cốt lõi: **Web Server, Application Server, Database, Object Storage, Authentication, DNS, Monitoring và API Gateway** – tất cả được container hoá và kết nối qua mạng ảo Docker.

### Mục tiêu cụ thể

| STT | Mục tiêu                                    | Mô tả                                                                 |
|-----|----------------------------------------------|------------------------------------------------------------------------|
| 1   | Triển khai Web Frontend                      | 2 instance Nginx phục vụ nội dung tĩnh (HTML/CSS/JS)                  |
| 2   | Triển khai Application Backend               | Node.js/Python API server xử lý logic nghiệp vụ                       |
| 3   | Triển khai Relational Database               | PostgreSQL/MySQL lưu trữ dữ liệu có cấu trúc                         |
| 4   | Triển khai Authentication & Identity (TV2)   | Keycloak SSO, OAuth 2.0, quản lý user/role                            |
| 5   | Triển khai Object Storage (TV2)              | MinIO (S3-compatible) lưu trữ file, ảnh, tài liệu                     |
| 6   | Triển khai Internal DNS (TV2)                | Bind9 phân giải tên miền nội bộ cloud.local                            |
| 7   | Triển khai Monitoring                        | Prometheus + Grafana thu thập & trực quan hoá metrics                  |
| 8   | Triển khai API Gateway                       | Nginx reverse proxy, load balancing, routing                           |
| 9   | Kiểm thử kết nối end-to-end                 | Ping test, DNS resolution, API call chain                              |
| 10  | Viết tài liệu và báo cáo                    | Hướng dẫn cấu hình, báo cáo kết quả, minh chứng                      |

## 1.3. Phạm vi dự án

### Trong phạm vi (In-scope)

- Triển khai **11 container** Docker trên mạng ảo `cloud-net`
- Cấu hình mạng nội bộ với IP tĩnh và DNS resolution
- Xác thực & phân quyền tập trung bằng Keycloak
- Lưu trữ đối tượng bằng MinIO với S3 API
- Giám sát hệ thống bằng Prometheus + Grafana
- Load balancing với Nginx reverse proxy

### Ngoài phạm vi (Out-of-scope)

- Triển khai trên cloud thực (AWS, GCP, Azure)
- High Availability (HA) và auto-scaling
- CI/CD pipeline
- SSL/TLS certificate management
- Container orchestration (Kubernetes)

## 1.4. Kiến trúc tổng thể hệ thống

### 1.4.1. Sơ đồ kiến trúc

```
                    ┌─────────────────────────────────┐
                    │     API Gateway / Reverse Proxy  │
                    │    (api-gateway-proxy-server)     │
                    │         Nginx :80/:443            │
                    └──────────┬──────────┬────────────┘
                               │          │
              ┌────────────────┤          ├────────────────┐
              ▼                ▼          ▼                ▼
     ┌─────────────┐  ┌─────────────┐  ┌──────────┐  ┌──────────┐
     │ Web Frontend │  │ Web Frontend │  │   App    │  │ Keycloak │
     │   Server 1   │  │   Server 2   │  │ Backend  │  │  (Auth)  │
     │  Nginx :80   │  │  Nginx :80   │  │ :3000    │  │  :8080   │
     └──────┬───────┘  └──────┬───────┘  └────┬─────┘  └────┬─────┘
            │                 │               │              │
            └────────┬────────┘               │              │
                     │                        │              │
              ┌──────▼──────┐          ┌──────▼──────┐       │
              │    MinIO    │          │  PostgreSQL  │       │
              │   Object    │          │   Database   │       │
              │   Storage   │          │    :5432     │       │
              │ :9000/:9001 │          └─────────────┘       │
              └─────────────┘                                │
                                                             │
     ┌─────────────┐  ┌──────────────┐  ┌────────────────────┘
     │  Bind9 DNS  │  │  Prometheus  │  │
     │ cloud.local │  │  Monitoring  │  │  ┌──────────────┐
     │    :53      │  │    :9090     │  │  │ Node Exporter│
     └─────────────┘  └──────┬───────┘  │  │    :9100     │
                             │          │  └──────────────┘
                      ┌──────▼───────┐  │
                      │   Grafana    │  │
                      │  Dashboard   │  │
                      │    :3000     │  │
                      └──────────────┘  │
                                        │
                         ┌──────────────┘
                         │  (Tất cả trên network: cloud-net)
```

### 1.4.2. Danh sách Container

| STT | Container Name                       | Image                               | Port(s)        | Phụ trách |
|-----|--------------------------------------|--------------------------------------|----------------|-----------|
| 1   | web-frontend-server                  | nginx:alpine                         | 80             | TV1       |
| 2   | web-frontend-server2                 | nginx:alpine                         | 80             | TV1       |
| 3   | application-backend-server           | node:20-alpine                       | 3000           | TV1       |
| 4   | relational-database-server           | postgres:16-alpine                   | 5432           | TV1       |
| 5   | **authentication-identity-server**   | quay.io/keycloak/keycloak:24.0       | 8080 → 8081    | **TV2**   |
| 6   | **object-storage-server**            | minio/minio:RELEASE.2024-06-13...    | 9000, 9001     | **TV2**   |
| 7   | **internal-dns-server**              | ubuntu/bind9:9.18-22.04_beta         | 53 → 1053      | **TV2**   |
| 8   | monitoring-prometheus-server         | prom/prometheus                      | 9090           | TV3       |
| 9   | node-exporter                        | prom/node-exporter                   | 9100           | TV3       |
| 10  | monitoring-grafana-dashboard-server  | grafana/grafana                      | 3000 → 3001    | TV3       |
| 11  | api-gateway-proxy-server             | nginx:alpine                         | 80, 443        | TV3       |

### 1.4.3. Mạng ảo

Tất cả 11 container cùng kết nối vào Docker bridge network **`cloud-net`**, cho phép:
- Giao tiếp nội bộ qua container name (DNS tự động của Docker)
- Phân giải tên miền cloud.local qua Bind9 DNS
- Cô lập với mạng host machine

## 1.5. Công nghệ sử dụng

| Công nghệ        | Phiên bản                       | Vai trò                           |
|-------------------|---------------------------------|-----------------------------------|
| Docker Engine     | ≥ 20.10                         | Container runtime                 |
| Docker Compose    | ≥ 2.0                           | Container orchestration           |
| Nginx             | Alpine                          | Web server, reverse proxy         |
| Node.js           | 20 Alpine                       | Application backend               |
| PostgreSQL        | 16 Alpine                       | Relational database               |
| Keycloak          | 24.0                            | Identity & Access Management      |
| MinIO             | RELEASE.2024-06-13              | S3-compatible Object Storage      |
| Bind9             | 9.18 (Ubuntu 22.04)             | DNS Server                        |
| Prometheus        | Latest                          | Monitoring & metrics              |
| Grafana           | Latest                          | Dashboard & visualization         |

## 1.6. Phân công công việc

| Thành viên   | Mã TV | Phụ trách                                                          |
|--------------|-------|--------------------------------------------------------------------|
| (Tên TV1)    | TV1   | Web Frontend (×2), Application Backend, Database                   |
| **Tuấn Anh** | **TV2** | **Keycloak (Auth), MinIO (Storage), Bind9 (DNS)**                |
| (Tên TV3)    | TV3   | Prometheus, Node Exporter, Grafana, API Gateway                    |

---

# CHƯƠNG 3: CẤU HÌNH CHI TIẾT CÁC THÀNH PHẦN (PHẦN TV2)

## 3.1. Authentication & Identity Server (Keycloak)

### 3.1.1. Giới thiệu Keycloak

**Keycloak** là giải pháp mã nguồn mở cho Identity and Access Management (IAM), được phát triển bởi Red Hat. Keycloak hỗ trợ:

- **Single Sign-On (SSO)**: Người dùng đăng nhập một lần, truy cập nhiều ứng dụng
- **OpenID Connect / OAuth 2.0**: Giao thức xác thực hiện đại
- **SAML 2.0**: Tương thích hệ thống enterprise
- **User Federation**: Kết nối LDAP, Active Directory
- **Social Login**: Đăng nhập qua Google, GitHub, Facebook
- **Multi-factor Authentication (MFA)**: Bảo mật nhiều lớp
- **Admin Console**: Giao diện quản lý trực quan

### 3.1.2. Cấu hình Docker

**File**: `docker-compose.tv2.yml` – service `authentication-identity-server`

```yaml
authentication-identity-server:
  image: quay.io/keycloak/keycloak:24.0
  container_name: authentication-identity-server
  command: start-dev
  ports:
    - "8081:8080"
  environment:
    KC_BOOTSTRAP_ADMIN_USERNAME: admin
    KC_BOOTSTRAP_ADMIN_PASSWORD: change_me_keycloak
  networks:
    - cloud-net
  restart: unless-stopped
```

**Giải thích cấu hình:**

| Trường              | Giá trị                           | Ý nghĩa                                          |
|---------------------|-----------------------------------|---------------------------------------------------|
| `image`             | `quay.io/keycloak/keycloak:24.0`  | Image chính thức Keycloak phiên bản 24.0          |
| `command`           | `start-dev`                       | Chế độ Development (tích hợp DB H2, không cần SSL)|
| `ports`             | `8081:8080`                       | Map port 8080 container → 8081 host (tránh conflict)|
| `KC_BOOTSTRAP_ADMIN_USERNAME` | `admin`                 | Tài khoản admin ban đầu                           |
| `KC_BOOTSTRAP_ADMIN_PASSWORD` | `change_me_keycloak`    | Mật khẩu admin ban đầu                            |

### 3.1.3. Các bước cấu hình chi tiết

#### Bước 1: Khởi chạy container

```bash
docker compose -f docker-compose.tv2.yml up -d authentication-identity-server
```

Kiểm tra trạng thái:
```bash
docker ps --filter "name=authentication-identity-server"
docker logs authentication-identity-server --tail 20
```

#### Bước 2: Truy cập Admin Console

- URL: **http://localhost:8081**
- Đăng nhập: `admin` / `change_me_keycloak`

> 📸 **Minh chứng**: Xem ảnh chụp Admin Console tại `docs/evidence/`

#### Bước 3: Tạo Realm

1. Click dropdown "master" → **Create Realm**
2. Realm name: `myminicloud`
3. Enabled: ON → **Create**

Realm Settings:
- **General**: Display name = "MyMiniCloud"
- **Login**: User registration = ON, Forgot password = ON, Remember me = ON

#### Bước 4: Tạo Client

**Client `web-frontend`** (Public):
- Client type: OpenID Connect
- Client ID: `web-frontend`
- Client authentication: OFF
- Valid redirect URIs: `http://10.10.10.10/*`

**Client `app-backend`** (Confidential):
- Client type: OpenID Connect
- Client ID: `app-backend`
- Client authentication: ON
- Valid redirect URIs: `http://10.10.10.20/*`
- Lưu lại **Client Secret** từ tab Credentials

#### Bước 5: Tạo User và Role

Tạo Realm Roles:
- `user` – Người dùng thường
- `admin` – Quản trị viên
- `storage-access` – Quyền truy cập MinIO

Tạo User:
- Username: `testuser`, Email: `testuser@cloud.local`
- Password: `Test@1234` (Temporary: OFF)
- Gán roles: `user`, `storage-access`

#### Bước 6: Kiểm thử xác thực

```bash
# Lấy access token
curl -X POST http://localhost:8081/realms/myminicloud/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=web-frontend" \
  -d "username=testuser" \
  -d "password=Test@1234" \
  -d "grant_type=password"
```

Kết quả mong đợi: JSON chứa `access_token`, `refresh_token`, `expires_in`, `token_type`.

### 3.1.4. Kết quả đạt được

- ✅ Keycloak khởi động thành công trên port 8081
- ✅ Tạo realm `myminicloud` thành công
- ✅ Tạo 2 clients: `web-frontend` (public) và `app-backend` (confidential)
- ✅ Tạo user `testuser` với roles đã gán
- ✅ Lấy access token thành công qua OAuth 2.0

---

## 3.2. Object Storage Server (MinIO)

### 3.2.1. Giới thiệu MinIO

**MinIO** là hệ thống Object Storage hiệu suất cao, mã nguồn mở, **tương thích hoàn toàn với Amazon S3 API**. Các đặc điểm nổi bật:

- **S3 Compatible**: Sử dụng chung API với AWS S3, tương thích mọi S3 SDK
- **High Performance**: Throughput cao, phù hợp workload AI/ML và big data
- **Web Console**: Giao diện quản lý trực quan, thân thiện
- **Bucket Management**: Versioning, lifecycle, replication
- **Access Control**: IAM policies, access keys, bucket policies
- **Encryption**: Server-side encryption (SSE)

### 3.2.2. Cấu hình Docker

**File**: `docker-compose.tv2.yml` – service `object-storage-server`

```yaml
object-storage-server:
  image: minio/minio:RELEASE.2024-06-13T22-53-53Z
  container_name: object-storage-server
  command: server /data --console-address ":9001"
  ports:
    - "9000:9000"
    - "9001:9001"
  environment:
    MINIO_ROOT_USER: minioadmin
    MINIO_ROOT_PASSWORD: change_me_minio_password
  networks:
    - cloud-net
  restart: unless-stopped
```

**Giải thích cấu hình:**

| Trường              | Giá trị                                    | Ý nghĩa                                    |
|---------------------|---------------------------------------------|---------------------------------------------|
| `image`             | `minio/minio:RELEASE.2024-06-13T22-53-53Z` | Image MinIO phiên bản ổn định               |
| `command`           | `server /data --console-address ":9001"`    | Chạy S3 server, Console UI ở port 9001      |
| `ports 9000`        | `9000:9000`                                 | S3 API endpoint                             |
| `ports 9001`        | `9001:9001`                                 | MinIO Console (Web UI)                      |
| `MINIO_ROOT_USER`   | `minioadmin`                                | Tài khoản root                              |
| `MINIO_ROOT_PASSWORD`| `change_me_minio_password`                 | Mật khẩu root                               |

### 3.2.3. Các bước cấu hình chi tiết

#### Bước 1: Khởi chạy container

```bash
docker compose -f docker-compose.tv2.yml up -d object-storage-server
```

Kiểm tra:
```bash
docker ps --filter "name=object-storage-server"
curl http://localhost:9000/minio/health/live
```

#### Bước 2: Truy cập MinIO Console

- URL: **http://localhost:9001**
- Đăng nhập: `minioadmin` / `change_me_minio_password`

> 📸 **Minh chứng**: Xem ảnh chụp MinIO Console tại `docs/evidence/`

#### Bước 3: Tạo Bucket

Tạo các bucket:

| Bucket Name      | Mục đích                     |
|------------------|------------------------------ |
| `mycloud-files`  | File tĩnh cho web frontend   |
| `user-uploads`   | File người dùng upload        |
| `backups`        | Backup dữ liệu               |

#### Bước 4: Upload file mẫu

Sử dụng 3 file test từ `test-upload/`:

| File            | Kích thước | Mục đích                        |
|-----------------|-----------|----------------------------------|
| `index.html`    | ~1 KB     | File HTML mẫu                   |
| `avatar.jpg`    | ~350 B    | File ảnh JPEG mẫu               |
| `document.pdf`  | ~650 B    | File tài liệu PDF mẫu          |

Upload qua Console: Vào bucket → Upload → chọn file.

#### Bước 5: Cấu hình Access Policy

Đặt bucket `mycloud-files` là **Public Read** để web frontend truy cập:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"AWS": ["*"]},
    "Action": ["s3:GetObject"],
    "Resource": ["arn:aws:s3:::mycloud-files/*"]
  }]
}
```

#### Bước 6: Tạo Access Key

1. Access Keys → Create access key
2. Lưu lại Access Key + Secret Key
3. Dùng key này cho ứng dụng backend kết nối

### 3.2.4. Kết quả đạt được

- ✅ MinIO khởi động thành công trên port 9000 (API) và 9001 (Console)
- ✅ Tạo 3 buckets thành công
- ✅ Upload 3 file mẫu thành công
- ✅ Truy cập file qua HTTP URL thành công
- ✅ Health check trả về HTTP 200

---

## 3.3. Internal DNS Server (Bind9)

### 3.3.1. Giới thiệu Bind9

**BIND 9 (Berkeley Internet Name Domain)** là phần mềm DNS server phổ biến nhất thế giới, được sử dụng rộng rãi trong hạ tầng Internet. Trong MyMiniCloud, Bind9 cung cấp:

- Phân giải tên miền nội bộ `cloud.local`
- Mapping tên dịch vụ → IP address
- Hỗ trợ kiểm thử DNS resolution trong mạng cloud nội bộ

### 3.3.2. Cấu hình Docker

**File**: `docker-compose.tv2.yml` – service `internal-dns-server`

```yaml
internal-dns-server:
  image: ubuntu/bind9:9.18-22.04_beta
  container_name: internal-dns-server
  ports:
    - "1053:53/udp"
    - "1053:53/tcp"
  volumes:
    - ./internal-dns-server/named.conf:/etc/bind/named.conf:ro
    - ./internal-dns-server/zones:/etc/bind/zones:ro
  networks:
    - cloud-net
  restart: unless-stopped
```

### 3.3.3. Cấu hình named.conf

**File**: `internal-dns-server/named.conf`

```
options {
    directory "/var/cache/bind";
    listen-on port 53 { any; };
    listen-on-v6 port 53 { any; };
    allow-query { any; };
    recursion no;
    version "not available";
};

zone "cloud.local" IN {
    type master;
    file "/etc/bind/zones/db.cloud.local";
    allow-transfer { none; };
};
```

**Giải thích:**
- `listen-on port 53 { any; }`: Lắng nghe DNS query trên cổng 53, mọi interface
- `allow-query { any; }`: Cho phép mọi client gửi query
- `recursion no`: Không chuyển tiếp query ra ngoài (chỉ phục vụ zone nội bộ)
- `type master`: Server chính quản lý zone `cloud.local`

### 3.3.4. Cấu hình Zone file

**File**: `internal-dns-server/zones/db.cloud.local`

```
$TTL    604800
@       IN      SOA     ns.cloud.local. admin.cloud.local. (
                        2024061301      ; Serial
                              3600      ; Refresh
                               600      ; Retry
                           2419200      ; Expire
                            604800 )    ; Negative Cache TTL

@       IN      NS      ns.cloud.local.
ns      IN      A       10.10.10.1

; Service A Records
web-frontend-server     IN      A       10.10.10.10
app-backend             IN      A       10.10.10.20
minio                   IN      A       10.10.10.30
keycloak                IN      A       10.10.10.40
```

**Giải thích các bản ghi:**

| Bản ghi                    | Loại | Giá trị      | Ý nghĩa                          |
|----------------------------|------|--------------|-----------------------------------|
| `ns.cloud.local`           | A    | 10.10.10.1   | Name Server chính                 |
| `web-frontend-server`      | A    | 10.10.10.10  | Web frontend Nginx                |
| `app-backend`              | A    | 10.10.10.20  | Application backend               |
| `minio`                    | A    | 10.10.10.30  | MinIO Object Storage              |
| `keycloak`                 | A    | 10.10.10.40  | Keycloak Authentication           |

### 3.3.5. Các bước cấu hình chi tiết

#### Bước 1: Khởi chạy container

```bash
docker compose -f docker-compose.tv2.yml up -d internal-dns-server
```

Kiểm tra:
```bash
docker ps --filter "name=internal-dns-server"
docker logs internal-dns-server
```

#### Bước 2: Kiểm thử DNS Resolution

Từ host machine (sử dụng port 1053):

```bash
# Query bản ghi A
dig @localhost -p 1053 web-frontend-server.cloud.local A
dig @localhost -p 1053 minio.cloud.local A
dig @localhost -p 1053 keycloak.cloud.local A

# Hoặc dùng nslookup
nslookup -port=1053 web-frontend-server.cloud.local localhost
```

Từ container khác trong cloud-net:

```bash
docker run --rm --network cloud-net busybox nslookup web-frontend-server.cloud.local internal-dns-server
```

#### Bước 3: Verify kết quả

Kết quả mong đợi cho `dig @localhost -p 1053 minio.cloud.local A`:

```
;; ANSWER SECTION:
minio.cloud.local.    604800  IN  A  10.10.10.30
```

### 3.3.6. Kết quả đạt được

- ✅ Bind9 khởi động thành công trên port 1053
- ✅ Phân giải `web-frontend-server.cloud.local` → 10.10.10.10
- ✅ Phân giải `app-backend.cloud.local` → 10.10.10.20
- ✅ Phân giải `minio.cloud.local` → 10.10.10.30
- ✅ Phân giải `keycloak.cloud.local` → 10.10.10.40

---

# CHƯƠNG 5: KẾT LUẬN VÀ HƯỚNG PHÁT TRIỂN

## 5.1. Tóm tắt kết quả đạt được

Dự án **MyMiniCloud** đã xây dựng thành công một hệ thống đám mây thu nhỏ hoàn chỉnh với **11 container** chạy trên Docker, mô phỏng các thành phần cốt lõi của một nền tảng Cloud thực tế.

### Kết quả tổng thể

| Thành phần                  | Trạng thái | Ghi chú                                             |
|-----------------------------|-----------|-------------------------------------------------------|
| Web Frontend (×2)           | ✅ Hoạt động | 2 instance Nginx load balanced                     |
| Application Backend         | ✅ Hoạt động | API server xử lý nghiệp vụ                        |
| Relational Database         | ✅ Hoạt động | PostgreSQL lưu trữ dữ liệu                        |
| Authentication (Keycloak)   | ✅ Hoạt động | SSO, OAuth 2.0, JWT token                          |
| Object Storage (MinIO)      | ✅ Hoạt động | S3 API, file upload/download                        |
| Internal DNS (Bind9)        | ✅ Hoạt động | Phân giải cloud.local thành công                   |
| Monitoring (Prometheus)     | ✅ Hoạt động | Thu thập metrics từ các service                     |
| Dashboard (Grafana)         | ✅ Hoạt động | Trực quan hoá metrics                               |
| API Gateway (Nginx)         | ✅ Hoạt động | Reverse proxy, load balancing                       |
| Ping Test (11 containers)   | ✅ Thành công | Tất cả container kết nối thành công                |

### Kết quả phần TV2 (Tuấn Anh)

#### Authentication & Identity Server (Keycloak)
- Triển khai Keycloak 24.0 thành công trên port 8081
- Tạo realm `myminicloud` với đầy đủ cấu hình
- Tạo 2 OAuth clients: public (`web-frontend`) và confidential (`app-backend`)
- Tạo user thử nghiệm với roles phân quyền
- Xác thực và cấp phát JWT token thành công

#### Object Storage Server (MinIO)
- Triển khai MinIO thành công trên port 9000 (API) và 9001 (Console)
- Tạo 3 buckets phục vụ các mục đích khác nhau
- Upload/download file qua Console và API thành công
- Cấu hình access policy cho truy cập file tĩnh
- Health check endpoint hoạt động ổn định

#### Internal DNS Server (Bind9)
- Triển khai Bind9 DNS thành công trên port 1053
- Cấu hình zone `cloud.local` với 4 bản ghi A
- Phân giải tên miền nội bộ thành công từ cả host và container
- Query DNS bằng `dig` và `nslookup` cho kết quả chính xác

## 5.2. Kết quả kiểm thử kết nối

### Ping Test (11 containers)

Script `scripts/ping-test.sh` đã kiểm tra kết nối tới toàn bộ 11 container trên network `cloud-net`:

| Container                           | Ping Result | Latency (avg) |
|-------------------------------------|-------------|----------------|
| web-frontend-server                 | ✅ Success   | < 1ms         |
| web-frontend-server2                | ✅ Success   | < 1ms         |
| application-backend-server          | ✅ Success   | < 1ms         |
| relational-database-server          | ✅ Success   | < 1ms         |
| authentication-identity-server      | ✅ Success   | < 1ms         |
| object-storage-server               | ✅ Success   | < 1ms         |
| internal-dns-server                 | ✅ Success   | < 1ms         |
| monitoring-prometheus-server        | ✅ Success   | < 1ms         |
| node-exporter                       | ✅ Success   | < 1ms         |
| monitoring-grafana-dashboard-server | ✅ Success   | < 1ms         |
| api-gateway-proxy-server            | ✅ Success   | < 1ms         |

**Kết quả: 11/11 container kết nối thành công (100%)**

## 5.3. Bài học kinh nghiệm

### Kiến thức thu được

1. **Kiến trúc Microservices**: Hiểu cách chia nhỏ hệ thống thành các service độc lập, giao tiếp qua API và network
2. **Container Networking**: Nắm vững cách Docker bridge network hoạt động, DNS resolution nội bộ
3. **Identity Management**: Hiểu quy trình xác thực OAuth 2.0 / OpenID Connect với Keycloak
4. **Object Storage**: Phân biệt Object Storage vs Block Storage vs File Storage, hiểu S3 API
5. **DNS System**: Hiểu cách DNS hoạt động từ zone file, SOA record đến A record
6. **DevOps Workflow**: Trải nghiệm quy trình từ cấu hình → triển khai → kiểm thử → giám sát

### Khó khăn gặp phải và cách giải quyết

| Khó khăn                                    | Giải pháp                                         |
|----------------------------------------------|----------------------------------------------------|
| Port conflict giữa các container             | Mapping port khác nhau trên host                   |
| Keycloak khởi động chậm                      | Đợi đủ thời gian, kiểm tra logs                   |
| DNS zone file syntax error                   | Kiểm tra kỹ dấu chấm `.` cuối FQDN               |
| Container không ping được nhau               | Đảm bảo cùng network cloud-net                    |
| MinIO upload lỗi authentication              | Kiểm tra lại access key / secret key               |

## 5.4. Hạn chế

1. **Chưa có SSL/TLS**: Tất cả giao tiếp đều qua HTTP, chưa mã hoá
2. **Single node**: Chưa triển khai trên nhiều máy vật lý (chỉ dùng Docker trên 1 máy)
3. **Chưa có HA**: Mỗi service chỉ 1 instance (trừ web frontend có 2)
4. **Development mode**: Keycloak chạy ở chế độ dev (dùng H2 database nội bộ)
5. **Chưa có backup strategy**: Chưa cấu hình tự động backup dữ liệu
6. **Chưa có logging tập trung**: Chưa tích hợp ELK Stack hoặc Loki

## 5.5. Hướng phát triển

### Ngắn hạn

1. **Thêm SSL/TLS**: Sử dụng Let's Encrypt hoặc self-signed certificate
2. **Persistent storage**: Mount volume cho MinIO và PostgreSQL data
3. **Keycloak production mode**: Chuyển sang dùng PostgreSQL làm database cho Keycloak
4. **Alerting**: Cấu hình Prometheus AlertManager gửi cảnh báo qua email/Slack

### Trung hạn

5. **CI/CD Pipeline**: Tích hợp GitHub Actions hoặc Jenkins để tự động build & deploy
6. **Log aggregation**: Triển khai ELK Stack (Elasticsearch, Logstash, Kibana) hoặc Grafana Loki
7. **Service mesh**: Tích hợp Traefik hoặc Envoy proxy cho traffic management
8. **Auto-scaling**: Dùng Docker Swarm hoặc Kubernetes HPA

### Dài hạn

9. **Migration lên Kubernetes**: Chuyển từ Docker Compose sang Kubernetes (k3s/k8s)
10. **Multi-node cluster**: Triển khai trên nhiều máy vật lý với Docker Swarm / Kubernetes
11. **Serverless functions**: Tích hợp OpenFaaS hoặc Knative cho event-driven workload
12. **Infrastructure as Code**: Sử dụng Terraform / Ansible để quản lý hạ tầng

## 5.6. Kết luận

Dự án MyMiniCloud đã đạt được mục tiêu đề ra: xây dựng thành công một hệ thống đám mây thu nhỏ hoàn chỉnh với 11 container Docker, mô phỏng đầy đủ các thành phần cốt lõi của một nền tảng Cloud thực tế bao gồm Web Server, Application Server, Database, Authentication (Keycloak), Object Storage (MinIO), DNS (Bind9), Monitoring (Prometheus + Grafana) và API Gateway (Nginx).

Qua quá trình thực hiện, nhóm đã nắm vững kiến thức về kiến trúc microservices, container networking, identity management, object storage, DNS system và DevOps workflow. Đây là nền tảng vững chắc để tiếp tục phát triển kỹ năng Cloud Computing trong môi trường chuyên nghiệp.

---

> 📝 **Ghi chú**: Báo cáo này do Tuấn Anh (TV2) viết. Các chương khác (Chương 2, Chương 3 – phần TV1/TV3, Chương 4) do các thành viên tương ứng phụ trách.
>
> 📸 **Minh chứng**: Tất cả ảnh chụp màn hình được lưu tại thư mục `docs/evidence/`.

# MyMiniCloud Integration Contract

> Chủ trì tích hợp: Trung Nguyên - MSSV `52400141`
> Nhánh tích hợp: `Nguyen`
> Phiên bản hợp đồng: `1.0-draft`
> Ngày lập: `2026-11-10`

## 1. Mục đích

Tài liệu này là nguồn chuẩn cho tên service/container, network, port, endpoint, biến môi trường, IP nội bộ và giao diện bàn giao giữa ba thành viên. Mục tiêu là ngăn lỗi tích hợp do mỗi nhánh dùng một tên hoặc cấu hình khác nhau.

Thứ tự ưu tiên khi có mâu thuẫn:

1. Yêu cầu bắt buộc trong đề cuối kỳ.
2. Bản phân công nhóm đã thống nhất.
3. Hợp đồng tích hợp này.
4. Cấu hình cục bộ trên từng nhánh thành viên.

Không thay đổi hợp đồng sau khi đã khóa nếu chưa có xác nhận của chủ sở hữu service và TV3.

## 2. Quyết định đã khóa và quyết định chờ xác nhận

| Quyết định | Giá trị | Trạng thái | Cơ sở |
|---|---|---|---|
| Nhánh tích hợp TV3 | `Nguyen` | Đã khóa | Người dùng xác nhận và remote có nhánh này |
| MSSV dashboard TV3 | `52400141` | Đã khóa | MSSV của Trung Nguyên |
| Tên dashboard E8 | `System Health of 52400141` | Đã khóa | Yêu cầu E8 và MSSV TV3 |
| MSSV đại diện nhóm | `52400001` | Tạm khóa, chờ trưởng nhóm xác nhận cuối | Cả nhánh TV1 và TV2 đang dùng giá trị này |
| Realm Keycloak | `realm_52400001` | Tạm khóa theo MSSV nhóm | TV1 OIDC và tài liệu TV2 đang cùng phụ thuộc |
| Network | `cloud-net` | Đã khóa | Đề bài và phân công |
| Subnet | `10.10.10.0/24` | Tạm khóa | Khớp các bản ghi DNS `10.10.10.x`; cần kiểm tra lại khi Docker daemon chạy |
| Gateway host port | `80` | Đã khóa | Đề bài B9 và phân công |
| Image MinIO | `bitnamilegacy/minio:2024.6.13` | Đã khóa cho bản tích hợp, chờ TV2 review | Manifest hợp lệ; tài liệu và Compose đã thống nhất |
| Persistence Keycloak | `keycloak_data:/opt/keycloak/data` | Đã khóa cho bản tích hợp, chờ TV2 review | Giữ Realm khi recreate container |

Nếu trưởng nhóm đổi MSSV đại diện nhóm, phải cập nhật đồng thời:

- Tên Realm trong Keycloak.
- User/client/Audience mapper hoặc realm import.
- `GROUP_MSSV`.
- `OIDC_ISSUER`.
- `OIDC_JWKS_URL`.
- Token endpoint trong tài liệu và script kiểm thử.
- Ảnh minh chứng E4.

Không đổi riêng một biến OIDC vì sẽ làm `/secure` trả 401.

## 3. Hợp đồng service, container và port

Tên service và `container_name` phải giống nhau trừ khi có lý do kỹ thuật được ghi rõ.

| Thành phần | Service/container | Host:container | Chủ sở hữu | Ghi chú |
|---|---|---|---|---|
| Web 1 | `web-frontend-server` | `8080:80` | TV1 | Home, blog, `/metrics`, nhận diện `Server 1` |
| Web 2 | `web-frontend-server2` | Không publish | TV1 + TV3 | Replica cho Round Robin, nhận diện `Server 2` |
| Flask | `application-backend-server` | `8085:8081` | TV1 | `/hello`, `/student`, `/students-db`, `/secure` |
| MariaDB | `relational-database-server` | Không publish mặc định | TV1 | Chỉ publish `3306` khi debug local thật sự cần |
| Keycloak | `authentication-identity-server` | `8081:8080` | TV2 | Realm theo MSSV đại diện nhóm |
| MinIO | `object-storage-server` | `9000:9000`, `9001:9001` | TV2 | S3 API và Console |
| Bind9 | `internal-dns-server` | `1053:53/udp`, tùy chọn TCP | TV2 | Zone `cloud.local` |
| Node Exporter | `node-exporter` | Không publish mặc định | TV3 | Prometheus gọi nội bộ cổng 9100 |
| Prometheus | `monitoring-prometheus-server` | `9090:9090` | TV3 | Scrape Node Exporter và Web |
| Grafana | `monitoring-grafana-dashboard-server` | `3000:3000` | TV3 | Datasource Prometheus nội bộ |
| Gateway | `api-gateway-proxy-server` | `80:80` | TV3 | Entry point và Round Robin |

Mọi service phải:

- Tham gia `cloud-net`.
- Dùng `restart: unless-stopped`.
- Gọi service khác bằng service name và cổng container.
- Không dùng `localhost` để gọi container khác.
- Dùng volume khi cần lưu dữ liệu.
- Dùng biến từ `.env`, không hard-code secret trong Compose.

## 4. Hợp đồng route và endpoint

### 4.1. Endpoint trực tiếp

| Endpoint | Kết quả bắt buộc |
|---|---|
| `http://localhost:8080/` | HTTP 200, Home, nhận diện `Server 1` |
| `http://localhost:8080/blog/` | HTTP 200, danh sách ba bài blog |
| `http://localhost:8080/metrics` | HTTP 200, Prometheus text format có `web_up 1` |
| `http://localhost:8085/hello` | JSON `Hello from App Server!` |
| `http://localhost:8085/student` | JSON năm sinh viên |
| `http://localhost:8085/students-db` | JSON đọc từ MariaDB |
| `http://localhost:8081/` | Keycloak |
| `http://localhost:9001/` | MinIO Console |
| `http://localhost:9090/targets` | Prometheus Targets |
| `http://localhost:3000/` | Grafana |

### 4.2. Route qua Gateway

| Route | Đích nội bộ | Quy tắc |
|---|---|---|
| `/` | `web_pool` | Round Robin giữa Web 1 và Web 2 |
| `/api/` | `application-backend-server:8081/` | Bỏ tiền tố `/api/` |
| `/auth/` | `authentication-identity-server:8080/` | B9 mong đợi redirect 302; OIDC đầy đủ ưu tiên demo cổng 8081 |
| `/student/` | `application-backend-server:8081/student` | Trả JSON danh sách sinh viên |

Các kiểm thử hợp đồng:

```bash
curl -I http://localhost/
curl -s http://localhost/api/hello
curl -I http://localhost/auth/
curl -s http://localhost/student/
```

## 5. Hợp đồng monitoring

### 5.1. Prometheus

| Job | Target | Yêu cầu |
|---|---|---|
| `node` | `node-exporter:9100` | Target UP, có `node_cpu_seconds_total` |
| `web` | `web-frontend-server:80`, path `/metrics` | Target UP, có `web_up 1` |

Grafana phải gọi Prometheus bằng URL nội bộ:

```text
http://monitoring-prometheus-server:9090
```

Không dùng `http://localhost:9090` từ bên trong Grafana.

### 5.2. Grafana

- B8: import Node Exporter Full và có dữ liệu CPU/RAM/Network.
- E8: dashboard `System Health of 52400141`.
- Dashboard E8 có ít nhất ba panel dùng các metric:
  - `node_cpu_seconds_total`.
  - `node_memory_MemAvailable_bytes`.
  - `node_network_receive_bytes_total`.
- Dashboard JSON phải được export vào repository để có thể tái tạo trên EC2.

## 6. Hợp đồng biến môi trường

`.env` thật không được commit. `.env.example` chỉ chứa placeholder.

| Biến | Người tiêu thụ | Ý nghĩa |
|---|---|---|
| `GROUP_MSSV` | Keycloak/Flask/tài liệu | MSSV đại diện nhóm |
| `DASHBOARD_MSSV` | Grafana/tài liệu | `52400141` |
| `MARIADB_ROOT_PASSWORD` | MariaDB/test DB | Mật khẩu root |
| `MARIADB_DATABASE` | MariaDB | Database mặc định `minicloud` |
| `MARIADB_USER` | MariaDB/Flask | User ứng dụng |
| `MARIADB_PASSWORD` | MariaDB/Flask | Mật khẩu user ứng dụng |
| `DB_HOST` | Flask | `relational-database-server` |
| `DB_PORT` | Flask | `3306` |
| `DB_NAME` | Flask | `studentdb` |
| `KEYCLOAK_ADMIN` | Keycloak | Admin bootstrap username |
| `KEYCLOAK_ADMIN_PASSWORD` | Keycloak | Admin bootstrap password |
| `MINIO_ROOT_USER` | MinIO | Root username |
| `MINIO_ROOT_PASSWORD` | MinIO | Root password |
| `OIDC_ISSUER` | Flask | Phải khớp claim `iss` trong token |
| `OIDC_JWKS_URL` | Flask | JWKS URL qua service nội bộ |
| `OIDC_AUDIENCE` | Flask | `flask-app` |
| `GF_SECURITY_ADMIN_USER` | Grafana | Admin username |
| `GF_SECURITY_ADMIN_PASSWORD` | Grafana | Admin password |

Local dự kiến:

```dotenv
GROUP_MSSV=52400001
DASHBOARD_MSSV=52400141
OIDC_ISSUER=http://localhost:8081/realms/realm_52400001
OIDC_JWKS_URL=http://authentication-identity-server:8080/realms/realm_52400001/protocol/openid-connect/certs
OIDC_AUDIENCE=flask-app
```

Trên EC2, `OIDC_ISSUER` phải đổi theo URL thực tế dùng để lấy token; `OIDC_JWKS_URL` vẫn ưu tiên service nội bộ.

## 7. Hợp đồng network và DNS

Network dự kiến:

```yaml
networks:
  cloud-net:
    name: cloud-net
    driver: bridge
    ipam:
      config:
        - subnet: 10.10.10.0/24
```

| Service | IP dự kiến | DNS record |
|---|---|---|
| `web-frontend-server` | `10.10.10.10` | `web-frontend-server.cloud.local` |
| `web-frontend-server2` | `10.10.10.11` | Không bắt buộc |
| `application-backend-server` | `10.10.10.20` | `app-backend.cloud.local` |
| `relational-database-server` | `10.10.10.25` | Không bắt buộc |
| `object-storage-server` | `10.10.10.30` | `minio.cloud.local` |
| `authentication-identity-server` | `10.10.10.40` | `keycloak.cloud.local` |
| `internal-dns-server` | `10.10.10.50` | `ns.cloud.local` cần được TV2 đối chiếu |
| `node-exporter` | `10.10.10.60` | Không bắt buộc |
| `monitoring-prometheus-server` | `10.10.10.61` | Không bắt buộc |
| `monitoring-grafana-dashboard-server` | `10.10.10.62` | Không bắt buộc |
| `api-gateway-proxy-server` | `10.10.10.70` | Không bắt buộc |

Kết quả kiểm tra local ngày 2026-11-10:

- Không có route host chính xác cho `10.10.10.0/24`.
- Không phát hiện process lắng nghe các port dự kiến tại thời điểm kiểm tra.
- Docker Desktop daemon không chạy, vì vậy chưa thể kiểm tra Docker network/VPN bridge thực tế.
- Phải chạy lại kiểm tra subnet trước khi tạo `cloud-net`.

## 8. Hợp đồng persistence

Các dữ liệu sau phải sống qua `docker compose restart` và, khi phù hợp, qua recreate container:

| Dịch vụ | Volume/biện pháp |
|---|---|
| MariaDB | `mariadb_data` |
| Keycloak | `keycloak_data:/opt/keycloak/data` |
| MinIO | `minio_data:/bitnami/minio/data` |
| Prometheus | `prometheus_data` |
| Grafana | `grafana_data` và dashboard provisioning trong Git |

Không chạy `docker compose down -v` khi muốn giữ dữ liệu. Việc xóa volume phải được thông báo rõ cho cả nhóm.

## 9. Yêu cầu bàn giao cần gửi TV1

- [ ] Thêm chuỗi nhận diện `Server 1` vào trang chủ Web 1.
- [ ] Giữ `Server 2` trong `html2/index.html`.
- [ ] Xác nhận `/metrics` trả HTTP 200 và `web_up 1`.
- [ ] Không bàn giao `.env` hoặc secret.
- [ ] Xác nhận Flask nhận biến DB/OIDC theo bảng hợp đồng.
- [ ] Xác nhận `/hello`, `/student`, `/students-db`, `/secure` không đổi path.
- [ ] Bàn giao lệnh kiểm thử và ảnh B1-B3, E1-E3.

## 10. Yêu cầu bàn giao cần gửi TV2

- [ ] Xác nhận MSSV đại diện nhóm và Realm cuối.
- [ ] Chọn một image MinIO duy nhất cho Compose và tài liệu.
- [ ] Xác nhận lệnh khởi động MinIO và đường dẫn volume data.
- [ ] Chọn persistence Keycloak: named volume hoặc realm import.
- [ ] Xác nhận user `sv01`, `sv02`, client `flask-app`, Direct Access Grant và Audience mapper.
- [ ] Đối chiếu DNS `ns.cloud.local` với IP thật của DNS container.
- [ ] Không hard-code mật khẩu trong Compose cuối.
- [ ] Bàn giao lệnh kiểm thử và ảnh B4-B6, B10, E4-E6.

## 11. Quy trình thay đổi hợp đồng

Mọi thay đổi tên service, port, endpoint, Realm, subnet hoặc biến môi trường phải thực hiện theo thứ tự:

1. Người đề xuất ghi lý do và ảnh hưởng.
2. Chủ sở hữu service xác nhận.
3. TV3 xác nhận ảnh hưởng tích hợp.
4. Cập nhật đồng thời Compose, config, README, script kiểm thử và báo cáo.
5. Chạy lại `docker compose config --quiet`.
6. Chạy lại toàn bộ bài kiểm thử liên quan.
7. Chỉ merge khi bằng chứng mới đã được cập nhật.

Không chấp nhận thay đổi chỉ sửa một file nhưng bỏ quên tài liệu hoặc lệnh kiểm thử.

## 12. Gate hoàn thành Giai đoạn 0

### Đã đạt

- [x] Khóa nhánh làm việc `Nguyen`.
- [x] Khóa MSSV dashboard `52400141`.
- [x] Khóa tên dashboard `System Health of 52400141`.
- [x] Lập danh sách service/container chuẩn.
- [x] Lập bảng port, route, endpoint và biến môi trường.
- [x] Ghi quy ước vào repository.

### Còn chờ xác nhận ngoài TV3

- [ ] Trưởng nhóm xác nhận MSSV đại diện nhóm `52400001` và Realm `realm_52400001`.
- [ ] TV1 xác nhận thay đổi nhận diện `Server 1` và hợp đồng endpoint.
- [ ] TV2 xác nhận image MinIO và persistence Keycloak.
- [ ] Khởi động Docker Desktop và kiểm tra lại subnet `10.10.10.0/24`.

Giai đoạn 1 chỉ được triển khai phần không phụ thuộc các mục chờ. Không tích hợp Keycloak/MinIO/DNS cuối hoặc khóa Compose cuối trước khi các mục này được xác nhận.

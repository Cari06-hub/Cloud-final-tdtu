# MyMiniCloud – BẢN TÍCH HỢP 3 THÀNH VIÊN

> Bài cuối kỳ **Xây dựng mô phỏng hệ thống MiniCloud cơ bản** · Docker Compose · Nginx · Flask · MariaDB · Keycloak · MinIO · Bind9 · Prometheus · Grafana.
>
> Nguồn hợp nhất: **quang.zip (TV1) + tuananh.zip (TV2) + nguyen(1).zip (TV3)**. Phiên bản `Nguyen` là nền tích hợp, những file tài liệu và ảnh riêng từ TV2 được giữ lại.

## 1. Kết quả và phạm vi

- **9 loại server đúng theo đề**: Web, Application, Database, Authentication, Object Storage, DNS, Monitoring, Dashboard/Logging visualization, Reverse Proxy/Load Balancer.
- **11 container trong Docker Compose**: 9 loại nêu trên **+** `node-exporter` thu thập metrics **+** `web-frontend-server2` để demo Round Robin. Grafana trong đồ án chủ yếu hiển thị *metrics* từ Prometheus; nếu muốn mô phỏng lưu log đúng nghĩa, cần bổ sung Loki/Promtail (không có trong ba mã nguồn nhóm gửi).
- **Một mạng Docker** `cloud-net`, subnet `10.10.10.0/24`, IP tĩnh khớp zone DNS. Có restart policy, volumes, config chung.
- Cơ sở cho **B1–B10** (mục cơ bản) và **E1–E10** (mục mở rộng 5 điểm). Có script `scripts/verify_local.py` chạy từng mục để ghi bằng chứng thực tế.
- **Không có sẵn `.env`** để tránh phát tán mật khẩu. Tạo riêng trên mỗi máy. Không lấy kết quả 20/20 từ log cũ làm kết luận cho bản mới nếu chưa chạy lại.

**Trạng thái xác minh bản ZIP này:** đã rà soát mã nguồn, cấu trúc Compose/YAML, lệnh Python, file HTML và các đường dẫn. **Chưa chạy Docker Engine trong môi trường đóng gói**, vì vậy cần chạy theo Mục 3 và Mục 4 trên máy có Docker để xác nhận.

## 2. Phần mềm và điều kiện chạy

1. **Windows 10/11**: Docker Desktop (Linux containers, WSL2 backend được bật), PowerShell 5.1+; cần Internet lần đầu để tải Docker images. Docker Compose v2 đi kèm Docker Desktop. Linux/EC2: Docker Engine + Docker Compose plugin v2, Python 3.
2. Khuyến nghị **ít nhất 8 GB RAM**, nên có trên 6 GB dung lượng trống để tải image/volume; máy RAM 8 GB nên tắt Android Studio/emulator trước khi chạy. Keycloak, Grafana và MariaDB cần thời gian khởi động.
3. Cổng host `80`, `8080`, `8085`, `8081`, `9000`, `9001`, `1053`, `9090`, `3000` chưa bị ứng dụng khác chiếm. Nếu máy có container cũ tên trùng, dừng chúng trước (không xóa bừa dữ liệu).
4. Một project dùng **một** `docker-compose.yml` tại thư mục gốc. **Không khởi động thêm** `docker-compose.tv2.yml` cũ: file này chỉ được lưu ở `docs/tham-khao-thanh-vien/` để tham khảo.

## 3. Cách chạy trên 3 máy Windows – khuyến nghị

Cả **3 thành viên tải CÙNG một bản ZIP**, giải nén ở mỗi máy (không cần chia thành ba folder code) và làm như sau:

1. Mở Docker Desktop, chờ Docker Engine chạy (chế độ Linux containers).
2. Nhấp đúp **`START_WINDOWS.cmd`** trong thư mục dự án. File sẽ:
   - Tạo `.env` với mật khẩu mạnh và riêng trên máy (nếu chưa tồn tại).
   - Kiểm tra Docker Compose, build và khởi động **11 container**.
   - Chờ Keycloak sẵn sàng, tạo `Realm`, `flask-app`, `sv01`, `sv02`, bucket MinIO và các file mẫu.
   - In ra địa chỉ truy cập.
3. Nếu có lỗi, giữ màn hình CMD và đọc nội dung (không xóa volume). Kiểm tra `docker compose ps` và `docker compose logs <service> --tail 100`.
4. Nhấp đúp **`VERIFY_WINDOWS.cmd`** để kiểm thử 20 mục (cần Python 3), hoặc chạy tại PowerShell trong thư mục gốc:

```powershell
py -3 scripts\verify_local.py
# Nếu Windows không có "py" nhưng có python:
# python scripts\verify_local.py
```

Log mới sẽ ở `docs/evidence/moi/kiem-thu-YYYYMMDD-HHMMSS.txt`. **Chỉ ghi báo cáo những mục PASS sau khi máy thực tế chạy.** Có thể chụp màn hình PowerShell và trang web theo checklist trong `docs/BANG_DOI_CHIEU_DE_BAI.md`.

### Cách chạy từng lệnh (PowerShell)

```powershell
# Chỉ làm một lần nếu không dùng START_WINDOWS.cmd:
py -3 scripts/setup_local.py

# Đọc file .env (KHÔNG chia sẻ; KHÔNG đẩy lên GitHub):
notepad .env

docker compose --env-file .env config --quiet
docker compose --env-file .env up -d --build
docker compose --env-file .env ps

# Khởi tạo Keycloak, MinIO (chạy lại được nếu dịch vụ đã sẵn sàng):
.\scripts\provision-demo.ps1 -EnvFile .env
# Hoặc dùng Python3 đa nền tảng:
# py -3 scripts/provision_demo.py

py -3 scripts\verify_local.py
```

**Quan trọng:** Nếu dùng PowerShell thủ công, có thể tạm cho phép thực thi trong **chỉ phiên hiện tại** bằng `Set-ExecutionPolicy -Scope Process Bypass`. File `START_WINDOWS.cmd` đã tự gọi PowerShell cho lần khởi động của nó.

### Ubuntu / Linux / AWS EC2

```bash
cd MyMiniCloud_3ThanhVien_Final
chmod +x START_LINUX.sh
./START_LINUX.sh
python3 scripts/verify_local.py
```

Trong lần đầu, `scripts/setup_local.py` tạo `.env`; `scripts/provision_demo.py` chuẩn bị Keycloak/MinIO. Khi chỉ muốn chạy containers mà không chuẩn bị dữ liệu demo: `docker compose --env-file .env up -d --build`.

## 4. Truy cập và API sau khi chạy

| Thành phần | Địa chỉ trên máy của người chạy | Bằng chứng |
|---|---|---|
| Web Frontend 1 | http://localhost:8080/ và `/blog/` | B1, E1 |
| API Flask | http://localhost:8085/hello | B2 |
| API danh sách JSON | http://localhost:8085/student | E2 |
| API kết nối MariaDB | http://localhost:8085/students-db | E3 |
| Keycloak | http://localhost:8081 | B4, E4 |
| MinIO Console | http://localhost:9001 | B5, E5 |
| Bind9 DNS | `dig @127.0.0.1 -p 1053 web-frontend-server.cloud.local` | B6, E6 |
| Prometheus | http://localhost:9090/targets | B7, E7 |
| Grafana | http://localhost:3000 | B8, E8 |
| **Gateway** | **http://localhost/** | B9 |
| Gateway API | http://localhost/api/hello | B2, B9 |
| Gateway student | http://localhost/student/ | E9 |
| Gateway blog | http://localhost/blog/ | B1, E1 |
| Round Robin | Tải lại http://localhost/ nhiều lần: `Server 1` ↔ `Server 2` | E10 |

Trên Windows Docker Desktop, số liệu Node Exporter thường phản ánh **máy ảo Linux chạy Docker**, không nhất thiết là toàn bộ CPU/RAM của Windows host.

Các cổng quản trị và API dùng `127.0.0.1` ở phía host để giảm rủi ro truy cập ngoài máy; **chỉ Gateway cổng 80** nghe trên tất cả interface, thuận tiện demo qua Public IP EC2. Trong Docker, các service vẫn liên lạc qua `cloud-net`.

**Tài khoản quản trị:** mở file `.env` **cục bộ** để xem `KEYCLOAK_ADMIN`, `KEYCLOAK_ADMIN_PASSWORD`, `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`, `GF_SECURITY_ADMIN_USER`, `GF_SECURITY_ADMIN_PASSWORD`. Tuyệt đối không gửi cả file `.env` cho các thành viên khác hoặc chụp lộ mật khẩu/token.

**Cấu hình DB:** `01-init.sql` của nhóm cấp quyền truy vấn cho tên user `minicloud_user`. Giữ nguyên `MARIADB_USER=minicloud_user` (được mặc định trong `.env.example`); mỗi máy thay **mật khẩu**, không tự đổi tên user nếu chưa sửa lại SQL.

**OIDC demo:** chạy `scripts/provision-demo.ps1` hoặc `scripts/provision_demo.py` để tạo Realm `realm_52400001` (mặc định), client công khai `flask-app` và users `sv01`, `sv02`. API `/secure` kiểm tra chữ ký JWT, `iss`, `aud`. Nếu đổi mã Realm trong `.env`, **phải đổi đồng bộ** `KEYCLOAK_REALM`, `OIDC_ISSUER`, `OIDC_JWKS_URL`. `scripts/setup_local.py --mssv 52400001` sẽ tạo đúng các giá trị từ đầu.

## 5. Cấu trúc chung

```text
MyMiniCloud_3ThanhVien_Final/
├── docker-compose.yml                         # KHAI BÁO DUY NHẤT cho toàn hệ thống
├── .env.example                               # Mẫu, không có mật khẩu thật
├── .env                                       # Sinh tại từng máy, KHÔNG nằm trong ZIP
├── START_WINDOWS.cmd / START_WINDOWS.ps1      # Khởi động trên Windows
├── STOP_WINDOWS.cmd / VERIFY_WINDOWS.cmd      # Dừng / kiểm thử 20 mục
├── START_LINUX.sh                             # Linux / EC2
├── web-frontend-server/                       # TV1: web1, web2, blog, assets
├── application-backend-server/                # TV1: Flask /hello /student /students-db /secure
├── relational-database-server/                # TV1: SQL init + GRANT cho minicloud_user
├── authentication-identity-server/            # TV2: Keycloak (image + provision)
├── object-storage-server/                     # TV2: MinIO (image + provision)
├── internal-dns-server/                       # TV2: Bind9 zone cloud.local
├── monitoring-prometheus-server/              # TV3: Prometheus scrape
├── monitoring-grafana-dashboard-server/       # TV3: dashboards + provisioning
├── api-gateway-proxy-server/                  # TV3: Nginx Gateway / Round Robin
├── scripts/
│   ├── setup_local.py                         # Tạo .env
│   ├── provision_demo.py                      # Python: demo Keycloak/MinIO
│   ├── provision-demo.ps1                     # PowerShell: demo Keycloak/MinIO
│   ├── verify_local.py                        # Test 20 mục + log (đa nền tảng)
│   └── smoke-test.sh                          # Bộ kiểm thử gốc từ nhánh Nguyen
├── test-upload/                               # Mẫu avatar, HTML, PDF
└── docs/
    ├── BANG_DOI_CHIEU_DE_BAI.md
    ├── SO_DO_KIEN_TRUC.md
    ├── HUONG_DAN_BAO_CAO.md
    ├── HUONG_DAN_EC2.md
    ├── evidence/local/                        # Minh chứng gốc TV3 (LỊCH SỬ)
    ├── evidence/tu-TV2/                       # Minh chứng gốc TV2 (LỊCH SỬ)
    └── evidence/moi/                          # KẾT QUẢ mới thực tế, mỗi máy tự tạo
```

## 6. Đối chiếu mục tiêu đề bài và kết quả cần thu

Xem **[docs/BANG_DOI_CHIEU_DE_BAI.md](docs/BANG_DOI_CHIEU_DE_BAI.md)**: 10 mục cơ bản B1–B10 và 10 mục mở rộng E1–E10, đường dẫn cấu hình, cách test và ảnh đề xuất. `docs/SO_DO_KIEN_TRUC.md` chứa sơ đồ luồng Request → Gateway → Web/App → DB/Keycloak và giám sát qua Prometheus/Grafana. Phần ghi log tập trung Loki **chưa có**: không mô tả Grafana như một hệ thống lưu log đầy đủ.

## 7. Phân công cho 3 thành viên

| Phần | Chủ trì | Mã nguồn | Nội dung thuyết trình/báo cáo |
|---|---|---|---|
| Web, App, Database | TV1 (Quang) | `web-frontend-server`, `application-backend-server`, `relational-database-server` | B1–B3, E1–E3; API và SQL |
| Authentication, Storage, DNS | TV2 (Tuấn Anh) | `authentication-identity-server`, `object-storage-server`, `internal-dns-server` | B4–B6, E4–E6; token, bucket, DNS |
| Monitoring, Grafana, Gateway & tích hợp | TV3 (Nguyen, dashboard MSSV 52400141) | `monitoring-*`, `api-gateway-*`, `docker-compose.yml` | B7–B10, E7–E10, sơ đồ, EC2 |

Các thành viên dùng cùng một code, nhưng `docker compose up` được chạy độc lập trên **máy riêng** nên mỗi người có container và volume riêng.

## 8. Vận hành / lưu dữ liệu / reset

```powershell
# Xem trạng thái và lỗi
docker compose --env-file .env ps
docker compose --env-file .env logs --tail 100
# Chỉ xem log một server:
docker compose --env-file .env logs application-backend-server --tail 100
# Dừng và giữ dữ liệu
docker compose --env-file .env down
# Chạy lại
docker compose --env-file .env up -d
```

**KHÔNG dùng `docker compose down -v` nếu còn cần dữ liệu**: cờ `-v` xóa volume MariaDB, Keycloak, MinIO, Prometheus, Grafana. Nếu đổi mật khẩu trong `.env` sau khi volume đã có dữ liệu, thông tin khởi tạo cũ trong DB/Keycloak/MinIO không tự cập nhật; cần phục hồi mật khẩu cũ hoặc tái khởi tạo sạch (mất dữ liệu).

### Sự cố phổ biến

- `error during connect`: Docker Desktop chưa mở, chưa bật Linux containers/WSL2.
- `port is already allocated`: cổng `80`, `8080`, `8081`... đang bị chiếm; dùng `netstat -ano | findstr :80` hoặc `Get-NetTCPConnection -LocalPort 80` để tra cứu trước khi thay port.
- `container name already in use`: còn container MyMiniCloud cũ. Kiểm tra `docker ps -a`, dừng đúng container của dự án cũ, không xóa container không liên quan.
- `network cloud-net overlaps`: subnet `10.10.10.0/24` xung đột với mạng khác; sửa đồng bộ Compose, zone file DNS và bài kiểm tra nếu đổi IP.
- Backend `/students-db` HTTP 503: DB init có thể chưa hoàn tất, user không có SELECT, hoặc volume cũ có schema khác; xem `docker compose logs relational-database-server`.
- Keycloak token lỗi: chưa chạy provision, Realm/JWKS/Issuer không khớp, hoặc `.env` mới đi với volume Keycloak cũ.
- Prometheus chưa có CPU *rate*: đợi có ít nhất hai lần scrape và kiểm tra Targets `UP`; sau đó chạy test lại.
- MinIO `mc not found`: kiểm tra image được tải đúng `bitnamilegacy/minio:2024.6.13`; bộ provision hiện dựa trên CLI `mc` trong image nguồn mà nhóm đã dùng.
- Máy RAM 8 GB: dừng Android Studio, AVD, Chrome tabs nặng; cấp đủ RAM cho Docker. Không chạy hai stack trên **cùng máy** với tên container/cổng trùng nhau.
- Nếu `START_WINDOWS.cmd` bị Windows chặn: mở PowerShell tại folder dự án rồi chạy `powershell -NoProfile -ExecutionPolicy Bypass -File .\START_WINDOWS.ps1`.

## 9. AWS EC2, Docker Hub và báo cáo

Đề yêu cầu chạy trên AWS EC2 bằng Public IP và push **ít nhất 1 image tùy chỉnh lên Docker Hub**. Xem `docs/HUONG_DAN_EC2.md`. Phần ZIP này **chưa chứng minh đã deploy trên EC2 hoặc push Docker Hub**; đó là bước vận hành cần làm và lưu minh chứng.

Để viết báo cáo theo 5 chương/Phụ lục, dùng `docs/HUONG_DAN_BAO_CAO.md`. Ảnh cũ trong `docs/evidence/local` và `docs/evidence/tu-TV2` là dữ liệu tham khảo từ lần chạy trước, không thay thế ảnh chụp của bản cuối khi chưa kiểm tra lại.

---
**Nguyên tắc bàn giao:** một ZIP → giải nén trên ba máy → ba `.env` riêng → chạy Compose chung → chuẩn bị demo → chạy đủ 20 test → lưu ảnh/log mới → viết báo cáo đúng phần đã được kiểm chứng.

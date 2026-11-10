# ĐỐI CHIẾU 20 MỤC ĐỀ BÀI VỚI MÃ NGUỒN BẢN TÍCH HỢP

**Nguồn:** đề *Xây dựng mô phỏng hệ thống MiniCloud cơ bản* (27 trang), phần kiểm tra cơ bản trang 2, 11–20, phần mở rộng trang 21–27.

**Kết luận mã nguồn:** Các file cần thiết cho 20 hạng mục được chuẩn bị trong dự án; **đạt yêu cầu thực tế hay chưa chỉ quyết định sau khi chạy** `python scripts/verify_local.py` và đối chiếu ảnh mới. Không lấy log `20/20` của bản `Nguyen` cũ làm kết quả kiểm thử bản cuối.

| Mã | Yêu cầu trong đề | File cấu hình / vị trí | Test/ảnh cần chụp |
|---|---|---|---|
| B1 | Web Home và `/blog/` chạy 200 | `web-frontend-server/html/`, `conf.default` | `http://localhost:8080/`, `/blog/`; kiểm tra thêm Gateway `/blog/` |
| B2 | Flask `/hello` trực tiếp & Gateway trả JSON | `application-backend-server/app.py`, `api-gateway-proxy-server/nginx.conf` | `http://localhost:8085/hello`, `http://localhost/api/hello` |
| B3 | MariaDB có schema và dữ liệu `notes` | `relational-database-server/init/01-init.sql` | `docker exec ... mariadb -e 'SHOW DATABASES'`, `SELECT` |
| B4 | Keycloak quản lý user và login | `authentication-identity-server/`, `scripts/provision*` | Console, Realm, user `sv01` |
| B5 | MinIO bucket/upload file | `test-upload/`, `scripts/provision*` | Bucket `demo/index.html` trong Console |
| B6 | DNS có bản ghi Web | `internal-dns-server/zones/db.cloud.local` | `dig @127.0.0.1 -p 1053 web-frontend-server.cloud.local` |
| B7 | Prometheus Node Exporter UP | `monitoring-prometheus-server/prometheus.yml` | Targets + truy vấn `node_cpu_seconds_total` |
| B8 | Grafana có dashboard và dữ liệu metrics | `monitoring-grafana-dashboard-server/` | `Node Exporter Full`, CPU/RAM/Network |
| B9 | Gateway route Web/API/Auth | `api-gateway-proxy-server/nginx.conf` | `/` 200, `/api/hello` JSON, `/auth/` 302 |
| B10 | 11 container kết nối mạng | `docker-compose.yml` | `docker compose ps`, `docker network inspect cloud-net`, ping |
| E1 | Ít nhất 3 blog, ảnh, link trang chủ | `web-frontend-server/html/blog/blog{1,2,3}.html` | 3 trang và ảnh minh họa |
| E2 | API `/student` trả 5 SV file JSON | `app.py`, `students.json` | `http://localhost/api/student` |
| E3 | `studentdb.students` và ít nhất 3 bản ghi | `01-init.sql`, `app.py` | `http://localhost/api/students-db` trả 5 bản ghi |
| E4 | Realm theo MSSV, 2 user, client, token `/secure` | `scripts/provision*`, `app.py` | Token hợp lệ, API `/secure` 200 |
| E5 | Bucket `profile-pics`, `documents` | `scripts/provision*`, `test-upload/` | avatar public HTTP 200; PDF trong bucket private |
| E6 | DNS thêm `app-backend`, `minio`, `keycloak` | `db.cloud.local` | 3 lệnh `dig`, IP chính xác |
| E7 | Prometheus Web target UP | `prometheus.yml`, `html/metrics` | Targets `job=web`, trạng thái UP |
| E8 | Dashboard cá nhân 3 biểu đồ | `dashboards/system-health-52400141.json` | CPU Usage, Memory Usage, Network Traffic |
| E9 | Gateway `/student/` định tuyến Flask | `nginx.conf` | `http://localhost/student/` trả 5 SV |
| E10 | 2 Web instance, Nginx Round Robin | `Dockerfile.web2`, `html2/index.html`, `nginx.conf` | 6 lần reload thấy Server 1 → Server 2 luân phiên |

## Kiểm tra thực tế

```powershell
# Từ folder gốc, sau khi chạy START_WINDOWS.cmd
py -3 scripts\verify_local.py
```

Log sinh tại `docs/evidence/moi/`. Nếu một test FAIL: ghi nguyên nhân và cách sửa, chạy lại, **không sửa kết quả vào log thủ công**.

## Bổ sung để hoàn thiện ngoài mã nguồn

1. Đưa ảnh chụp và log **của bản cuối** vào phụ lục.
2. Push `myminicloud-web` hoặc `myminicloud-backend` lên Docker Hub và ghi link/tag.
3. Deploy trên AWS EC2 Ubuntu; xác nhận được trang Gateway qua Public IP; ghi rõ Security Group và các cổng quản trị chỉ truy cập nội bộ/SSH tunnel.
4. Báo cáo đủ 5 chương: mục tiêu, sơ đồ, cấu hình, demo/test, đánh giá và phụ lục.
5. Đề ghi server số 8 là `Logging/Visualization`; ba phần source nhóm gửi chỉ triển khai **Grafana kết nối Prometheus metrics**, chưa có hệ thống tập trung thu gom log (Loki/Promtail). Trong báo cáo nêu rõ giới hạn này để tránh mô tả quá khả năng thực tế.

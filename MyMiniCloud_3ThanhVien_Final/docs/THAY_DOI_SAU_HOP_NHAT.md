# CHANGELOG – HỢP NHẤT BA ZIP

## Nguồn và nguyên tắc

- Nền chính: **`nguyen(1).zip`** – có Docker Compose 11 container, Gateway, Monitoring, Grafana, mã Web/Flask/DB đã nhận từ TV1 và cấu hình TV2.
- Bổ sung từ **`tuananh.zip`**: báo cáo Chương 1/3/5, tài liệu phân công, hình minh chứng gốc Keycloak, MinIO, DNS và ping.
- Rà soát từ **`quang.zip`**: source Web/Blog/Flask/MariaDB so với bản đã tích hợp. Giữ các sửa đổi mới từ bản `Nguyen` (JWT, DB, Web metrics...). **Không ghi đè bằng phiên bản cũ**.
- Không đưa file `.env` riêng TV1 vào ZIP (chứa thông tin nội bộ). Không kèm `.git` để giảm kích thước và tránh lịch sử bí mật.

## Các thay đổi trong gói hợp nhất

1. Giữ Compose 11 service, cố định IP và network; chuyển các cổng quản trị/API sang bind `127.0.0.1` trên host, riêng Gateway `80:80` vẫn public để demo EC2.
2. Sửa `Dockerfile.web2`: Web 2 có **đủ blog, CSS, ảnh và `/metrics`**, không còn 404 ngẫu nhiên khi Gateway Round Robin vào `/blog/`. Trang chủ Web 2 giữ marker `Server 2` để test E10.
3. Giữ nguyên SQL khởi tạo đã có kết quả kiểm thử của nhánh Nguyen, bao gồm `notes`, `studentdb.students` và GRANT cho account `minicloud_user`. Các máy nên giữ nguyên `MARIADB_USER=minicloud_user` và chỉ đổi mật khẩu qua `.env` để tránh sai quyền.
4. Thêm `START_WINDOWS.cmd`, `START_WINDOWS.ps1`, `STOP_WINDOWS.cmd`, `START_LINUX.sh`, `scripts/setup_local.py` tạo `.env` riêng cho từng máy.
5. Thêm `scripts/provision_demo.py` chuẩn bị Keycloak/MinIO bằng Python stdlib cho cả Linux/Windows; giữ PowerShell script gốc và bổ sung lệnh cấu hình alias MinIO tường minh.
6. Thêm `scripts/verify_local.py` kiểm thử tự động **20 mục** B1–B10, E1–E10 trên môi trường thực tế, có log ở `docs/evidence/moi`.
7. Thêm README tiếng Việt, sơ đồ/ma trận đề bài/hướng dẫn báo cáo/EC2, giữ riêng ảnh **lịch sử** từ TV2 và TV3 để tránh nhầm thành ảnh của bản mới.
8. Chuyển Compose riêng TV2 sang `docs/tham-khao-thanh-vien` – **không dùng để chạy**; chỉ còn `docker-compose.yml` chính.

## Chưa được chứng nhận

- Không chạy được Docker Engine trực tiếp trong môi trường đóng gói ZIP; cần chạy trên máy nhóm và nộp **log test của bản mới**.
- Chưa có kết quả xác minh EC2/Public IP và Docker Hub image push. Các hạng mục này vẫn là bước phải thực hiện.
- Grafana trong gói gốc hiển thị metrics, **không có Loki/Promtail** để lưu log tập trung. Nếu giảng viên yêu cầu logging đúng nghĩa, đây là hướng cần bổ sung và kiểm tra riêng.

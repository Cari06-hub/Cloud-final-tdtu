# KẾT QUẢ KIỂM TRA TĨNH BẢN HỢP NHẤT

Các kiểm tra này được thực hiện khi đóng gói dự án, **không phải chạy trực tiếp 11 container**.

- **106 kiểm tra cấu trúc:** đạt, gồm YAML Compose đúng 11 services, IP tĩnh không trùng, đầy đủ mount path và Dockerfile; đường dẫn HTML/asset hợp lệ; Web 2 có blog/CSS/ảnh; API route Gateway; biến cấu hình môi trường; Grafana Dashboard có đủ ba panel; cơ sở dữ liệu có cả `minicloud` và `studentdb` cùng GRANT của user mặc định.
- **Nginx:** cú pháp Gateway và Web được kiểm tra thành công bằng `nginx -t` trên môi trường đóng gói; hostnames của upstream được thay thế tạm thành `127.0.0.1` chỉ để parser không cần DNS runtime. Cấu hình source **không bị thay hostnames**.
- **Python:** parse/compile script chạy; `scripts/setup_local.py` được thử trên thư mục tạm, tạo `.env` không chứa giá trị placeholder, tôn trọng mã Realm, không ghi đè file `.env` có sẵn.
- **Bash:** `bash -n` chạy cho các `.sh` không báo lỗi cú pháp.
- **Không có Docker Engine** tại nơi đóng gói: không tự chạy `docker compose up`, không xác minh Keycloak/MinIO, không kiểm thử 20 endpoint. Không thể khẳng định 20/20 PASS cho bản mới tại bước này.

## Cách chuyển thành kết quả thực tế

1. Trên từng máy, chạy `START_WINDOWS.cmd` hoặc `./START_LINUX.sh`.
2. Chạy `VERIFY_WINDOWS.cmd` hoặc `python3 scripts/verify_local.py`.
3. Lưu log thực tế tại `docs/evidence/moi/`; chụp ảnh từng server và báo cáo chỉ những mục thực sự PASS.

Kết quả lịch sử từ `nguyen(1).zip` và `tuananh.zip` được giữ riêng trong thư mục `docs/evidence/local` và `docs/evidence/tu-TV2` và **không được tính là xác minh mới**.

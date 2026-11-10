# KẾ HOẠCH TRIỂN KHAI TRÊN AWS EC2 (YÊU CẦU ĐỀ)

**Tình trạng:** Đây là HƯỚNG DẪN/CHỈ DẪN, không phải chứng nhận đã chạy EC2.

## Chuẩn bị

- Tạo EC2 Ubuntu có đủ RAM và disk để chạy 11 container; kích thước phù hợp phụ thuộc tải thực tế (Keycloak + Grafana + MariaDB khá nặng). Không giả định instance nhỏ nhất sẽ chạy ổn.
- Cài Docker Engine và Docker Compose plugin v2 bằng hướng dẫn chính thức cho phiên bản Ubuntu đang dùng. Bật service Docker, đảm bảo lệnh `docker compose version` thành công.
- Security Group: chỉ mở **22/tcp** từ IP quản trị của nhóm, **80/tcp** (HTTP Gateway) từ nguồn được giảng viên kiểm thử. KHÔNG mở công khai 8081 Keycloak, 9000/9001 MinIO, 9090 Prometheus, 3000 Grafana hoặc 3306 MariaDB. Để làm dashboard từ máy cá nhân, dùng SSH tunnel.
- Đưa bản ZIP hoặc clone repository đã thống nhất lên EC2. Giữ `.env` và các khóa/mật khẩu ngoài GitHub.

## Chạy trên Ubuntu

```bash
cd ~/MyMiniCloud_3ThanhVien_Final
chmod +x START_LINUX.sh
./START_LINUX.sh
# Mỗi máy tự sinh .env và khởi tạo dữ liệu Keycloak/MinIO
python3 scripts/verify_local.py
```

Nếu Ubuntu cần cấp quyền Docker, người được cấp quyền có thể dùng `sudo` có kiểm soát hoặc thêm vào docker group (nhóm docker tương đương quyền root). Đảm bảo user chạy script có quyền truy cập Docker Engine.

## Kiểm tra qua Public IP

- Đăng nhập SSH vào EC2, chạy `docker compose ps` và `python3 scripts/verify_local.py` ngay trên instance.
- Từ máy nhóm/giảng viên, mở `http://<EC2_PUBLIC_IP>/` và `http://<EC2_PUBLIC_IP>/api/hello`.
- Kiểm tra Web Round Robin, chức năng `/student/` tại `http://<EC2_PUBLIC_IP>/student/`.
- Với Keycloak, MinIO, Prometheus, Grafana: dùng SSH local port forwarding hoặc kiểm tra trực tiếp qua terminal/console nội bộ EC2; tránh mở cổng quản trị công khai.
- Lưu ảnh Security Group đã che thông tin nhạy cảm, `docker compose ps`, truy cập web qua Public IP và log 20/20 nếu đúng.

## Lưu ý rất quan trọng với token trên EC2

Tệp mẫu `.env.example` sử dụng `OIDC_ISSUER=http://localhost:8081/realms/realm_...`. Vì script `provision_demo.py` được chạy **trên chính EC2**, token lấy qua localhost nên vẫn xác minh được khi test cục bộ. **Máy khách từ Internet không thể dùng `localhost:8081` trên EC2**; nếu cần người dùng ở xa đăng nhập vào Keycloak, phải bố trí tên miền công khai HTTPS và đồng bộ issuer/hostname/nginx route. Demo đề bài chỉ cần web qua Public IP và chức năng Keycloak từ local/SSH tunnel.

## Push image lên Docker Hub

```bash
# Thay <dockerhub-user> bằng tài khoản của nhóm
# Đảm bảo đăng nhập bằng cách an toàn qua docker login
docker build -t <dockerhub-user>/myminicloud-web:final ./web-frontend-server
docker login
docker push <dockerhub-user>/myminicloud-web:final
```

Chỉ ghi link image trong báo cáo khi lệnh push đã thành công, link đã kiểm tra được. Tránh đẩy `.env`, mật khẩu, khóa hoặc file chứa secrets vào image hay repository.

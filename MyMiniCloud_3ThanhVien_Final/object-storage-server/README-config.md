# MinIO - Object Storage Server

## Cấu hình tích hợp

| Mục | Giá trị |
|---|---|
| Image | `bitnamilegacy/minio:2024.6.13` |
| Container | `object-storage-server` |
| API | `9000:9000` |
| Console | `9001:9001` |
| Network/IP | `cloud-net` / `10.10.10.30` |
| Persistence | `minio_data:/bitnami/minio/data` |

Image được chọn vì tag đã được kiểm tra tồn tại trong registry tại thời điểm
tích hợp. Đây là image archive được ghim phiên bản; không thay bằng `latest`.
Bitnami entrypoint tự khởi động MinIO, vì vậy Compose độc lập không ghi đè
`command`.

## Biến môi trường

```dotenv
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=REPLACE_WITH_STRONG_MINIO_PASSWORD
```

Giá trị thật chỉ nằm trong `.env` local hoặc `.env` riêng trên EC2.

## Khởi động độc lập phần TV2

```bash
cp .env.example .env
# Điền giá trị thật vào .env
docker compose --env-file .env -f docker-compose.tv2.yml config --quiet
docker compose --env-file .env -f docker-compose.tv2.yml up -d object-storage-server
docker compose --env-file .env -f docker-compose.tv2.yml ps
```

Truy cập Console tại `http://localhost:9001`.

## B5 - Bucket cơ bản

1. Tạo bucket `demo`.
2. Upload `test-upload/index.html`.
3. Xác nhận object hiển thị trong bucket.

## E5 - Bucket mở rộng

1. Tạo bucket `profile-pics`.
2. Upload `test-upload/avatar.jpg`.
3. Đặt policy chỉ đủ để public read object cần demo.
4. Mở URL object bằng trình duyệt ẩn danh.
5. Tạo bucket `documents`.
6. Upload `test-upload/document.pdf`.

Không public toàn bộ Console hoặc root credential. Không chụp access key hay
secret key vào báo cáo.

## Kiểm tra health và persistence

```bash
curl -f http://localhost:9000/minio/health/live
docker compose --env-file .env -f docker-compose.tv2.yml restart object-storage-server
curl -f http://localhost:9000/minio/health/live
```

Sau restart, các bucket và object phải còn nguyên.

Không dùng `docker compose down -v` nếu muốn giữ dữ liệu. Xóa volume
`minio_data` đồng nghĩa xóa bucket và object của bài demo.

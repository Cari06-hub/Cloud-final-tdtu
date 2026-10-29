# 📦 MinIO – Object Storage Server

## Hướng dẫn cấu hình chi tiết (Tuấn Anh – TV2)

---

## Mục lục

1. [Tổng quan](#1-tổng-quan)
2. [Yêu cầu hệ thống](#2-yêu-cầu-hệ-thống)
3. [Khởi chạy MinIO](#3-khởi-chạy-minio)
4. [Truy cập MinIO Console](#4-truy-cập-minio-console)
5. [Tạo Bucket](#5-tạo-bucket)
6. [Upload file](#6-upload-file)
7. [Cấu hình Access Policy](#7-cấu-hình-access-policy)
8. [Sử dụng MinIO Client (mc)](#8-sử-dụng-minio-client-mc)
9. [Tích hợp với ứng dụng](#9-tích-hợp-với-ứng-dụng)
10. [Kiểm thử Object Storage](#10-kiểm-thử-object-storage)
11. [Xử lý sự cố](#11-xử-lý-sự-cố)

---

## 1. Tổng quan

**MinIO** là hệ thống Object Storage hiệu suất cao, tương thích Amazon S3 API, mã nguồn mở. MinIO cung cấp:
- S3-compatible API
- Web Console quản lý trực quan
- Bucket versioning, lifecycle management
- Server-side encryption
- Access policy (IAM)

**Trong dự án MyMiniCloud**, MinIO đóng vai trò:
- Lưu trữ file tĩnh (HTML, CSS, JS, hình ảnh) cho web frontend
- Lưu trữ tài liệu người dùng upload
- Cung cấp presigned URL cho ứng dụng backend

| Thông số          | Giá trị                                         |
|-------------------|--------------------------------------------------|
| Image             | `minio/minio:RELEASE.2024-06-13T22-53-53Z`      |
| Container name    | `object-storage-server`                          |
| API Port          | `9000:9000`                                      |
| Console Port      | `9001:9001`                                      |
| Root user         | `minioadmin`                                     |
| Root password     | `change_me_minio_password`                       |
| Network           | `cloud-net`                                      |

---

## 2. Yêu cầu hệ thống

- Docker Engine ≥ 20.10
- Docker Compose ≥ 2.0
- RAM khả dụng ≥ 256 MB
- Dung lượng đĩa: tuỳ vào lượng file upload (tối thiểu 1 GB)
- Network `cloud-net` đã được tạo

---

## 3. Khởi chạy MinIO

### Cách 1: Chạy cùng bộ TV2

```bash
docker compose -f docker-compose.tv2.yml up -d object-storage-server
```

### Cách 2: Chạy riêng lẻ bằng docker run

```bash
docker run -d \
  --name object-storage-server \
  --network cloud-net \
  -p 9000:9000 \
  -p 9001:9001 \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=change_me_minio_password \
  minio/minio:RELEASE.2024-06-13T22-53-53Z \
  server /data --console-address ":9001"
```

### Kiểm tra container đã chạy

```bash
docker ps --filter "name=object-storage-server"
docker logs -f object-storage-server
```

> ⏳ MinIO khởi động rất nhanh (vài giây). Khi thấy:
> `MinIO Object Storage Server ... API: http://...`
> nghĩa là đã sẵn sàng.

---

## 4. Truy cập MinIO Console

1. Mở trình duyệt, truy cập: **http://localhost:9001**
2. Đăng nhập với:
   - Username: `minioadmin`
   - Password: `change_me_minio_password`

> 📸 **Chụp màn hình** trang MinIO Console → lưu vào `docs/evidence/`

---

## 5. Tạo Bucket

Bucket là đơn vị lưu trữ cấp cao nhất trong MinIO (tương đương folder gốc).

### Qua Console:

1. Menu trái → **Buckets** → **Create Bucket**
2. Nhập thông tin:
   - **Bucket Name**: `mycloud-files`
   - Versioning: `OFF` (hoặc `ON` nếu muốn giữ phiên bản)
   - Object Locking: `OFF`
3. Click **Create Bucket**

### Tạo thêm các bucket:

| Bucket Name      | Mục đích                           |
|------------------|-------------------------------------|
| `mycloud-files`  | File tĩnh cho web frontend         |
| `user-uploads`   | File do người dùng upload           |
| `backups`        | Backup dữ liệu                     |

> 📸 **Chụp màn hình** danh sách buckets đã tạo

---

## 6. Upload file

### 6.1. Upload qua Console

1. Click vào bucket `mycloud-files`
2. Click **Upload** → **Upload File**
3. Chọn các file từ thư mục `test-upload/`:
   - `index.html`
   - `avatar.jpg`
   - `document.pdf`
4. Click **Upload**

### 6.2. Upload qua curl (S3 API)

```bash
# Upload file sử dụng presigned URL hoặc S3 API
curl -X PUT \
  -H "Content-Type: text/html" \
  --data-binary @test-upload/index.html \
  http://minioadmin:change_me_minio_password@localhost:9000/mycloud-files/index.html
```

> 📸 **Chụp màn hình** file đã upload thành công trong bucket

---

## 7. Cấu hình Access Policy

### 7.1. Đặt Bucket Policy (Public Read)

Để cho phép truy cập file tĩnh từ web:

1. Vào **Buckets** → `mycloud-files` → **Summary**
2. **Access Policy**: chọn `Public` (hoặc `Custom`)
3. Hoặc dùng custom policy JSON:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"AWS": ["*"]},
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::mycloud-files/*"]
    }
  ]
}
```

### 7.2. Tạo Access Key

1. Menu trái → **Access Keys** → **Create access key**
2. Ghi lại:
   - **Access Key**: (sẽ được tự sinh)
   - **Secret Key**: (sẽ được tự sinh)
3. Click **Create**

> ⚠️ **Lưu ý**: Secret Key chỉ hiển thị một lần. Lưu lại cẩn thận!

> 📸 **Chụp màn hình** Access Keys đã tạo

---

## 8. Sử dụng MinIO Client (mc)

### 8.1. Cài đặt mc

```bash
# Chạy mc từ Docker
docker run --rm --network cloud-net \
  --entrypoint /bin/sh \
  minio/mc -c "
    mc alias set myminio http://object-storage-server:9000 minioadmin change_me_minio_password
    mc ls myminio/
  "
```

### 8.2. Các lệnh mc thường dùng

```bash
# Tạo alias
mc alias set myminio http://localhost:9000 minioadmin change_me_minio_password

# Liệt kê buckets
mc ls myminio/

# Liệt kê file trong bucket
mc ls myminio/mycloud-files/

# Upload file
mc cp test-upload/index.html myminio/mycloud-files/
mc cp test-upload/avatar.jpg myminio/mycloud-files/
mc cp test-upload/document.pdf myminio/user-uploads/

# Download file
mc cp myminio/mycloud-files/index.html ./downloaded.html

# Xem thông tin bucket
mc stat myminio/mycloud-files

# Xoá file
mc rm myminio/mycloud-files/old-file.txt

# Đồng bộ thư mục
mc mirror ./test-upload/ myminio/mycloud-files/
```

---

## 9. Tích hợp với ứng dụng

### 9.1. Truy cập file qua HTTP

Sau khi đặt bucket policy Public, file có thể truy cập trực tiếp:

```
http://localhost:9000/mycloud-files/index.html
http://localhost:9000/mycloud-files/avatar.jpg
```

### 9.2. Tích hợp qua S3 SDK (Node.js)

```javascript
const Minio = require('minio');

const minioClient = new Minio.Client({
    endPoint: 'object-storage-server',  // hoặc 'localhost'
    port: 9000,
    useSSL: false,
    accessKey: 'minioadmin',
    secretKey: 'change_me_minio_password'
});

// Upload file
await minioClient.fPutObject('mycloud-files', 'test.html', './test.html');

// Get presigned URL (7 ngày)
const url = await minioClient.presignedGetObject('mycloud-files', 'test.html', 7*24*60*60);
```

### 9.3. Tích hợp qua S3 SDK (Python)

```python
from minio import Minio

client = Minio(
    "object-storage-server:9000",
    access_key="minioadmin",
    secret_key="change_me_minio_password",
    secure=False
)

# Upload file
client.fput_object("mycloud-files", "test.html", "./test.html")

# Liệt kê objects
objects = client.list_objects("mycloud-files")
for obj in objects:
    print(obj.object_name, obj.size)
```

---

## 10. Kiểm thử Object Storage

### Checklist kiểm thử:

- [ ] MinIO container khởi động thành công
- [ ] Truy cập MinIO Console tại http://localhost:9001
- [ ] Đăng nhập minioadmin thành công
- [ ] Tạo bucket `mycloud-files` thành công
- [ ] Upload file `index.html` thành công
- [ ] Upload file `avatar.jpg` thành công
- [ ] Upload file `document.pdf` thành công
- [ ] Truy cập file qua http://localhost:9000/mycloud-files/index.html
- [ ] Tạo Access Key thành công
- [ ] Dùng mc liệt kê file trong bucket thành công
- [ ] Ping từ container khác tới `object-storage-server` thành công

---

## 11. Xử lý sự cố

### Container không khởi động

```bash
docker logs object-storage-server
```

| Lỗi thường gặp                    | Nguyên nhân & giải pháp                          |
|------------------------------------|--------------------------------------------------|
| `Port 9000 already in use`         | Đổi port hoặc tắt service đang dùng port 9000   |
| `invalid credentials`              | Kiểm tra lại MINIO_ROOT_USER / MINIO_ROOT_PASSWORD |
| `disk not found`                   | Volume mount không đúng path                      |
| `Unable to connect`                | Container chưa khởi động, kiểm tra logs           |

### Reset MinIO (xoá toàn bộ data)

```bash
docker compose -f docker-compose.tv2.yml down -v
docker compose -f docker-compose.tv2.yml up -d object-storage-server
```

### Kiểm tra health

```bash
curl http://localhost:9000/minio/health/live
# Kết quả mong đợi: HTTP 200 OK
```

---

> ✅ **Hoàn tất cấu hình MinIO!** Tiếp tục upload file tĩnh cho web frontend và tích hợp với ứng dụng backend.

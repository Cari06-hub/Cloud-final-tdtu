# 🔐 Keycloak – Authentication & Identity Server

## Hướng dẫn cấu hình chi tiết (Tuấn Anh – TV2)

---

## Mục lục

1. [Tổng quan](#1-tổng-quan)
2. [Yêu cầu hệ thống](#2-yêu-cầu-hệ-thống)
3. [Khởi chạy Keycloak](#3-khởi-chạy-keycloak)
4. [Truy cập Admin Console](#4-truy-cập-admin-console)
5. [Tạo Realm mới](#5-tạo-realm-mới)
6. [Tạo Client cho ứng dụng](#6-tạo-client-cho-ứng-dụng)
7. [Tạo User](#7-tạo-user)
8. [Cấu hình Role](#8-cấu-hình-role)
9. [Tích hợp với ứng dụng](#9-tích-hợp-với-ứng-dụng)
10. [Kiểm thử xác thực](#10-kiểm-thử-xác-thực)
11. [Xử lý sự cố](#11-xử-lý-sự-cố)

---

## 1. Tổng quan

**Keycloak** là giải pháp Identity and Access Management (IAM) mã nguồn mở, cung cấp:
- Single Sign-On (SSO) / Single Sign-Out
- OAuth 2.0 / OpenID Connect / SAML 2.0
- User Federation (LDAP, Active Directory)
- Social Login (Google, GitHub, Facebook...)
- Multi-factor Authentication (MFA)

**Trong dự án MyMiniCloud**, Keycloak đóng vai trò:
- Xác thực người dùng cho web frontend
- Cấp phát token JWT cho application backend
- Quản lý phân quyền truy cập MinIO (Object Storage)

| Thông số          | Giá trị                            |
|-------------------|------------------------------------|
| Image             | `quay.io/keycloak/keycloak:24.0`   |
| Container name    | `authentication-identity-server`   |
| Port mapping      | `8081:8080`                        |
| Admin username    | `admin`                            |
| Admin password    | `change_me_keycloak`               |
| Network           | `cloud-net`                        |

---

## 2. Yêu cầu hệ thống

- Docker Engine ≥ 20.10
- Docker Compose ≥ 2.0
- RAM khả dụng ≥ 512 MB (khuyến nghị 1 GB)
- Network `cloud-net` đã được tạo

---

## 3. Khởi chạy Keycloak

### Cách 1: Chạy cùng bộ TV2

```bash
docker compose -f docker-compose.tv2.yml up -d authentication-identity-server
```

### Cách 2: Chạy riêng lẻ bằng docker run

```bash
docker run -d \
  --name authentication-identity-server \
  --network cloud-net \
  -p 8081:8080 \
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
  -e KC_BOOTSTRAP_ADMIN_PASSWORD=change_me_keycloak \
  quay.io/keycloak/keycloak:24.0 start-dev
```

### Kiểm tra container đã chạy

```bash
docker ps --filter "name=authentication-identity-server"
docker logs -f authentication-identity-server
```

> ⏳ Keycloak khởi động mất khoảng 30–60 giây. Đợi log hiện dòng:
> `Keycloak 24.0 ... started in XXs`

---

## 4. Truy cập Admin Console

1. Mở trình duyệt, truy cập: **http://localhost:8081**
2. Chọn **Administration Console**
3. Đăng nhập với:
   - Username: `admin`
   - Password: `change_me_keycloak`

> 📸 **Chụp màn hình** trang Admin Console → lưu vào `docs/evidence/`

---

## 5. Tạo Realm mới

Realm là đơn vị quản lý cao nhất trong Keycloak, tách biệt hoàn toàn user, client, role giữa các realm.

### Các bước:

1. Ở góc trái trên, click dropdown **"master"** → **Create Realm**
2. Nhập thông tin:
   - **Realm name**: `myminicloud`
   - **Enabled**: `ON`
3. Click **Create**

> 📸 **Chụp màn hình** sau khi tạo realm thành công

### Cấu hình Realm Settings:

1. Vào **Realm Settings** → tab **General**:
   - Display name: `MyMiniCloud`
   - Frontend URL: (để trống nếu dùng localhost)
2. Tab **Login**:
   - User registration: `ON` (cho phép đăng ký)
   - Forgot password: `ON`
   - Remember me: `ON`
3. Tab **Email** (tuỳ chọn): cấu hình SMTP nếu muốn gửi email

---

## 6. Tạo Client cho ứng dụng

Client đại diện cho một ứng dụng muốn sử dụng Keycloak để xác thực.

### 6.1. Client cho Web Frontend

1. Chuyển sang realm **myminicloud**
2. Menu trái → **Clients** → **Create client**
3. Tab **General Settings**:
   - Client type: `OpenID Connect`
   - Client ID: `web-frontend`
   - Name: `Web Frontend Application`
4. Tab **Capability config**:
   - Client authentication: `OFF` (public client)
   - Authorization: `OFF`
   - Standard flow: ✅
   - Direct access grants: ✅
5. Tab **Login settings**:
   - Root URL: `http://10.10.10.10`
   - Home URL: `http://10.10.10.10`
   - Valid redirect URIs: `http://10.10.10.10/*`
   - Web origins: `http://10.10.10.10`
6. Click **Save**

### 6.2. Client cho Application Backend

1. **Create client** → Client ID: `app-backend`
2. Client type: `OpenID Connect`
3. Client authentication: `ON` (confidential client)
4. Standard flow: ✅, Service accounts roles: ✅
5. Valid redirect URIs: `http://10.10.10.20/*`
6. Sau khi tạo, vào tab **Credentials** → copy **Client secret**

> 📸 **Chụp màn hình** danh sách clients đã tạo

---

## 7. Tạo User

### Tạo user thử nghiệm:

1. Menu trái → **Users** → **Add user**
2. Nhập thông tin:
   - Username: `testuser`
   - Email: `testuser@cloud.local`
   - First name: `Test`
   - Last name: `User`
   - Email verified: `ON`
3. Click **Create**
4. Chuyển sang tab **Credentials**:
   - Click **Set password**
   - Password: `Test@1234`
   - Temporary: `OFF`
   - Click **Save** → **Save password**

> 📸 **Chụp màn hình** trang user detail

---

## 8. Cấu hình Role

### 8.1. Tạo Realm Roles

1. Menu trái → **Realm roles** → **Create role**
2. Tạo các role:
   - `user` – Role mặc định cho người dùng thường
   - `admin` – Role quản trị
   - `storage-access` – Role truy cập MinIO

### 8.2. Gán Role cho User

1. Vào **Users** → chọn `testuser` → tab **Role mapping**
2. Click **Assign role**
3. Chọn: `user`, `storage-access`
4. Click **Assign**

---

## 9. Tích hợp với ứng dụng

### 9.1. Lấy thông tin endpoint

Keycloak cung cấp OpenID Configuration tại:

```
http://localhost:8081/realms/myminicloud/.well-known/openid-configuration
```

Các endpoint quan trọng:

| Endpoint            | URL                                                                    |
|---------------------|------------------------------------------------------------------------|
| Authorization       | `http://localhost:8081/realms/myminicloud/protocol/openid-connect/auth` |
| Token               | `http://localhost:8081/realms/myminicloud/protocol/openid-connect/token`|
| UserInfo            | `http://localhost:8081/realms/myminicloud/protocol/openid-connect/userinfo` |
| Logout              | `http://localhost:8081/realms/myminicloud/protocol/openid-connect/logout` |

### 9.2. Test lấy token bằng curl

```bash
# Direct Access Grant (Resource Owner Password)
curl -X POST http://localhost:8081/realms/myminicloud/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=web-frontend" \
  -d "username=testuser" \
  -d "password=Test@1234" \
  -d "grant_type=password"
```

Kết quả trả về JSON chứa `access_token`, `refresh_token`, `expires_in`.

### 9.3. Decode JWT Token

Truy cập https://jwt.io → paste `access_token` để xem payload (chứa realm roles, resource access, user info).

---

## 10. Kiểm thử xác thực

### Checklist kiểm thử:

- [ ] Keycloak container khởi động thành công
- [ ] Truy cập Admin Console tại http://localhost:8081
- [ ] Đăng nhập admin thành công
- [ ] Tạo realm `myminicloud` thành công
- [ ] Tạo client `web-frontend` và `app-backend` thành công
- [ ] Tạo user `testuser` thành công
- [ ] Lấy access token bằng curl thành công
- [ ] Token chứa đúng realm roles đã gán
- [ ] Ping từ container khác tới `authentication-identity-server` thành công

---

## 11. Xử lý sự cố

### Container không khởi động

```bash
docker logs authentication-identity-server
```

| Lỗi thường gặp                    | Nguyên nhân & giải pháp                          |
|------------------------------------|--------------------------------------------------|
| `Port 8081 already in use`         | Đổi port hoặc tắt service đang dùng port 8081   |
| `Out of memory`                    | Tăng RAM cho Docker Desktop (≥ 2 GB)             |
| `Connection refused`               | Container chưa khởi động xong, đợi thêm 30s     |
| `Invalid credentials`              | Kiểm tra lại biến môi trường admin username/pass |

### Reset Keycloak

```bash
docker compose -f docker-compose.tv2.yml down -v
docker compose -f docker-compose.tv2.yml up -d authentication-identity-server
```

---

> ✅ **Hoàn tất cấu hình Keycloak!** Tiếp tục tích hợp với Nginx reverse proxy và ứng dụng frontend.

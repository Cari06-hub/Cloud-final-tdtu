# Keycloak Setup - Realm nhóm

## Giá trị chuẩn

| Mục | Giá trị |
|---|---|
| Admin URL | `http://localhost:8081` |
| Admin user | `${KEYCLOAK_ADMIN}` |
| Admin password | Chỉ lưu trong `.env` local |
| Realm | `realm_52400001` |
| Client | `flask-app` |

Nếu trưởng nhóm đổi MSSV đại diện, phải cập nhật đồng thời Realm, `.env`, Flask
OIDC, script token, tài liệu và ảnh E4.

## 1. Tạo Realm

1. Đăng nhập Admin Console.
2. Chọn **Create Realm**.
3. Đặt tên `realm_52400001` và bật Realm.

## 2. Tạo client `flask-app`

1. Chọn **Clients** -> **Create client**.
2. Client type: `OpenID Connect`.
3. Client ID: `flask-app`.
4. Client authentication: `OFF` để dùng public client.
5. Direct access grants: `ON`.
6. Chỉ dùng redirect URI rộng trong phạm vi lab; không dùng `*` cho production.

## 3. Thêm Audience mapper

1. Mở client `flask-app` -> **Client scopes**.
2. Mở dedicated client scope.
3. **Add mapper** -> **By configuration** -> **Audience**.
4. Name: `flask-app-audience`.
5. Included Client Audience: `flask-app`.
6. Lưu và kiểm tra token có claim `aud` phù hợp.

## 4. Tạo user

Tạo hai user:

- `sv01`, email `sv01@cloud.local`.
- `sv02`, email `sv02@cloud.local`.

Đặt mật khẩu mạnh khác nhau từ biến local `SV01_PASSWORD` và `SV02_PASSWORD`;
tắt **Temporary**. Không ghi mật khẩu thật vào tài liệu.

## 5. Token endpoint và kiểm thử

Endpoint:

```text
http://localhost:8081/realms/realm_52400001/protocol/openid-connect/token
```

Chạy script:

```bash
set -a
. ./.env
set +a
./scripts/keycloak-test-token.sh
```

Sau khi lấy token, gọi `/secure` với Bearer token. Khi chụp ảnh phải che token.

# Keycloak - Authentication & Identity Server

## Cấu hình tích hợp

| Mục | Giá trị |
|---|---|
| Image | `quay.io/keycloak/keycloak:26.8.2` |
| Container | `authentication-identity-server` |
| Port | `8081:8080` |
| Network/IP | `cloud-net` / `10.10.10.40` |
| Realm dự kiến | `realm_52400001` |
| Client | `flask-app` - public client |
| Persistence | `keycloak_data:/opt/keycloak/data` |

Image được ghim phiên bản để local và EC2 dùng cùng một bản. Dự án dùng
`start-dev` vì đây là bài lab; không xem cấu hình này là cấu hình production.

## Biến môi trường

```dotenv
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=REPLACE_WITH_STRONG_KEYCLOAK_PASSWORD
GROUP_MSSV=52400001
KEYCLOAK_REALM=realm_52400001
SV01_PASSWORD=REPLACE_WITH_STRONG_SV01_PASSWORD
SV02_PASSWORD=REPLACE_WITH_STRONG_SV02_PASSWORD
```

Không ghi mật khẩu thật vào Compose, tài liệu, script hoặc ảnh minh chứng.

## Khởi động độc lập phần TV2

```bash
cp .env.example .env
# Điền giá trị thật vào .env
docker compose --env-file .env -f docker-compose.tv2.yml config --quiet
docker compose --env-file .env -f docker-compose.tv2.yml up -d
docker compose --env-file .env -f docker-compose.tv2.yml ps
```

Truy cập Admin Console tại `http://localhost:8081`.

## Cấu hình bắt buộc

Thực hiện theo [keycloak-setup.md](keycloak-setup.md):

1. Tạo Realm `realm_52400001`.
2. Tạo public client `flask-app`.
3. Bật Direct Access Grants.
4. Tạo user `sv01` và `sv02`, đặt mật khẩu từ môi trường local.
5. Tắt chế độ mật khẩu Temporary.
6. Thêm Audience mapper với Included Client Audience là `flask-app`.

## Kiểm thử

Export biến từ `.env` vào shell trước khi chạy script hoặc cung cấp trực tiếp
`SV01_PASSWORD` và `SV02_PASSWORD` trong môi trường:

```bash
set -a
. ./.env
set +a
./scripts/keycloak-test-token.sh
```

Các điều kiện đạt:

- Admin Console đăng nhập thành công.
- Realm, hai user và client tồn tại.
- Token endpoint trả access token cho `sv01` và `sv02`.
- Claim `aud` có `flask-app`.
- Token hợp lệ gọi Flask `/secure` trả HTTP 200 và `preferred_username`.

## Persistence và reset

Named volume `keycloak_data` giữ Realm khi container được recreate. Không dùng
`docker compose down -v` trừ khi nhóm chủ động muốn xóa toàn bộ cấu hình.

Khi cần reset có kiểm soát, phải chụp/xuất cấu hình cần giữ và thông báo nhóm
trước khi xóa volume.

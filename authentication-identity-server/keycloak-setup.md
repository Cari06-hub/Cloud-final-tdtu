# Keycloak Setup – MSSV: 52400001

## Thông tin cơ bản

| Mục               | Giá trị                     |
|-------------------|-----------------------------|
| Admin URL         | http://localhost:8081        |
| Admin user        | admin                        |
| Admin password    | change_me_keycloak           |
| **Realm name**    | **realm_52400001**           |

---

## Các bước cấu hình (thực hiện trên Admin Console)

### Bước 1 – Tạo Realm

1. Truy cập http://localhost:8081 → đăng nhập admin
2. Dropdown "master" → **Create Realm**
3. Realm name: `realm_52400001` → **Create**

### Bước 2 – Tạo Client `flask-app`

1. Menu → **Clients** → **Create client**
2. Client ID: `flask-app`
3. Client type: `OpenID Connect`
4. Client authentication: **OFF** (public)
5. Direct access grants: ✅ ON
6. Valid redirect URIs: `*`
7. **Save**

### Bước 3 – Thêm Audience Mapper

1. Vào client `flask-app` → tab **Client scopes**
2. Click `flask-app-dedicated` → **Add mapper** → **By configuration**
3. Chọn **Audience**
4. Name: `flask-app-audience`
5. Included Client Audience: `flask-app`
6. **Save**

### Bước 4 – Tạo User sv01

1. Menu → **Users** → **Add user**
2. Username: `sv01`
3. Email: `sv01@cloud.local`, Email verified: ON
4. **Create** → tab **Credentials**
5. Set password: `Sv01@1234`, Temporary: **OFF** → Save

### Bước 5 – Tạo User sv02

1. **Add user** → Username: `sv02`
2. Email: `sv02@cloud.local`, Email verified: ON
3. **Create** → tab **Credentials**
4. Set password: `Sv02@1234`, Temporary: **OFF** → Save

---

## Test lấy token

```bash
curl -X POST http://localhost:8081/realms/realm_52400001/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=flask-app" \
  -d "username=sv01" \
  -d "password=Sv01@1234" \
  -d "grant_type=password"
```

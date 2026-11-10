# Phase 0 - Nội dung xin xác nhận từ nhóm

> Người tổng hợp: Trung Nguyên - `52400141`
> Mục tiêu: khóa các quyết định còn mở trước khi tích hợp Compose
> Tài liệu chuẩn: [integration-contract.md](integration-contract.md)

## 1. Tin nhắn gửi trưởng nhóm

```text
Mình đang khóa chuẩn tích hợp trên nhánh Nguyen. Hiện cả nhánh Quang và nhánh
feature/auth-storage-dns đều đang dùng MSSV đại diện nhóm 52400001, Realm
realm_52400001. Để không làm hỏng OIDC, đề nghị chốt:

1. GROUP_MSSV = 52400001
2. Keycloak Realm = realm_52400001
3. Dashboard phần TV3 vẫn dùng MSSV cá nhân và tên:
   System Health of 52400141
4. Network = cloud-net, subnet dự kiến 10.10.10.0/24
5. Tên service và port giữ theo docs/integration-contract.md

Vui lòng phản hồi "Đồng ý" hoặc ghi chính xác giá trị cần thay. Nếu đổi MSSV
Realm thì TV1 và TV2 phải cùng cập nhật OIDC, Realm, script token, tài liệu và
ảnh E4 trước khi TV3 khóa Compose.
```

Kết quả cần ghi lại:

- [ ] Trưởng nhóm đồng ý `GROUP_MSSV=52400001`.
- [ ] Trưởng nhóm đồng ý `realm_52400001`.
- [ ] Trưởng nhóm đồng ý `System Health of 52400141`.
- [ ] Trưởng nhóm đồng ý hợp đồng service/port/network.
- Ngày xác nhận: `________________`.
- Người xác nhận: `________________`.
- Ghi chú/thay đổi: `________________________________________________`.

## 2. Tin nhắn gửi TV1

```text
Để TV3 tích hợp Gateway, Prometheus và Compose, nhờ TV1 xác nhận/bàn giao:

1. Web 1 thêm nội dung nhận diện chính xác "Server 1" trên trang chủ.
2. Web 2 giữ nội dung nhận diện "Server 2".
3. GET /metrics trả HTTP 200, Content-Type text/plain và có dòng web_up 1.
4. Giữ nguyên endpoint Flask: /hello, /student, /students-db, /secure.
5. Flask nhận DB/OIDC qua biến môi trường theo integration-contract.md.
6. Không bàn giao hoặc commit .env; mật khẩu cũ đã lên Git phải được thay.
7. Gửi lệnh test và ảnh B1-B3, E1-E3; gửi link Docker Hub khi hoàn thành.

Nhờ phản hồi từng mục Đạt/Chưa đạt và báo trước nếu cần đổi tên service, port,
endpoint hoặc biến môi trường.
```

Kết quả cần ghi lại:

- [ ] Web 1 có `Server 1`.
- [ ] Web 2 có `Server 2`.
- [ ] `/metrics` đạt hợp đồng.
- [ ] Bốn endpoint Flask được giữ nguyên.
- [ ] Biến môi trường DB/OIDC được xác nhận.
- [ ] `.env` không được bàn giao/merge.
- [ ] Mật khẩu từng bị commit đã được thay.
- Ngày xác nhận: `________________`.
- Người xác nhận: `________________`.
- Ghi chú/thay đổi: `________________________________________________`.

## 3. Tin nhắn gửi TV2

```text
Để TV3 khóa Compose, nhờ TV2 xác nhận/bàn giao các quyết định sau:

1. Realm cuối là realm_52400001, gồm sv01, sv02, client flask-app, Direct
   Access Grants và Audience mapper flask-app.
2. Review lựa chọn tích hợp `bitnamilegacy/minio:2024.6.13`; manifest đã được
   kiểm tra và Compose/README đã thống nhất.
3. Xác nhận Bitnami entrypoint mặc định cùng data path
   `/bitnami/minio/data` và named volume `minio_data`.
4. Review persistence Keycloak `keycloak_data:/opt/keycloak/data`.
5. Xác nhận DNS A record:
   web-frontend-server=10.10.10.10,
   app-backend=10.10.10.20,
   minio=10.10.10.30,
   keycloak=10.10.10.40.
6. Đối chiếu ns.cloud.local với IP DNS container dự kiến 10.10.10.50.
7. Không hard-code password trong Compose cuối; dùng biến từ .env.
8. Gửi lệnh test và ảnh B4-B6, B10, E4-E6; gửi link video khi hoàn thành.

Nhờ phản hồi từng mục Đạt/Chưa đạt và báo trước nếu cần đổi tên service, port,
Realm, endpoint hoặc cấu trúc volume.
```

Kết quả cần ghi lại:

- [ ] Realm và MSSV đại diện nhóm được xác nhận.
- [ ] Image MinIO `bitnamilegacy/minio:2024.6.13` được TV2 xác nhận.
- [ ] Bitnami entrypoint mặc định được TV2 xác nhận.
- [ ] `minio_data:/bitnami/minio/data` được TV2 xác nhận.
- [ ] `keycloak_data:/opt/keycloak/data` được TV2 xác nhận.
- [ ] Các DNS record/IP được xác nhận.
- [ ] Secret được chuyển sang `.env`.
- Ngày xác nhận: `________________`.
- Người xác nhận: `________________`.
- Ghi chú/thay đổi: `________________________________________________`.

## 4. Kiểm tra subnet sau khi bật Docker Desktop

Chạy:

```powershell
docker network ls
docker network inspect cloud-net
Get-NetRoute -DestinationPrefix '10.10.10.0/24' -ErrorAction SilentlyContinue
```

Nếu `cloud-net` chưa tồn tại, kiểm tra các network hiện có trước khi tạo. Nếu
subnet `10.10.10.0/24` xung đột VPN, route của tổ chức hoặc network Docker khác,
không tự đổi subnet: phải cập nhật đồng thời Compose, Bind9 zone, tài liệu và mọi
ảnh/lệnh kiểm thử liên quan.

- [ ] Docker Desktop daemon đã chạy.
- [ ] Không có Docker network trùng subnet.
- [ ] Không có VPN/host route gây xung đột.
- [ ] Cổng 80, 3000, 8080, 8081, 8085, 9000, 9001, 9090 không bị chiếm.
- Người kiểm tra: `________________`.
- Ngày kiểm tra: `________________`.

## 5. Điều kiện chuyển hợp đồng từ draft sang locked

Chỉ đổi phiên bản trong `integration-contract.md` từ `1.0-draft` thành
`1.0-locked` khi:

- [ ] Trưởng nhóm đã phản hồi.
- [ ] TV1 đã phản hồi.
- [ ] TV2 đã phản hồi.
- [ ] Subnet đã được kiểm tra khi Docker daemon chạy.
- [ ] Mọi thay đổi do phản hồi đã cập nhật vào hợp đồng, README và plan.
- [ ] Giai đoạn 0 trong `plan.md` không còn checklist mở ảnh hưởng Compose,
      Realm hoặc endpoint.

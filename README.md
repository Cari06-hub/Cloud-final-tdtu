# MyMiniCloud - Cloud Final TDTU

Repository triển khai hệ thống MyMiniCloud bằng Docker Compose cho báo cáo cuối kỳ môn Điện toán đám mây.

## Trạng thái tích hợp

- Nhánh tích hợp của TV3: `Nguyen`.
- MSSV dashboard TV3: `52400141`.
- MSSV đại diện nhóm/Realm tạm khóa theo mã nguồn hiện tại: `52400001`.
- Network chung: `cloud-net`.
- Gateway công khai của hệ thống: `http://localhost/` ở local và `http://<EC2_PUBLIC_IP>/` trên EC2.

Quy chuẩn tên service, port, endpoint, network, biến môi trường, IP nội bộ và quy trình thay đổi được định nghĩa tại [docs/integration-contract.md](docs/integration-contract.md). Các nội dung cần trưởng nhóm, TV1 và TV2 xác nhận được soạn sẵn tại [docs/phase-0-handoff.md](docs/phase-0-handoff.md). Mọi thay đổi ảnh hưởng hợp đồng này phải được chủ sở hữu service và TV3 xác nhận trước khi merge.

Kế hoạch triển khai và checklist chi tiết của Trung Nguyên được lưu tại [plan.md](plan.md).

Baseline bảo mật, quy tắc tích hợp nhánh TV1 và checklist thay credential được lưu tại [docs/security-baseline.md](docs/security-baseline.md).

## Thành viên và phạm vi

| Thành viên | Phạm vi chính |
|---|---|
| TV1 | Web, Flask API, MariaDB, Docker Hub |
| Tuấn Anh | Keycloak, MinIO, Bind9, ping test, video |
| Trung Nguyên - 52400141 | Prometheus, Grafana, Gateway, Compose, tích hợp, EC2 và tổng hợp báo cáo |

## Nguyên tắc bảo mật

- Không commit `.env`, mật khẩu, token, access key, private key hoặc AWS credentials.
- Chỉ commit `.env.example` với placeholder.
- Mật khẩu từng xuất hiện trong lịch sử Git phải được thay trước khi demo hoặc deploy EC2.
- MariaDB, Node Exporter và các cổng quản trị không được mở công khai trên EC2.

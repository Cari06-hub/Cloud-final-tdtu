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

Nguồn file, các thay đổi chuẩn hóa và kết quả kiểm tra Giai đoạn 2 được ghi tại [docs/stage-2-integration-audit.md](docs/stage-2-integration-audit.md).

Cấu hình, quyết định phiên bản và kết quả nghiệm thu Prometheus/Node Exporter được ghi tại [docs/stage-3-monitoring-audit.md](docs/stage-3-monitoring-audit.md).

Cấu hình provisioning, dashboard B8/E8 và kết quả kiểm thử Grafana từ volume rỗng được ghi tại [docs/stage-4-grafana-audit.md](docs/stage-4-grafana-audit.md).

Cấu hình Gateway, các route B9/E9 và kết quả Round Robin E10 được ghi tại [docs/stage-5-gateway-audit.md](docs/stage-5-gateway-audit.md).

Compose tích hợp đủ 11 container, IPAM, DNS, persistence và kết quả hồi quy Giai đoạn 6 được ghi tại [docs/stage-6-compose-audit.md](docs/stage-6-compose-audit.md).

## Khởi động stack tích hợp

```bash
cp .env.example .env
# Thay toàn bộ REPLACE_* trong .env bằng giá trị mạnh chỉ dùng ở local.
docker compose --env-file .env config --quiet
docker compose --env-file .env build
docker compose --env-file .env up -d
docker compose --env-file .env ps
```

Nghiệm thu tự động trên PowerShell:

```powershell
./scripts/test-compose.ps1 `
  -EnvFile .env `
  -GrafanaAdminUser $env:GF_SECURITY_ADMIN_USER `
  -GrafanaAdminPassword $env:GF_SECURITY_ADMIN_PASSWORD
```

Không chạy `docker compose down -v` nếu muốn giữ database, Realm Keycloak,
bucket MinIO, dữ liệu Prometheus và Grafana.

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

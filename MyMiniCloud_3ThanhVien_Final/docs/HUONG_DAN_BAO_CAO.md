# HƯỚNG DẪN THU THẬP MINH CHỨNG VÀ VIẾT BÁO CÁO NHÓM

## Quy trình thống nhất cho ba người

1. Giải nén **cùng một bản ZIP**, chạy `START_WINDOWS.cmd` trên ba máy riêng.
2. Chạy `py -3 scripts/verify_local.py` hoặc `python3 scripts/verify_local.py`.
3. Chụp `docker compose ps` đủ 11 container, kết quả kiểm thử 20 mục và các giao diện / URL tương ứng; lưu thành `B1_...png`, `E1_...png`...; thêm vào `docs/evidence/moi` của từng máy. Chụp không lộ `.env`, mật khẩu, token.
4. Mỗi người báo lại hạng mục FAIL (nếu có), log `docker compose logs --tail 100 <service>` không chứa bí mật để nhóm cùng sửa.
5. Chỉ dùng ảnh từ **cùng bản cuối**, cùng cấu hình, cùng lần kiểm chứng khi trích dẫn vào báo cáo.

## Cấu trúc 5 chương như đề yêu cầu

### Chương 1. Giới thiệu & mục tiêu
- Điện toán đám mây, ý nghĩa mini-cloud, yêu cầu 9 loại server.
- Công nghệ và phạm vi: 11 container, một Docker network, chạy local và EC2.
- Sự khác nhau giữa *9 loại server* và *11 container*.

### Chương 2. Kiến trúc & sơ đồ
- Sơ đồ tổng thể tại `docs/SO_DO_KIEN_TRUC.md`.
- IP / Port / volume / restart / các luồng Web, API, JWT, metrics, DNS và MinIO.
- Nêu ranh giới tin cậy: chỉ Gateway port 80 công khai, DB và admin không đưa thẳng ra Internet.

### Chương 3. Cấu hình & Dockerfile
- Bảng các image với phiên bản được pin trong `docker-compose.yml`.
- Trích phần cần thiết của hai Dockerfile Web + Dockerfile Flask và lý do dùng image có sẵn cho 6 server còn lại.
- Nêu `.env.example`, SQL, zone DNS, Prometheus scrape config, Grafana provisioning, Nginx upstream Round Robin.
- Khởi tạo Keycloak Realm/client/users và MinIO bucket bằng script; mật khẩu lưu riêng, không đưa vào báo cáo.

### Chương 4. Demo & kiểm thử
- Chuỗi `docker compose config`, `up -d --build`, `ps` và kết quả kiểm tra.
- Ma trận **B1–B10** và **E1–E10** ở `docs/BANG_DOI_CHIEU_DE_BAI.md`; có ảnh cùng mục và giá trị đúng.
- Đính kèm log `docs/evidence/moi/kiem-thu-....txt` trên máy thực tế.
- Demo EC2 với Public IP, đảm bảo đã kiểm tra được thực tế.

### Chương 5. Đánh giá & phân tích
- Ưu điểm: một Compose, phân tách thành phần, tích hợp qua mạng, quan sát CPU/RAM/Network, scale Web 2 instance.
- Giới hạn: lab không phải Cloud Platform thực; Grafana hiện hiển thị metrics, không có Loki log collection; MinIO chưa được tích hợp vào một tính năng upload của Flask; Keycloak `start-dev` chỉ cho demo.
- Khó khăn thực tế: máy RAM 8 GB, Docker Desktop/WSL2, cổng trùng, Keycloak boot chậm, init DB, cấu hình JWT, static IP.
- Hướng mở rộng: TLS, Docker secrets, IaC, thêm Loki, CI/CD, autoscaling, backup/restore.

### Phụ lục
- Link GitHub nhánh cuối, Docker Hub image/tag, video demo, Public IP EC2 (chỉ nếu đang còn tồn tại), log Docker/test và ảnh.
- Phân công 3 người và bảng tỷ lệ đóng góp.

## Phân công người viết

- **TV1 Quang:** Chương 3 về Web / Flask / MariaDB, B1–B3, E1–E3.
- **TV2 Tuấn Anh:** Chương 3 về Keycloak / MinIO / DNS, B4–B6, E4–E6; tham khảo `docs/tham-khao-thanh-vien/TV2_Bao_cao_Chuong_1_3_5.md`.
- **TV3 Nguyen:** Sơ đồ Chương 2, Chương 3 Monitoring/Grafana/Gateway, B7–B10, E7–E10, bảng Docker Compose, EC2 và tổng hợp kiểm thử.
- **Cả nhóm:** Chương 1, Chương 5, danh mục minh chứng và review bản nộp cuối.

> Không tạo ảnh giả, không ghi thành công EC2/Docker Hub khi chưa tự xác minh. Mọi minh chứng cũ từ các ZIP gốc được lưu phân biệt dưới `docs/evidence/local` hoặc `docs/evidence/tu-TV2`.

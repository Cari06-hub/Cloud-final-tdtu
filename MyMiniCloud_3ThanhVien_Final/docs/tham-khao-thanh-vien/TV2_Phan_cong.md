**KẾ HOẠCH PHÂN CÔNG DỰ ÁN MYMINICLOUD**

3 thành viên • Phân chia độc lập • Tích hợp theo một chuẩn thống nhất • Bản hợp nhất v3

# **1\. Mục tiêu và nguyên tắc làm việc**

* **Mục tiêu:** hệ thống MyMiniCloud gồm 9 nhóm server của đề \+ Node Exporter (phụ trợ), chạy bằng Docker Compose, chung network cloud-net, kiểm thử local và triển khai trên AWS EC2 Ubuntu qua Public IP.

* **Điểm:** phần cơ bản 5 điểm (10 bài kiểm thử, gồm cả bài ping mạng) \+ phần mở rộng 5 điểm (10 yêu cầu × 0,5). Đối chiếu từng mục ở **Mục 4**.

* **Chuẩn chung:** tên thư mục, service, container\_name, network, port, biến môi trường đã chốt trong tài liệu này; không tự đổi. Nếu cần đổi thì báo cả nhóm và sửa đồng thời compose, cấu hình, README và lệnh kiểm thử.

* **Sở hữu:** mỗi người tự code và kiểm thử độc lập trong thư mục được giao. TV3 chỉ ghép compose và gateway, **không viết lại mã ứng dụng** của TV1/Tuấn Anh; cần sửa thì nhờ chủ sở hữu xác nhận.

* **Minh chứng:** mỗi tính năng phải có ảnh chụp màn hình hoặc log, lưu vào docs/evidence/ theo tên E4\_token.png, B6\_dig.png… (mã bài ở Mục 4).

* **An toàn:** không commit .env, mật khẩu, access key. Không chạy docker rm \-f \$(docker ps \-aq) như ví dụ của đề trên máy đang chạy project khác; chỉ dùng docker compose down trong thư mục dự án.

# **2\. Cấu trúc thư mục chính thức**

Tạo đúng cấu trúc dưới đây ở gốc repository. 

MyMiniCloud/

├── docker-compose.yml  
├── .env.example                  (.env thật nằm trong .gitignore)  
├── .gitignore  
├── README.md  
├── scripts/  
│   └── ping-test.sh              \[MỚI\] bài ping mạng (B10)  
├── docs/evidence/                \[MỚI\] ảnh/log minh chứng cho báo cáo  
├── web-frontend-server/  
│   ├── Dockerfile  
│   ├── conf.default              (có location \= /metrics)  
│   ├── html/  index.html, metrics \[MỚI\], blog/ (index, blog1-3.html), images/  
│   └── html2/index.html          \[MỚI\] trang "Server 2" cho web 2  
├── application-backend-server/  
│   ├── Dockerfile, requirements.txt, app.py  
│   └── students.json             (5 sinh viên: id, name, major, gpa)  
├── relational-database-server/init/01-init.sql  
├── authentication-identity-server/README-config.md  
├── object-storage-server/README-config.md  
├── internal-dns-server/  
│   ├── named.conf  
│   └── zones/db.cloud.local  
├── monitoring-prometheus-server/prometheus.yml  
├── monitoring-grafana-dashboard-server/dashboards/  
└── api-gateway-proxy-server/nginx.conf

Keycloak, MinIO, MariaDB, Prometheus, Grafana, Node Exporter dùng image chính thức, không cần Dockerfile riêng; nên ghim phiên bản (ví dụ mariadb:11, grafana/grafana:11…) thay vì latest để cả nhóm và EC2 chạy giống nhau. README-config.md ghi lại các bước cấu hình tạo qua giao diện web.

# **3\. Quy ước service, container, network và port**

Tên service và container\_name giống nhau. Mọi service vào network cloud-net (khai báo một lần ở cấp cao nhất với name: cloud-net), dùng restart: unless-stopped, có volume khi cần lưu dữ liệu (MariaDB, MinIO, Grafana). Giao tiếp giữa container dùng service name và cổng nội bộ, không dùng localhost.

| Thành phần | Service / container | Port host:container | Ghi chú |
| :---- | :---- | :---- | :---- |
| **Web chính** | web-frontend-server | 8080:80 | Trang chủ, blog, /metrics |
| **Web phụ (LB)** | web-frontend-server2 | không publish | Cùng image, mount html2/ để nhận diện "Server 2" |
| **Flask API** | application-backend-server | 8085:8081 | Listen 0.0.0.0:8081; /hello, /student, /students-db, /secure |
| **MariaDB** | relational-database-server | 3306:3306 | Chỉ publish khi cần debug từ host |
| **Keycloak** | authentication-identity-server | 8081:8080 | start-dev; realm realm\_\<MSSV\> |
| **MinIO** | object-storage-server | 9000:9000, 9001:9001 | S3 API và Console |
| **Bind9** | internal-dns-server | 1053:53/udp | Zone cloud.local |
| **Prometheus** | monitoring-prometheus-server | 9090:9090 | Scrape node-exporter:9100 và web-frontend-server:80 |
| **Node Exporter** | node-exporter | 9100:9100 | Có thể không publish |
| **Grafana** | monitoring-grafana-dashboard-server | 3000:3000 | Datasource http\://monitoring-prometheus-server:9090 |
| **Gateway** | api-gateway-proxy-server | 80:80 | Nginx reverse proxy \+ Round Robin |

# **4\. Bảng đối chiếu với đề cuối kỳ**

Đây là bảng quan trọng nhất: mỗi bài của đề có một người chịu trách nhiệm, một lệnh/URL kiểm thử và một ảnh minh chứng. Cột “Mã” dùng để đặt tên file ảnh.

## **4.1. Phần cơ bản (5 điểm)**

| Mã | Server | Phụ trách | Lệnh / URL kiểm thử | Kết quả cần đạt |
| :---- | :---- | :---- | :---- | :---- |
| B1 | Web | TV1 | curl \-I http\://localhost:8080/ curl \-I http\://localhost:8080/blog/ | HTTP 200; “MyMiniCloud – Home”, trang blog hiển thị |
| B2 | App | TV1 | curl http\://localhost:8085/hello curl http\://localhost/api/hello | JSON {"message":"Hello from App Server\!"}, hai lệnh giống nhau |
| B3 | Database | TV1 | docker exec relational-database-server mariadb \-uroot \-p"\$MARIADB\_ROOT\_PASSWORD" \-e "USE minicloud; SHOW TABLES; SELECT \* FROM notes;" **\[MỚI\]** lệnh mẫu của đề dùng host db, nhóm dùng tên container thật | Có bảng notes, có dòng “Hello from MariaDB\!” |
| B4 | Keycloak | Tuấn Anh | Mở http\://localhost:8081, đăng nhập admin | Vào được Dashboard, tạo được user test sv01 |
| B5 | MinIO | Tuấn Anh | Mở http\://localhost:9001 | Tạo bucket demo, upload index.html thấy trong bucket |
| B6 | DNS | Tuấn Anh | dig @127.0.0.1 \-p 1053 web-frontend-server.cloud.local \+short | Trả về 10.10.10.10 |
| B7 | Prometheus | TV3 | http\://localhost:9090/targets; truy vấn node\_cpu\_seconds\_total | Target node-exporter UP, truy vấn có dữ liệu |
| B8 | Grafana | TV3 | http\://localhost:3000: thêm datasource Prometheus, import “Node Exporter Full” | **\[MỚI\]** Dashboard hiển thị CPU/RAM/Network (đề cơ bản yêu cầu import) |
| B9 | Gateway | TV3 | curl \-I http\://localhost/ curl \-s http\://localhost/api/hello curl \-I http\://localhost/auth/ | / → 200; /api/hello → JSON; /auth/ → 302 |
| B10 | Ping mạng | Tuấn Anh | **\[MỚI\]** ./scripts/ping-test.sh | Ping thành công tới mọi server trong cloud-net; chụp toàn bộ kết quả |

## **4.2. Phần mở rộng (10 × 0,5 điểm)**

| Mã | Yêu cầu | Phụ trách | Lệnh / URL kiểm thử | Kết quả cần đạt |
| :---- | :---- | :---- | :---- | :---- |
| E1 | Blog 3 bài | TV1 | http\://localhost:8080/ và /blog/ | index.html liệt kê 3 bài có hyperlink; mỗi bài có ảnh minh họa và link quay lại trang chính |
| E2 | API /student | TV1 | curl http\://localhost:8085/student curl http\://localhost/api/student | JSON 5 sinh viên (id, name, major, gpa) đọc từ students.json |
| E3 | studentdb | TV1 | **\[MỚI\]** curl http\://localhost/api/students-db | Bảng students (≥3 bản ghi, nhóm đặt 5\) đọc từ MariaDB; chụp thêm SELECT/UPDATE/DELETE nếu làm tùy chọn |
| E4 | Keycloak realm | Tuấn Anh \+ TV1 | Lấy token từ token endpoint của realm\_\<MSSV\>, gọi /secure kèm Bearer | Realm theo MSSV, user sv01/sv02, client flask-app (public); /secure trả 200 và preferred\_username |
| E5 | MinIO bucket | Tuấn Anh | http\://localhost:9001 | Bucket profile-pics (avatar.jpg, mở được qua public URL) và documents (PDF) |
| E6 | DNS | Tuấn Anh | dig @127.0.0.1 \-p 1053 app-backend.cloud.local \+short (và minio, keycloak) | 10.10.10.20 / 10.10.10.30 / 10.10.10.40; đã restart container rồi kiểm tra lại |
| E7 | Prometheus | TV3 \+ TV1 | http\://localhost:9090/targets | Target web-frontend-server:80 UP (cần /metrics, xem Mục 11\) |
| E8 | Grafana | TV3 | http\://localhost:3000 | Dashboard System Health of \<MSSV\>: CPU Usage (%), Memory Usage, Network Traffic, có dữ liệu |
| E9 | Route /student/ | TV3 | curl http\://localhost/student/ | JSON danh sách sinh viên qua gateway |
| E10 | Round Robin | TV3 \+ TV1 | **\[MỚI\]** for i in 1 2 3 4 5 6; do curl \-s http\://localhost/ \| grep \-o "Server \[12\]"; done | Kết quả luân phiên Server 1 / Server 2 |

Đề yêu cầu **ghi rõ trong báo cáo đã làm được bao nhiêu phần mở rộng**; TV3 đưa bảng 4.2 (cột kết quả thực tế: Đạt / Không đạt) vào đầu Chương 4\.

# **5\. Biến môi trường và bảo mật**

Giá trị thật chỉ nằm trong .env (đã .gitignore). Trong compose dùng \${TEN\_BIEN}, không ghi mật khẩu thật vào YAML. **\[MỚI\]** Thêm MSSV, OIDC\_JWKS\_URL, và đổi audience sang flask-app cho khớp đề.

MSSV=\<điền\_MSSV\_nhóm\_đã\_chốt\>  
MARIADB\_ROOT\_PASSWORD=change\_me\_root  
MARIADB\_DATABASE=minicloud  
MARIADB\_USER=minicloud\_user  
MARIADB\_PASSWORD=change\_me\_db  
KEYCLOAK\_ADMIN=admin  
KEYCLOAK\_ADMIN\_PASSWORD=change\_me\_keycloak  
MINIO\_ROOT\_USER=minioadmin  
MINIO\_ROOT\_PASSWORD=change\_me\_minio\_password  
\# Issuer \= đúng giá trị claim "iss" trong token (URL mà người dùng dùng để lấy token)  
OIDC\_ISSUER=http\://localhost:8081/realms/realm\_\${MSSV}  
\# JWKS lấy qua tên service nội bộ  
OIDC\_JWKS\_URL=http\://authentication-identity-server:8080/realms/realm\_\${MSSV}/protocol/openid-connect/certs  
OIDC\_AUDIENCE=flask-app  
GF\_SECURITY\_ADMIN\_USER=admin  
GF\_SECURITY\_ADMIN\_PASSWORD=change\_me\_grafana

* Realm đặt theo MSSV: nhóm **thống nhất một MSSV** (thường của người nộp báo cáo), ghi rõ trong báo cáo; nên hỏi giảng viên nếu muốn mỗi người một realm.

* Keycloak bản mới dùng KC\_BOOTSTRAP\_ADMIN\_USERNAME/PASSWORD; trong compose ánh xạ từ \${KEYCLOAK\_ADMIN} và \${KEYCLOAK\_ADMIN\_PASSWORD}.

* Không publish MariaDB, Prometheus, Keycloak, MinIO ra Internet nếu không cần cho demo; trên EC2 giới hạn nguồn truy cập (Mục 12).

# **6\. Quy tắc định tuyến của Gateway**

| Đường dẫn | Đích nội bộ | Quy tắc |
| :---- | :---- | :---- |
| / | upstream web\_pool | Round Robin giữa web-frontend-server:80 và web-frontend-server2:80; hai web trả nội dung nhận diện được (Server 1 / Server 2\) |
| /api/ | application-backend-server:8081/ | Bỏ tiền tố /api/ (/api/hello → /hello, /api/student → /student, /api/students-db → /students-db) |
| /auth/ | authentication-identity-server:8080/ | Đạt B9 khi trả 302\. Đăng nhập OIDC đầy đủ demo trực tiếp qua localhost:8081 (xem Mục 11\) |
| /student/ | application-backend-server:8081/student | Route của bài mở rộng E9; kiểm tra dấu / cuối để không ghép sai path |

Cổng 8080 (web) và 8085 (Flask) vẫn giữ để kiểm thử trực tiếp. Nếu cổng 80 trên máy bị chiếm thì dừng dịch vụ đó, không tự đổi cổng của gateway.

# **7\. Phân công chi tiết cho 3 thành viên**

## **Thành viên 1: Web, Flask API, MariaDB, Docker Hub**

**Sở hữu:** web-frontend-server/, application-backend-server/, relational-database-server/.

* **Web (B1, E1, E10):** trang chủ; blog 3 bài (blog1-3.html) có ảnh và link quay lại; blog/index.html và trang chủ liệt kê bài viết có hyperlink; cấu hình Nginx (alias có / cuối).

* **\[MỚI\]** **Web 2:** tạo html2/index.html ghi rõ “Server 2” (và trang chủ gốc ghi “Server 1”) để demo Round Robin.

* **\[MỚI\]** **\`/metrics\` cho Prometheus (E7):** thêm file tĩnh html/metrics (định dạng Prometheus, ví dụ web\_up 1) và location \= /metrics { default\_type text/plain; } trong conf.default.

* **Flask (B2, E2, E3, E4):** /hello; /student đọc students.json; **\[MỚI\]** /students-db đọc studentdb.students qua biến môi trường; **\[MỚI\]** /secure kiểm tra Bearer token theo OIDC\_ISSUER, OIDC\_JWKS\_URL, OIDC\_AUDIENCE.

* **Database (B3, E3):** minicloud.notes và studentdb.students (id, student\_id, fullname, dob, major) với dữ liệu mẫu qua 01-init.sql. **\[MỚI\]** Thêm GRANT ALL ON studentdb.\* TO 'minicloud\_user'@'%'; FLUSH PRIVILEGES;, vì user chỉ tự có quyền trên minicloud.

* **Docker Hub:** build và push ít nhất 1 image tùy chỉnh (ví dụ myminicloud-web) lên Docker Hub công khai, gửi link cho TV3 đưa vào phụ lục.

* **Bàn giao:** mã nguồn, Dockerfile, SQL, ảnh B1–B3, E1–E3, link Docker Hub.

## **TUẤN ANH: Keycloak, MinIO, Bind9, kiểm thử mạng, báo cáo phần mở đầu/kết luận, video**

**Sở hữu:** authentication-identity-server/, object-storage-server/, internal-dns-server/, scripts/.

* **Keycloak (B4, E4):** chạy start-dev; tạo realm realm\_\<MSSV\>, user sv01, sv02 (đặt mật khẩu, tắt “temporary”), client flask-app (public, bật Direct access grants để lấy token bằng curl). Lấy URL token endpoint.

* **\[MỚI\]** **Audience:** token của client public thường có aud=account; thêm **Audience mapper** (client scope riêng của flask-app, included client audience flask-app) để /secure kiểm tra audience đạt. Phối hợp TV1 chạy thử /secure đến khi trả 200\.

* **MinIO (B5, E5):** bucket demo (B5), profile-pics (upload avatar.jpg, đặt policy public và thử mở URL), documents (upload PDF báo cáo). Ghi cách tái tạo vào README-config.md.

* **Bind9 (B6, E6):** zone cloud.local; bản ghi A: web-frontend-server 10.10.10.10, app-backend 10.10.10.20, minio 10.10.10.30, keycloak 10.10.10.40. Restart container và kiểm tra lại bằng dig @127.0.0.1 \-p 1053 ….

* **\[MỚI\]** **Ping mạng (B10):** viết scripts/ping-test.sh chạy trong network cloud-net (ví dụ docker run \--rm \--network cloud-net busybox ping \-c 3 \<container\>) cho tất cả container; chụp kết quả.

* **\[MỚI\]** **Báo cáo:** viết Chương 1, Chương 5 và quay/dựng **video demo** (TV3 chuẩn bị môi trường và kịch bản theo Mục 4).

* **Bàn giao:** cấu hình Bind9, README-config.md, ping-test.sh, ảnh B4–B6, B10, E4–E6, video.

## **Trung Nguyên: Prometheus, Grafana, Gateway, tích hợp, AWS EC2**

**Sở hữu:** monitoring-prometheus-server/, monitoring-grafana-dashboard-server/, api-gateway-proxy-server/, docker-compose.yml, README.md.

* **Khởi tạo repo:** commit trước khung thư mục rỗng, .gitignore, .env.example, compose khung (để mọi người làm trên cùng một chuẩn).

* **Prometheus (B7, E7):** scrape node-exporter:9100 (job node) và web-frontend-server:80 (job web); target UP; truy vấn node\_cpu\_seconds\_total có dữ liệu.

* **Grafana (B8, E8):** datasource http\://monitoring-prometheus-server:9090 (**\[MỚI\]** đề mẫu ghi prometheus:9090 là sai tên). Import “Node Exporter Full” (B8); tạo dashboard System Health of \<MSSV\> đúng 3 biểu đồ dùng node\_cpu\_seconds\_total, node\_memory\_MemAvailable\_bytes, node\_network\_receive\_bytes\_total; export JSON vào dashboards/.

* **Gateway (B9, E9, E10):** route /, /api/, /auth/, /student/; upstream web\_pool Round Robin hai web.

* **Compose/tích hợp:** ghép service, kiểm tra port, network, volume, depends\_on, restart; chạy toàn hệ thống bằng docker compose up \-d; chạy lại toàn bộ Mục 4 sau mỗi lần merge.

* **AWS EC2:** deploy trên Ubuntu, kiểm tra qua Public IP, thiết lập Security Group theo Mục 12, chụp minh chứng.

* **Báo cáo:** Chương 2 (sơ đồ network, flow request), tổng hợp và định dạng file Word cuối, bảng “đã làm X/10 mục mở rộng”, log khởi động hệ thống cho phụ lục.

* **Bàn giao:** compose, cấu hình Prometheus/Grafana/Nginx, ảnh B7–B9, E7–E10, minh chứng EC2.

## **Cân bằng khối lượng**

| Thành viên | Kỹ thuật | Báo cáo | Khác |
| :---- | :---- | :---- | :---- |
| **TV1** | Web, Flask, DB, /metrics, web 2 | Chương 3 (phần của mình), Chương 4 (ảnh của mình) | Docker Hub |
| **Tuấn Anh** | Keycloak, MinIO, DNS, ping test | Chương 1, Chương 5, Chương 3–4 (phần của mình) | Video demo |
| **Trung Nguyên** | Prometheus, Grafana, Gateway, compose, EC2 | Chương 2, tổng hợp Word, Chương 3–4 (phần của mình) | Git, log, điều phối |

# **8\. Phân công soạn thảo Báo cáo cuối kỳ**

| Chương / phần | Nội dung | Phân công |
| :---- | :---- | :---- |
| Chương 1\. Giới thiệu & mục tiêu | Giải thích hệ thống 9 server, mô hình cloud mô phỏng | Tuấn Anh (nhận ý từ TV1, TV3) |
| Chương 2\. Kiến trúc & sơ đồ | Sơ đồ network cloud-net, flow request qua Gateway | TV3 |
| Chương 3\. Cấu hình & Dockerfile | Dockerfile, compose, SQL, DNS zone, Nginx conf, Keycloak/MinIO setup | Mỗi người viết phần việc của mình |
| Chương 4\. Demo & kiểm thử | Bảng kết quả 10 bài cơ bản \+ 10 bài mở rộng, ảnh minh chứng mỗi server (local và EC2) | Mỗi người chụp phần mình; TV3 ghép và viết bảng “đã làm X/10 mở rộng” |
| Chương 5\. Đánh giá & phân tích | Ưu điểm, khó khăn, hướng mở rộng | Tuấn Anh viết, cả nhóm bổ sung |
| Phụ lục | Link Docker Hub, link video demo, log kết quả | TV1 (Docker Hub), Tuấn Anh (video), TV3 (log, tổng hợp) |

**Chéo kiểm tra:** TV1 đọc lại phần của Tuấn Anh, Tuấn Anh đọc lại phần của TV3, TV3 đọc lại phần của TV1 trước khi chốt (đối chiếu số liệu, tên service, ảnh khớp lệnh).

# **9\. Quy trình làm việc, Git và bàn giao**

* TV3 tạo repo, commit khung (thư mục, .gitignore, .env.example, compose khung).

* Mỗi người chỉ làm trong thư mục của mình, trên nhánh riêng: feature/web-api-db (TV1), feature/auth-storage-dns (Tuấn Anh), feature/monitoring-gateway (TV3). Có thể thêm file trong thư mục mình nhưng không đổi tên thư mục gốc.

* Mỗi phần phải chạy thử độc lập đúng port nội bộ đã chốt trước khi tạo Pull Request.

* Khi tích hợp, TV3 ghép compose và gateway; chủ sở hữu service xác nhận biến môi trường, volume và lệnh chạy của phần mình.

* Chỉ merge vào main khi service chạy độc lập; sau mỗi merge chạy lại toàn bộ Mục 4 từ đầu.

* Thay đổi tên service, port nội bộ, endpoint, biến môi trường hay cấu trúc thư mục phải báo cả nhóm và cập nhật đồng thời mọi tài liệu liên quan.

* Mỗi phần bàn giao gồm: mã nguồn/cấu hình, cách chạy, lệnh kiểm thử, kết quả mong đợi, ảnh minh chứng.

# **10\. Mốc thời gian**

| Giai đoạn | Nội dung | Đầu ra | Hạn (điền) |
| :---- | :---- | :---- | :---- |
| 0 | Chốt chuẩn: MSSV cho realm, tên/port, .env.example; TV3 tạo repo và khung | Repo, compose khung | … |
| 1 | Làm độc lập: mỗi người chạy được service của mình | Ảnh minh chứng B/E của phần mình | … |
| 2 | Tích hợp local: ghép compose, gateway, chạy Mục 4 đủ 20 bài | Hệ thống docker compose up \-d chạy ổn | … |
| 3 | Deploy EC2, chụp minh chứng qua Public IP, quay video | Link video, ảnh EC2 | … |
| 4 | Viết báo cáo, chéo kiểm tra, push Docker Hub, chốt file nộp | Báo cáo Word, link Docker Hub | … |

# **11\. Rủi ro kỹ thuật đã biết và cách xử lý**

| Vấn đề | Cách xử lý | Chủ | Liên quan |
| :---- | :---- | :---- | :---- |
| Target web UP | Nginx mặc định trả 404 ở /metrics nên Prometheus ghi DOWN. Thêm file tĩnh metrics \+ location \= /metrics (Mục 7, TV1). | TV1 \+ TV3 | E7 |
| /secure trả 401 do issuer | Claim iss theo URL lấy token (http\://localhost:8081/...), không phải tên service nội bộ. Đặt OIDC\_ISSUER đúng giá trị iss, lấy JWKS qua OIDC\_JWKS\_URL. Trên EC2 phải lấy token qua http\://\<PublicIP\>:8081/... và đổi OIDC\_ISSUER tương ứng. | TV1 \+ Tuấn Anh | E4 |
| /secure trả 401 do audience | Thêm Audience mapper cho flask-app (Mục 7, Tuấn Anh). | Tuấn Anh | E4 |
| Flask không đọc được studentdb | Thêm GRANT trong 01-init.sql. Script init chỉ chạy khi volume DB còn trống; sửa script xong phải xóa volume của project rồi chạy lại. | TV1 | E3 |
| /auth/ qua gateway | Chỉ cần 302 cho B9. Muốn đăng nhập OIDC qua gateway phải đặt KC\_HOSTNAME, KC\_HTTP\_ENABLED=true, thường cần cả KC\_HTTP\_RELATIVE\_PATH=/auth. Nên demo OIDC trực tiếp qua cổng 8081\. | TV3 \+ Tuấn Anh | B9, E4 |
| DNS từ host | Phải chỉ cổng: dig @127.0.0.1 \-p 1053 \<tên\>. Trong network, container dùng cổng 53\. | Tuấn Anh | B6, E6 |
| Cổng 80 bị chiếm | Kiểm tra trước khi chạy compose; dừng dịch vụ đang chiếm. | TV3 | B9 |

# **12\. Triển khai AWS EC2**

* Security Group: mở 22 (SSH) và 80 (gateway) công khai theo nhu cầu demo; **\[MỚI\]** các cổng cần chụp minh chứng (8080 web, 3000 Grafana, 9090 Prometheus, 8081 Keycloak, 9001 MinIO Console) mở **chỉ cho IP của nhóm**, hoặc không mở và dùng SSH tunnel. Không mở 3306, 9000, 9100\.

* Test DNS (Bind9) chạy ngay trên instance: dig @127.0.0.1 \-p 1053 ….

* Dùng .env riêng trên EC2 (không copy từ Git); nhớ đổi OIDC\_ISSUER theo Public IP.

* Chạy lại toàn bộ Mục 4 qua Public IP (thay localhost) và chụp ảnh cho Chương 4\.

# **13\. Checklist nghiệm thu cuối cùng**

| Trạng thái | Tiêu chí |
| :---- | :---- |
| ☐ Chưa xong | Docker Compose khởi động toàn bộ, không container nào thoát bất thường (docker compose ps đều Running). |
| ☐ Chưa xong | Mọi service dùng chung cloud-net và gọi nhau bằng tên service; **ping mạng (B10) đạt**. |
| ☐ Chưa xong | B1–B9 đạt và có ảnh minh chứng (đúng mã tên file). |
| ☐ Chưa xong | E1: blog 3 bài có ảnh, link quay lại, danh sách trong index.html. |
| ☐ Chưa xong | E2, E3: /student (JSON) và /students-db (MariaDB) đúng, cả trực tiếp và qua /api/. |
| ☐ Chưa xong | E4: realm realm\_\<MSSV\>, sv01, sv02, client flask-app; token gọi /secure trả 200\. |
| ☐ Chưa xong | E5: profile-pics/avatar.jpg mở được bằng public URL; documents/ có PDF. |
| ☐ Chưa xong | E6: dig trả đúng 10.10.10.20 / .30 / .40 sau khi restart DNS. |
| ☐ Chưa xong | E7, E8: Prometheus targets UP (node \+ web); dashboard System Health of \<MSSV\> có 3 biểu đồ có dữ liệu. |
| ☐ Chưa xong | E9, E10: /student/ đúng; Round Robin hiển thị luân phiên Server 1 / Server 2\. |
| ☐ Chưa xong | Đã push ít nhất 1 image tùy chỉnh lên Docker Hub công khai. |
| ☐ Chưa xong | Chạy ổn trên AWS EC2 Ubuntu qua Public IP; Security Group giới hạn hợp lý. |
| ☐ Chưa xong | Báo cáo 5 chương \+ phụ lục (Docker Hub, video, log), có bảng “đã làm X/10 mục mở rộng”; video chất lượng tốt. |
| ☐ Chưa xong | .env, mật khẩu, access key không có trong Git. |


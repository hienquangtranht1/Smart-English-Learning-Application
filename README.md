📚 VN ES Demo - Ứng dụng Học Tiếng Anh Thông Minh
VN ES Demo là một ứng dụng di động được xây dựng bằng Flutter, thiết kế nhằm mục đích hỗ trợ người dùng học từ vựng và rèn luyện kỹ năng tiếng Anh một cách toàn diện. Ứng dụng kết hợp phương pháp học trực quan qua Flashcard, hệ thống bài tập phân cấp, cùng tính năng phát âm (Text-to-Speech) chuẩn xác.

🚀 Các tính năng nổi bật
Quản Lý Từ Vựng & Flashcard: * Cung cấp sẵn bộ dữ liệu từ vựng Anh - Việt phong phú (vocabulary_en_vi.json).

Cho phép người dùng tự thêm, chỉnh sửa, lưu trữ các từ vựng yêu thích (Favorites) hoặc khôi phục từ đã xóa (Thùng rác).

Học từ vựng trực quan thông qua giao diện Flashcard.

Hệ Thống Bài Tập (Quiz System):

Cung cấp các gói bài tập (Quiz Pack) được chia theo 3 cấp độ: Nhập môn, Trung cấp, và Nâng cao.

Chấm điểm, lưu lại lịch sử làm bài (History) để người dùng theo dõi sự tiến bộ.

Phát Âm Tiếng Anh (Text-to-Speech): Tích hợp thư viện flutter_tts giúp phát âm từ vựng chuẩn xác, hỗ trợ nâng cao kỹ năng nghe và nói.

Hệ Thống Xác Thực & Bảo Mật:

Đăng ký, đăng nhập và quản lý hồ sơ người dùng (Profile/User Management).

Tính năng lấy lại mật khẩu thông qua mã xác thực OTP gửi trực tiếp vào Email (sử dụng mailer).

Bảo vệ dữ liệu nhạy cảm thông qua flutter_secure_storage và flutter_dotenv.

Lưu trữ & Xuất Dữ Liệu: Lưu trữ dữ liệu học tập cục bộ với shared_preferences và hỗ trợ trích xuất, quản lý tệp dữ liệu cá nhân (path_provider).

🛠️ Công nghệ sử dụng
Framework: Flutter & Dart (SDK >=2.17.0 <3.0.0)

State Management: provider

Local Storage & Security: shared_preferences, flutter_secure_storage, flutter_dotenv

Networking & API: http

Core Libraries:

flutter_tts: Xử lý giọng nói.

mailer: Xử lý gửi email OTP tự động.

intl: Định dạng đa ngôn ngữ và thời gian.

📂 Cấu trúc thư mục cốt lõi
Plaintext
lib/
├── models/         # Chứa các Data Model (User, Vocab, Quiz, Registration...)
├── pages/          # Giao diện ứng dụng (Home, Flashcard, Quiz Level, Login, OTP...)
├── services/       # Xử lý logic nghiệp vụ (AuthService, EmailService, QuizLoader...)
└── main.dart       # Điểm bắt đầu (Entry point) của ứng dụng
assets/
├── data/           # Các file dữ liệu JSON (Từ vựng, Bài tập theo cấp độ)
├── images/         # Hình ảnh, logo
└── email.env       # Cấu hình môi trường (ẩn) cho dịch vụ Email
⚙️ Hướng dẫn cài đặt
Để chạy ứng dụng này trên môi trường local, bạn cần cài đặt sẵn Flutter SDK.

Clone repository này về máy:

Bash
git clone <đường-dẫn-repo-của-bạn>
Cài đặt các thư viện (Dependencies):

Bash
cd vn_es_demo
flutter pub get
Cấu hình môi trường:
Tạo tệp email.env trong thư mục gốc (hoặc thư mục assets theo cấu hình) và cung cấp các thông số SMTP để tính năng gửi Email OTP hoạt động bình thường.

Khởi chạy ứng dụng:

Bash
flutter run
🧑‍💻 Thông tin tác giả / Profile
Dự án: Ứng dụng Học Tiếng Anh (VN ES Demo)

Phát triển bởi: [Điền Tên/Username của bạn]

Mục tiêu dự án: Xây dựng giải pháp công nghệ giáo dục (EdTech) trên nền tảng di động, tối ưu hóa trải nghiệm tự học ngôn ngữ qua công cụ Flashcard và trắc nghiệm tương tác.

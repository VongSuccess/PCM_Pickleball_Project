# HỆ THỐNG QUẢN LÝ CLB PICKLEBALL "VỢT THỦ PHỐ NÚI" (PCM) - MOBILE EDITION

- **Bài kiểm tra 02 (Nâng cao - Mobile)**
- **Môn học:** Lập trình Mobile với Flutter
- **Giảng viên hướng dẫn:** Kiều Tuấn Dũng(kitudu)

---

## 📋 THÔNG TIN SINH VIÊN

- **Họ và tên:** NGUYỄN VỌNG
- **Mã số sinh viên:** 1771020761
- **Lớp:** CNTT 17-07
- **Đề tài:** Hệ thống quản lý CLB Pickleball "Vợt Thủ Phố Núi"
- **Mã đề tài:** PCM (Pickleball Club Management)

---

## 🏗️ CẤU TRÚC DỰ ÁN

Dự án được tổ chức thành 2 thư mục chính tại thư mục gốc:

```
MOBILE_FLUTTER_1771020761_NguyenVong/
├── PcmBackend/          # Backend API (ASP.NET Core Web API 8.0)
│   ├── Controllers/     # Các API Endpoints
│   ├── Data/            # Entity Framework Context & Seeder
│   ├── Models/          # DTOs & Models
│   ├── Hubs/            # SignalR Hub (Real-time)
│   └── appsettings.json # Cấu hình Database & Connection Strings
│
└── pcm_mobile/         # Mobile App (Flutter)
    ├── lib/
    │   ├── models/     # Data Models
    │   ├── providers/  # State Management (Provider)
    │   ├── screens/    # Màn hình UI
    │   ├── services/   # API Services (Dio)
    │   └── widgets/    # Reusable Widgets
    └── pubspec.yaml    # Dependencies
```

---

## 🚀 HƯỚNG DẪN CÀI ĐẶT & CHẠY DỰ ÁN

### 1. Backend (ASP.NET Core)

**Yêu cầu:** .NET SDK 8.0, SQL Server.

**Bước 1:** Cấu hình Connection String
Mở file `PcmBackend/appsettings.json` và cập nhật chuỗi kết nối `DefaultConnection` phù hợp với SQL Server của bạn (Server Name, User, Password).

**Bước 2:** Chạy Backend
Mở terminal tại thư mục `PcmBackend` và chạy lệnh:

```bash
cd PcmBackend
# Backend sẽ tự động apply migration và seed dữ liệu mẫu khi khởi động
dotnet run
```

- **API URL:** `http://localhost:5294`
- **Swagger Docs:** `http://localhost:5294/swagger`

**Dữ liệu mẫu (`DbSeeder.cs`):**
- **Admin:** `admin` / `Admin@123`
- **Member:** `member01` -> `member20` / `Member@123` (Đã được tự động đăng ký vào giải Winter Cup)

---

### 2. Mobile App (Flutter)

**Yêu cầu:** Flutter SDK 3.x, Android Studio (Emulator) hoặc thiết bị thật.

**Bước 1:** Cài đặt thư viện
Mở terminal tại thư mục `pcm_mobile`:

```bash
cd pcm_mobile
flutter pub get
```

**Bước 2:** Cấu hình API URL
Mở file `lib/services/api_service.dart`. Kiểm tra `baseUrl` phù hợp với môi trường chạy:

- **Android Emulator:** Sử dụng `http://10.0.2.2:5294/api` (Mặc định)
- **iOS Simulator:** Sử dụng `http://localhost:5294/api`
- **Thiết bị thật:** Sử dụng IP LAN của máy tính (VD: `http://192.168.1.10:5294/api`)

**Bước 3:** Chạy ứng dụng

```bash
flutter run
```

---

## 🎯 TÍNH NĂNG ĐÃ TRIỂN KHAI

### 1. Xác thực & Phân quyền (Authentication) 🔐
- Đăng nhập, Đăng ký thành viên.
- Phân quyền theo vai trò: **Admin, Member**.
- Tự động lưu phiên đăng nhập (Token).

### 2. Quản lý Ví & Thanh toán (Wallet) 💰
- Xem số dư ví hiện tại.
- **Nạp tiền:** Gửi yêu cầu nạp tiền (Demo luồng duyệt nạp của Admin).
- **Thanh toán:** Tự động trừ tiền khi Đăng ký giải đấu hoặc Đặt sân.
- **Tích hợp:** Cổng thanh toán **VNPay** (Môi trường Sandbox).

### 3. Đặt sân (Booking) 📅
- Xem lịch sân trống/bận trực quan.
- Đặt sân nhanh chóng (Trừ tiền ví ngay lập tức).
- Ngăn chặn đặt trùng lịch.

### 4. Giải đấu (Tournaments) 🏆
- Xem danh sách giải đấu (Đang mở, Đã kết thúc).
- **Đăng ký tham gia:** Trừ phí tham gia (Entry Fee) từ ví.
- **Cây thi đấu (Bracket):**
    - Hiển thị lịch thi đấu chi tiết, rõ ràng ngày giờ.
    - Hỗ trợ thể thức **Hybrid** (Vòng bảng + Knockout).
    - **Tự động xếp lịch (Auto-Scheduler):** Hệ thống tự động bốc thăm chia bảng/cặp đấu ngẫu nhiên.
- **Lịch sử đấu:** Xem lại các trận đấu của bản thân trong phần Hồ sơ.

### 5. Hồ sơ cá nhân (Profile) 👤
- Xem thông tin hạng thành viên (Tier), điểm DUPR.
- Lịch sử giao dịch ví.
- **Lịch sử đấu:** Danh sách các trận đấu (Duels & Tournament) đã tham gia.

### 6. Real-time (SignalR) ⚡
- Cập nhật trạng thái đặt sân tức thời.
- Thông báo (Notifications) thời gian thực.

---

## 📸 MỘT SỐ HÌNH ẢNH DEMO

*(Có thể thêm ảnh chụp màn hình ứng dụng tại đây nếu cần)*

---

## ⚠️ LƯU Ý KHI CHẤM BÀI

1. Đảm bảo **Backend** đang chạy trước khi mở App.
2. Nếu chạy trên **Android Emulator**, hãy chắc chắn API URL là `10.0.2.2`.
3. Tài khoản **admin** có quyền quản lý giải đấu (Tạo lịch, duyệt nạp tiền).
4. Tài khoản **member01** là hội viên mẫu có sẵn tiền trong ví để test đặt sân/đăng ký giải.

---
*Cảm ơn Thầy Cô đã xem xét bài làm!*

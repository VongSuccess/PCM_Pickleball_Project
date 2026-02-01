## Giải quyết lỗi kết nối đăng nhập (CORS/Mixed Content)

### 1. Cấu hình Frontend (Flutter)
- Cập nhật [api_service.dart](file:///d:/MOBILE_FLUTTER_1771020761_NGUYEN-VONG/pcm_mobile/lib/services/api_service.dart) để hỗ trợ cấu hình Base URL linh hoạt.
- Sửa lỗi IP cứng `10.0.2.2` trong [auth_provider.dart](file:///d:/MOBILE_FLUTTER_1771020761_NGUYEN-VONG/pcm_mobile/lib/providers/auth_provider.dart) tại hàm `register`.
- Cải thiện thông báo lỗi tại `login` để người dùng dễ hiểu hơn.

### 2. Kiểm tra Backend (.NET)
- Xác nhận cấu hình Kestrel trong [appsettings.json](file:///d:/MOBILE_FLUTTER_1771020761_NGUYEN-VONG/PcmBackend/appsettings.json) đã mở cho `0.0.0.0:5266`.
- Đảm bảo thứ tự Middleware CORS trong [Program.cs](file:///d:/MOBILE_FLUTTER_1771020761_NGUYEN-VONG/PcmBackend/Program.cs) là tối ưu.

### 3. Hướng dẫn vận hành
- Đề xuất người dùng kiểm tra Firewall trên VPS để mở port 5266.
- Lưu ý về việc sử dụng HTTPS nếu chạy trên môi trường Web Production.
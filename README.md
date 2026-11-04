# 🥗 Ăn Lành - Application Mockup

Frontend mockup ứng dụng Flutter quét và đánh giá thực phẩm theo hồ sơ ăn uống cá nhân.

## 📖 Hướng dẫn nhanh

- Xem tài liệu hướng dẫn cài đặt và chạy demo chi tiết từng bước tại: **[GUIDE.md](./GUIDE.md)**

## 🚀 Chạy nhanh ứng dụng

1. Mở dự án bằng **Android Studio** có cài đặt Flutter Plugin.
2. Chạy `flutter pub get` trong Terminal.
3. Chạy ứng dụng trên trình duyệt Chrome hoặc Emulator:
   ```bash
   flutter run -d chrome
   ```

## 📱 Các tính năng chính trong bản Mockup

- **Hồ sơ ăn uống cá nhân**: Tùy chỉnh dị ứng, ngưỡng hạn chế đường/muối, chế độ ăn, mục tiêu dinh dưỡng và **khung nhập ghi chú AI**.
- **Quét mã vạch & Bảng thành phần**: Giao diện quét camera với chế độ dự phòng quét bảng thành phần OCR khi mã vạch không khả dụng.
- **Đánh giá & Giải thích**: Đánh giá *"Phù hợp"*, *"Cần cân nhắc"*, *"Không phù hợp"*, *"Chưa đủ dữ liệu"* kèm màn hình giải thích tiêu chí chi tiết.
- **Gợi ý sản phẩm phù hợp hơn (AI/Rule)**: Tự động đề xuất sản phẩm tốt hơn dựa trên hồ sơ cá nhân.
- **So sánh hai sản phẩm**: Đặt 2 nhãn cạnh nhau đối chiếu các chỉ số dinh dưỡng và cảnh báo dị ứng.
- **Lịch sử đánh giá**: Lưu vết lịch sử theo ngày kèm bộ lọc kết quả.

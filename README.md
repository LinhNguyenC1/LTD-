# 🥗 Ăn Lành - Application Mockup

Frontend mockup ứng dụng Flutter quét và đánh giá thực phẩm theo hồ sơ ăn uống cá nhân.

## 📖 Tài liệu hướng dẫn & Thiết kế

- **[GUIDE.md](./GUIDE.md)**: Hướng dẫn chi tiết cài đặt, clone và chạy demo dự án.
- **[FIGMA_PROTOTYPE_GUIDE.md](./FIGMA_PROTOTYPE_GUIDE.md)**: Hướng dẫn sơ đồ Frames, Components & Nối Prototype trên Figma.

## 🚀 Chạy nhanh ứng dụng

1. Mở dự án bằng **Android Studio** có cài đặt Flutter Plugin.
2. Chạy `flutter pub get` trong Terminal.
3. Chạy ứng dụng trên trình duyệt Chrome hoặc Emulator:
   ```bash
   flutter run -d chrome
   ```

## 📱 Các tính năng chính trong bản Mockup

- **Hồ sơ ăn uống cá nhân**: Tùy chỉnh Tên xưng hô, Đồng bộ 1-chạm, Dị ứng, Ngưỡng hạn chế đường/muối, Chế độ ăn, Mục tiêu dinh dưỡng và **khung nhập ghi chú AI**.
- **Quét mã vạch & Bảng thành phần**: Giao diện quét camera với chế độ dự phòng quét bảng thành phần OCR khi mã vạch không khả dụng.
- **Đánh giá & Giải thích**: Đánh giá *"Phù hợp"*, *"Cần cân nhắc"*, *"Không phù hợp"*, *"Chưa đủ dữ liệu"* kèm phân tích **AI Match Score**, **Ưu/Nhược điểm** và **Hỏi đáp AI**.
- **Gợi ý sản phẩm phù hợp hơn (AI/Rule)**: Tự động đề xuất sản phẩm tốt hơn dựa trên hồ sơ cá nhân.
- **So sánh hai sản phẩm**: Đặt 2 nhãn cạnh nhau đối chiếu các chỉ số dinh dưỡng và cảnh báo dị ứng.
- **Lịch sử đánh giá**: Lưu vết lịch sử theo ngày kèm bộ lọc kết quả.

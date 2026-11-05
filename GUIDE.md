# 🚀 Hướng Dẫn Cài Đặt & Chạy Demo Dự Án "Ăn Lành"

Tài liệu này hướng dẫn chi tiết từng bước cho thành viên mới (hoặc người đánh giá) để clone dự án **Ăn Lành** từ GitHub về Android Studio và khởi chạy bản demo mockup frontend.

---

## 📋 1. Yêu Cầu Tiền Đề (Prerequisites)

Trước khi bắt đầu, hãy đảm bảo máy tính của bạn đã cài đặt các công cụ sau:
- **Git**: [Tải về Git](https://git-scm.com/) (Kiểm tra bằng lệnh `git --version`).
- **Flutter SDK**: [Tải về Flutter SDK](https://docs.flutter.dev/get-started/install) (Phiên bản `≥ 3.3.0`).
- **Android Studio**: Tải và cài đặt plugin **Flutter** & **Dart** bằng cách:
  - Mở Android Studio ➔ `Settings` (Preferences) ➔ `Plugins` ➔ Tìm `Flutter` ➔ Bấm `Install`.

---

## 📥 2. Hướng Dẫn Clone (Tải) Dự Án Về Máy

### Cách A: Dùng giao diện Android Studio (Khuyên dùng)
1. Mở **Android Studio**.
2. Chọn **Get from VCS** (hoặc `File` ➔ `New` ➔ `Project from Version Control...`).
3. Tại ô **URL**, dán liên kết repository:
   ```text
   https://github.com/LinhNguyenC1/LTD-.git
   ```
   *(hoặc SSH: `git@github.com:LinhNguyenC1/LTD-.git`)*.
4. Chọn đường dẫn thư mục lưu trên máy tính ở ô **Directory**.
5. Nhấn **Clone** và đợi Android Studio tải dự án về.

### Cách B: Dùng Terminal / Command Prompt
```bash
git clone https://github.com/LinhNguyenC1/LTD-.git
cd LTD-
```
Sau đó mở Android Studio ➔ chọn **Open** ➔ chọn thư mục `LTD-`.

---

## 📦 3. Cài Đặt Thư Viện (`flutter pub get`)

1. Khi dự án được mở, Android Studio sẽ tự động xuất hiện thanh thông báo ở trên cùng:
   > **`Flutter commands: 'pub get'`** ➔ Bấm chọn **`Pub get`**.
2. Nếu không thấy thanh thông báo, mở tab **Terminal** ở góc dưới Android Studio và gõ:
   ```bash
   flutter pub get
   ```

---

## 📱 4. Khởi Chạy Demo Ứng Dụng

### Cách A: Chạy từ thanh công cụ Android Studio
1. Quan sát thanh công cụ ở phía trên cùng (bên cạnh nút ▶️ **Run**).
2. Nhấn vào danh sách thiết bị (Target Device Dropdown) và chọn một thiết bị:
   - 🌐 **Chrome (web)**: Chạy mượt mà và nhanh nhất trên trình duyệt Web.
   - 📱 **Android Emulator (Pixel 7)**: Chạy trên máy ảo điện thoại Android.
   - 💻 **macOS / Windows (desktop)**: Chạy ứng dụng dưới dạng Desktop.
3. Bấm nút màu xanh lá ▶️ **Run** (hoặc bấm `Shift + F10` / `Control + R` trên Mac).

### Cách B: Chạy từ Terminal
```bash
# Chạy trên trình duyệt Chrome (Nhanh nhất)
flutter run -d chrome

# Chạy trên máy ảo Android
flutter run -d emulator
```

---

## 🧭 5. Hướng Dẫn Trải Nghiệm Các Chức Năng Demo Trên App

| Màn hình | Các tính năng nổi bật để test |
| :--- | :--- |
| **🏠 1. Trang chủ** | • Xem thẻ *"Hồ sơ đang áp dụng"* ➔ Bấm **Chỉnh sửa** để chuyển sang tab Hồ sơ.<br>• Thẻ **"Đặt hai nhãn cạnh nhau"** ➔ Chuyển đến màn hình so sánh.<br>• Thẻ **Đánh giá gần đây** ➔ Mở chi tiết sản phẩm. |
| **📷 2. Quét mã vạch & Quét bảng thành phần** | • Khung camera có hiệu ứng quét & nút **Bật đèn**.<br>• Bấm nút công tắc giả lập lỗi quét ➔ Kích hoạt thẻ đỏ *[Không quét được mã]* & nút **`[ 🔲 Quét bảng thành phần ]`** làm phương án dự phòng OCR.<br>• Bấm nút **Lỗi kết nối** hoặc **Không thấy** bên dưới để kiểm tra các màn hình thông báo sự cố. |
| **🔎 3. Chi tiết sản phẩm & Gợi ý AI** | • Xem thông tin Dị ứng, Dinh dưỡng (Đường, Muối), NOVA, Nutri-Score, Eco-Score.<br>• **Thẻ Gợi ý AI**: Tự động đề xuất sản phẩm phù hợp hơn (*Bánh yến mạch nguyên bản*) khi sản phẩm bị vi phạm dị ứng.<br>• Bấm **"Xem giải thích theo tiêu chí"** để xem phân tích chi tiết lý do. |
| **🔀 4. So sánh 2 sản phẩm** | • Chọn 2 sản phẩm bất kỳ trong danh sách.<br>• Màn hình đối chiếu song song các chỉ số có tô màu làm nổi bật khác biệt quyết định. |
| **⚙️ 5. Hồ sơ cá nhân & AI Prompt** | • Tùy chỉnh Dị ứng, Ngưỡng cá nhân đường/muối, Chế độ ăn (*Keto, Thuần chay...*), Mục tiêu dinh dưỡng.<br>• **Trải nghiệm ô nhập AI**: Nhập mô tả chi tiết sở thích vào ô **Ghi chú thêm (AI)**.<br>• Bấm **Lưu hồ sơ** hoặc **Xóa hồ sơ** (mở hộp thoại Popup xác nhận xóa). |

---

## 🗂 6. Cấu Trúc Mã Nguồn Dự Án

```text
lib/
├── core/                         # Cấu hình dùng chung
│   ├── models/                   # Data Models (Food, UserProfile...)
│   └── theme/                    # Bảng màu Ăn Lành & Style Material 3
├── features/                     # Chia theo tính năng UI
│   ├── compare/                  # Màn hình Chọn & Bảng so sánh 2 sản phẩm
│   ├── history/                  # Lịch sử đánh giá
│   ├── home/                     # Trang chủ
│   ├── product/                  # Chi tiết sản phẩm, Giải thích & Gợi ý AI
│   ├── profile/                  # Hồ sơ ăn uống cá nhân & Modal xác nhận
│   ├── scan/                     # Quét mã vạch, Quét bảng thành phần & Lỗi tra cứu
│   └── widgets/                  # Components tái sử dụng (StatusBadge, PackWidget)
└── main.dart                     # Entry point & Shell Navigation
```

---

## 🛠 7. Lệnh Git Cơ Bản Cho Thành Viên Mới

Khi bạn thực hiện chỉnh sửa code và muốn đưa lên GitHub:

```bash
# 1. Thêm tất cả thay đổi
git add .

# 2. Tạo commit kèm tin nhắn
git commit -m "Mô tả thay đổi của bạn"

# 3. Push lên branch main trên GitHub
git push origin main
```

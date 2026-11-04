# 🎨 Hướng Dẫn Đồng Bộ Thiết Kế & Prototype Trên Figma Với Mã Nguồn Dự Án "Ăn Lành"

Tài liệu này liệt kê chi tiết danh sách các **Frames (Màn hình)**, **Components**, **Nội dung Văn bản (Copywriting)** và **Sơ đồ Nối Prototype (Interactions)** để bạn đồng bộ file Figma dự án ([Link Figma](https://www.figma.com/design/qCm12mrtI1S7LtoiBubkB0/LTD%C4%90)) khớp 100% với mã nguồn Flutter hiện tại.

---

## 🎨 1. Bảng Màu & Typography Chuẩn (Design Tokens)

- **Primary Green (Xanh lá rừng)**: `#1E533B`
- **Canvas Background (Nền kem)**: `#F8F8F2`
- **Card Border (Viền thẻ nhạt)**: `#E0E6DF`
- **Ink Text (Chữ chính)**: `#1F3329`
- **Sub Text (Chữ phụ)**: `#6D7F77`
- **Result Status Badges**:
  - `Phù hợp`: Bg `#E4F1E5` | Text `#1E533B`
  - `Cần cân nhắc`: Bg `#FDF5E2` | Text `#8C600F`
  - `Không phù hợp`: Bg `#FCEAE6` | Text `#B23A2B`
  - `Chưa đủ dữ liệu`: Bg `#EAF0F6` | Text `#4A6075`

---

## 📱 2. Danh Sách Màn Hình Cần Có Trên Figma (Frames)

| STT | Tên Frame trên Figma | Mô tả & Thành phần chính |
| :---: | :--- | :--- |
| **1** | `01_Trang_Chu` | Header "Ăn Lành" + Lời chào *"Chào Linh, cùng đọc nhãn nhé! 👋"* + Thẻ Quét mã + Thẻ Hồ sơ đang áp dụng + Thẻ Đặt hai nhãn cạnh nhau + Thẻ Đánh giá gần đây. |
| **2** | `02_Quet_Barcode` | Khung ống kính camera + Thẻ *"Đưa mã vạch vào khung"* + Nút Bật đèn. |
| **3** | `03_Quet_Loi_Fallback` | Khung ống kính viền đỏ + Thẻ đỏ *[Không quét được mã]* + Nút **`[ 🔲 Quét bảng thành phần ]`**. |
| **4** | `04_Quet_Bang_Thanh_Phan` | Khung camera OCR + Thẻ *"Đưa bảng thành phần vào khung"*. |
| **5** | `05_Loi_Ket_Noi` | Icon Wifi gạch chéo + Tiêu đề *"Chưa kết nối được với nguồn dữ liệu"* + Nút **Thử tra cứu lại**. |
| **6** | `06_Khong_Tim_Thay` | Icon Hộp quà kính lúp + Tiêu đề *"Chưa tìm thấy sản phẩm này"* + Nút **Quét lại mã vạch**. |
| **7** | `07_Chi_Tiet_San_Pham` | Header thông tin sp + Thẻ Kết quả + Thẻ **`🤖 AI Score & Pros/Cons`** + Thẻ **`✨ Gợi ý sản phẩm phù hợp hơn`** + Các mục Thành phần, Dinh dưỡng, Thông tin bổ sung. |
| **8** | `08_Vi_Sao_Co_Ket_Qua` | Badge kết quả + 5 Thẻ tiêu chí dị ứng/đường/muối/NOVA + Thẻ **`💬 Hỏi AI thêm về sản phẩm này`** + Hộp thoại Trợ lý AI. |
| **9** | `09_Chon_San_Pham_So_Sanh` | Danh sách sản phẩm kèm Checkbox + Thẻ *"Đã chọn 2/2 sản phẩm"* + Nút **So sánh 2 sản phẩm**. |
| **10** | `10_Dat_Hai_Nhan_Canh_Nhau` | 2 Thẻ bao bì sp + Thẻ *Khác biệt quyết định* + Bảng so sánh đối chiếu 2 cột tô màu + Thẻ lý do + Nút **Đổi cặp sản phẩm**. |
| **11** | `11_Lich_Su_Danh_Gia` | Chips bộ lọc (*Tất cả, Không phù hợp, Chưa đủ dữ liệu*) + Phân nhóm ngày (*Hôm nay, Hôm qua*) + Nút **Chọn 2 sản phẩm để so sánh**. |
| **12** | `12_Ho_So_An_Uong` | Thẻ **Tên xưng hô & Đồng bộ** + Dị ứng + Ngưỡng hạn chế + Chế độ ăn + Mục tiêu + Ô **Ghi chú thêm (AI)** + Nút **Lưu hồ sơ** / **Xóa hồ sơ**. |
| **13** | `13_Modal_Xac_Nhan_Xoa` | Dialog Popup xác nhận *"Xóa hồ sơ ăn uống?"* + Nút **Giữ hồ sơ** / **Xóa hồ sơ**. |

---

## 🔗 3. Sơ Đồ Nối Prototype (Interactions & Flow)

Để tạo prototype chạy tương tác mượt mà trên Figma, bạn nối các liên kết (**Interaction: On click ➔ Navigate to**) theo sơ đồ sau:

```text
[01_Trang_Chu]
  ├── On Click "Quét mã vạch" ───────────────► [02_Quet_Barcode]
  ├── On Click "Chỉnh sửa hồ sơ" ─────────────► [12_Ho_So_An_Uong]
  ├── On Click "Đặt hai nhãn cạnh nhau" ──────► [09_Chon_San_Pham_So_Sanh]
  └── On Click thẻ sp "Bánh yến mạch cacao" ──► [07_Chi_Tiet_San_Pham]

[02_Quet_Barcode]
  ├── On Click "Chuyển chế độ lỗi" ───────────► [03_Quet_Loi_Fallback]
  ├── On Click "Lỗi kết nối" ────────────────► [05_Loi_Ket_Noi]
  └── On Click "Xem sản phẩm mẫu" ───────────► [07_Chi_Tiet_San_Pham]

[03_Quet_Loi_Fallback]
  └── On Click "Quét bảng thành phần" ────────► [04_Quet_Bang_Thanh_Phan]

[07_Chi_Tiet_San_Pham]
  ├── On Click "Xem giải thích theo tiêu chí" ─► [08_Vi_Sao_Co_Ket_Qua]
  ├── On Click thẻ "Gợi ý sản phẩm phù hợp" ──► [07_Chi_Tiet_San_Pham] (Sp An Mộc)
  └── On Click "Chọn 2 sản phẩm để so sánh" ──► [09_Chon_San_Pham_So_Sanh]

[09_Chon_San_Pham_So_Sanh]
  └── On Click "So sánh 2 sản phẩm" ──────────► [10_Dat_Hai_Nhan_Canh_Nhau]

[12_Ho_So_An_Uong]
  └── On Click "Xóa hồ sơ" ──────────────────► [13_Modal_Xac_Nhan_Xoa] (Open Overlay)
```

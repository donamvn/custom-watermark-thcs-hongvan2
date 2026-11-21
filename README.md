# Custom Watermark — THCS Hồng Vân 2, PH Duyên Thái

Thay thế dòng chữ mặc định `Activate Windows` ở góc phải dưới màn hình bằng dòng chữ tùy chỉnh:
- **Dòng 1:** `🏫 THCS Hồng Vân 2, PH Duyên Thái ✨`
- **Dòng 2:** `💻 Bộ môn Tin học 🌸`

> **An toàn:** Không can thiệp vào dịch vụ bản quyền (`sppsvc`), Registry hay file hệ thống. Không cần quyền Administrator.

---

## Cài đặt nhanh bằng 1 lệnh (từ GitHub)

Mở **PowerShell** (nhấn `Win + X` -> chọn **Terminal** hoặc **Windows PowerShell**) rồi dán lệnh sau và nhấn **Enter**:

```powershell
irm https://raw.githubusercontent.com/donamvn/custom-watermark-thcs-hongvan2/main/install.ps1 | iex
```

Lệnh này sẽ tự động:
1. Tải `CustomWatermark.ps1` vào `%LOCALAPPDATA%\CustomWatermark\`.
2. Cài đặt tự khởi động cùng Windows trong thư mục `Startup`.
3. Hiển thị watermark mới ngay lập tức.

---

## Gỡ bỏ & khôi phục chữ "Activate Windows" gốc bằng 1 lệnh

```powershell
irm https://raw.githubusercontent.com/donamvn/custom-watermark-thcs-hongvan2/main/uninstall.ps1 | iex
```

---

## Cách dùng offline (không cần mạng)

Tải mã nguồn dạng ZIP từ GitHub, giải nén và nhấp đúp:
- `1_CaiDat_Va_Chay.cmd` — Cài đặt tự khởi động và chạy ngay.
- `2_Chay_Thu_Khong_CaiDat.cmd` — Chạy thử, không cài tự khởi động.
- `3_GoBo_KhoiPhuc_Goc.cmd` — Gỡ bỏ và khôi phục gốc.
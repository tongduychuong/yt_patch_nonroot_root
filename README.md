```markdown
# 🚀 YouTube Morphe Auto-Builder (Root Mount & Non-Root)

Một quy trình tự động hóa mạnh mẽ dựa trên **GitHub Actions** giúp tự động kiểm tra, tải ứng dụng và build bản **YouTube Morphe** (Patch mới nhất) dưới dạng **Magisk/KernelSU/APatch Module** (Root Mount) và file **APK chuẩn**.
---
## ✨ Tính Năng Nổi Bật

* **🤖 Tự động hoàn toàn (Automated Schedule):** Tự động chạy mỗi ngày để kiểm tra bản Patch mới nhất từ `MorpheApp/morphe-patches`.
* **⚡ Hỗ trợ song song 2 phiên bản:** Build cả bản **Stable** (Ổn định) và bản **Dev** (Thử nghiệm) cùng lúc.

## 🚀 Cách Sử Dụng

### 1. Chạy tự động (Automatic)

Workflow sẽ tự động kích hoạt vào lúc **23:00 giờ Việt Nam (16:00 UTC)** hàng ngày. Nếu phát hiện có Patch mới từ MorpheApp, hệ thống sẽ tiến hành build và tạo Release mới.

### 2. Ép Build thủ công (Manual Trigger)

1. Truy cập tab **Actions** trên GitHub.
2. Chọn workflow **Check & Auto Build Root Mount YouTube**.
3. Bấm **Run workflow**.
4. Tích chọn **"Ép Build thủ công (bỏ qua kiểm tra Patch)"** nếu muốn kích hoạt build ngay lập tức kể cả khi không có patch mới.

---

## 📲 Cài Đặt Ứng Dụng

Sau khi build thành công, vào mục **Releases** để tải file tương ứng:

* **Bản Root (Magisk/KernelSU/APatch):** Tải file `.zip` (ví dụ: `youtube_root_mount_x.x.x_Magisk.zip`) -> Flashing qua ứng dụng Magisk / KernelSU / APatch -> Khởi động lại máy.


* **Bản Non-Root (APK thông thường):** Tải file `.apk` -> Yêu cầu cài đặt thêm [MicroG-RE](https://github.com/MorpheApp/MicroG-RE/releases) để đăng nhập tài khoản Google.

---

## 💖 Lời Cảm Ơn (Credits)

* [MorpheApp](https://github.com/MorpheApp) - Dự án cung cấp Morphe CLI & Patches.


* [j-hc/revanced-magisk-module](https://github.com/j-hc/revanced-magisk-module) - Cấu trúc script đóng gói Root Mount Module.

```

```

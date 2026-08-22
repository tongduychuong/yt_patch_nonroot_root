# 🚀 YouTube Morphe Root Mount - Auto Builder

Kho lưu trữ này sử dụng **GitHub Actions** để tự động kiểm tra bản vá mới nhất từ [Morphe Patches](https://github.com/MorpheApp/morphe-patches), tải xuống phiên bản YouTube tương ứng, và đóng gói thành **Magisk/KernelSU Root Mount Module** cùng file APK hoàn chỉnh.

## 📥 Tải xuống & Hướng dẫn cài đặt

Bạn có thể tải trực tiếp các bản build mới nhất tại mục **[Releases](https://github.com/tongduychuong/yt_patch_nonroot_root/releases)** của kho lưu trữ.

### 1. Bản Root Mount (Khuyên dùng cho máy đã Root)
* **File tải**: `youtube_root_mount_<version>_Magisk.zip` hoặc `youtube_dev_root_mount_<version>_Magisk.zip`
* **Cách cài đặt**: Flash trực tiếp qua **Magisk** hoặc **KernelSU**, sau đó khởi động lại thiết bị.

### 2. Bản APK đơn lẻ (Dành cho máy Non-Root)
* **File tải**: `youtube_<version>.apk` hoặc `youtube_dev_<version>.apk`
* **Yêu cầu quan trọng (MicroG)**: Do ứng dụng yêu cầu dịch vụ Google để đăng nhập tài khoản, bạn **bắt buộc phải cài đặt MicroG** trước khi cài đặt APK:
  1. Tải và cài đặt **[MicroG-RE (MicroG Companion)](https://github.com/MorpheApp/MicroG-RE/releases)** phiên bản mới nhất.
  2. Mở MicroG và cấp quyền cần thiết, sau đó đăng nhập tài khoản Google của bạn.
  3. Cài đặt file `youtube_<version>.apk` đã tải từ mục Releases và sử dụng bình thường.

## 💡 Lời cảm ơn & Nguồn tham khảo
* Dự án lấy cảm hứng từ phương pháp build và cấu trúc mã nguồn của **[j-hc](https://github.com/j-hc)**.
* Sử dụng công cụ patch từ **[MorpheApp](https://github.com/MorpheApp)**.

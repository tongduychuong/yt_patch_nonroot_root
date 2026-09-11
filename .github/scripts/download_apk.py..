import sys
import os
import zipfile
from playwright.sync_api import sync_playwright

# Kiểm tra tham số truyền vào
if len(sys.argv) < 3:
    print("Sử dụng: python script.py <target_version> <output_filename>")
    sys.exit(1)

target_version = sys.argv[1].strip()
output_filename = sys.argv[2].strip()
sharing_url = "http://gofile.me/7XfX5/BItYeE5hl"

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    context = browser.new_context(accept_downloads=True)
    page = context.new_page()

    print(f"Đang truy cập: {sharing_url}")
    page.goto(sharing_url, wait_until="networkidle", timeout=60000)
    
    # Chờ trang load danh sách file
    try:
        page.wait_for_selector("body", timeout=15000)
        page.wait_for_timeout(2000) # Chờ thêm chút để UI render hoàn tất
    except Exception as e:
        print(f"Lỗi khi chờ trang tải: {e}")
        sys.exit(1)

    target_selector = f"text=/{target_version}.*\\.apk/i"
    general_apk_selector = "text=/.*\\.apk$/i"

    file_item = None
    if page.locator(target_selector).count() > 0:
        file_item = page.locator(target_selector).first
        print(f"Đã tìm thấy phiên bản khớp: {target_version}")
    elif page.locator(general_apk_selector).count() > 0:
        file_item = page.locator(general_apk_selector).first
        print("Không tìm thấy đúng phiên bản, chọn file APK thay thế đầu tiên.")
    else:
        print("Lỗi: Không tìm thấy bất kỳ file APK nào trên trang.")
        sys.exit(1)

    # Click chọn file trước
    file_item.click()
    page.wait_for_timeout(1000)

    # Danh sách selector tiếng Anh tối ưu cho nút Download trên Synology
    download_selectors = [
        "button:has-text('Download')",
        "span:has-text('Download')",
        "div:has-text('Download')",
        "a:has-text('Download')",
        "[role='button']:has-text('Download')",
        "[title*='Download']"
    ]

    download_btn = None
    for sel in download_selectors:
        locator = page.locator(sel).first
        try:
            if locator.count() > 0 and locator.is_visible():
                download_btn = locator
                print(f"Đã tìm thấy nút Download với selector: {sel}")
                break
        except Exception:
            continue

    # Thực hiện tải file
    try:
        with page.expect_download(timeout=120000) as download_info:
            if download_btn:
                download_btn.click()
            else:
                print("Không tìm thấy nút Download hiển thị, đang thử double-click vào file...")
                file_item.dblclick()
        
        download = download_info.value
        download.save_as(output_filename)
        print(f"Tải file thành công: {output_filename}")
    except Exception as e:
        print(f"Lỗi trong quá trình tải file: {e}")
        sys.exit(1)
        
    browser.close()

# Kiểm tra tính hợp lệ của file APK (dưới dạng zip)
if not os.path.exists(output_filename) or not zipfile.is_zipfile(output_filename):
    print("Lỗi: File tải về không tồn tại hoặc không phải là định dạng nén APK hợp lệ.")
    sys.exit(1)

print("Hoàn tất! File hợp lệ.")

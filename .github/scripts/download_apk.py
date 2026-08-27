import sys, os, zipfile
from playwright.sync_api import sync_playwright

target_version = sys.argv[1].strip()
output_filename = sys.argv[2].strip()
sharing_url = "http://gofile.me/7XfX5/BItYeE5hl"

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    context = browser.new_context(accept_downloads=True)
    page = context.new_page()

    print(f"Đang truy cập: {sharing_url}")
    page.goto(sharing_url, wait_until="networkidle", timeout=60000)
    
    # In ra tiêu đề trang để kiểm tra xem đã load được trang Synology chưa
    print(f"Tiêu đề trang: {page.title()}")
    
    # Chờ danh sách file xuất hiện (thay đổi selector tùy theo giao diện thực tế của Synology File Station)
    try:
        page.wait_for_selector(".file-list, tr, [role='row']", timeout=15000)
    except Exception as e:
        print(f"Không tìm thấy danh sách file trên trang: {e}")
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
        print("Không tìm thấy bất kỳ file APK nào trên trang.")
        sys.exit(1)

    # Click chọn file
    file_item.click()
    page.wait_for_timeout(1000)

    # Tìm nút download trên giao diện Synology
    download_selectors = [
        "button:has-text('Download')", 
        "button:has-text('Tải xuống')", 
        "button:has-text('Tải')",
        "[title*='Download']",
        "[title*='Tải xuống']"
    ]
    
    download_btn = None
    for sel in download_selectors:
        if page.locator(sel).is_visible():
            download_btn = page.locator(sel).first
            break

    try:
        with page.expect_download(timeout=120000) as download_info:
            if download_btn:
                download_btn.click()
            else:
                # Thử double click nếu không tìm thấy nút download nổi
                file_item.dblclick()
        
        download = download_info.value
        download.save_as(output_filename)
        print(f"Tải file thành công về: {output_filename}")
    except Exception as e:
        print(f"Lỗi trong quá trình chờ và tải file: {e}")
        sys.exit(1)
        
    browser.close()

# Kiểm tra file tải về
if os.path.exists(output_filename):
    file_size = os.path.getsize(output_filename)
    print(f"Kích thước file tải về: {file_size} bytes")

if not zipfile.is_zipfile(output_filename):
    print("Cảnh báo: File tải về không phải là định dạng nén hợp lệ (có thể file bị lỗi hoặc trang web trả về mã lỗi HTML).")
    sys.exit(1)
else:
    print("File hợp lệ!")

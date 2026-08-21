import sys, zipfile
from playwright.sync_api import sync_playwright

target_version = sys.argv[1].strip()
output_filename = sys.argv[2].strip()
sharing_url = "http://gofile.me/7XfX5/BItYeE5hl"

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    context = browser.new_context(accept_downloads=True)
    page = context.new_page()

    page.goto(sharing_url, wait_until="networkidle", timeout=60000)
    page.wait_for_selector("body", timeout=10000)

    target_selector = f"text=/{target_version}.*\\.apk/i"
    general_apk_selector = "text=/.*\\.apk$/i"

    file_item = None
    if page.locator(target_selector).count() > 0:
        file_item = page.locator(target_selector).first
    elif page.locator(general_apk_selector).count() > 0:
        file_item = page.locator(general_apk_selector).first
    else:
        sys.exit(1)

    file_item.click()
    page.wait_for_timeout(500)

    download_selectors = ["button:has-text('Download')", "button:has-text('Tải xuống')", "button:has-text('Tải')"]
    download_btn = next((page.locator(sel).first for sel in download_selectors if page.is_visible(sel)), None)

    with page.expect_download(timeout=120000) as download_info:
        if download_btn:
            download_btn.click()
        else:
            file_item.dblclick()

    download = download_info.value
    download.save_as(output_filename)
    browser.close()

if not zipfile.is_zipfile(output_filename):
    sys.exit(1)

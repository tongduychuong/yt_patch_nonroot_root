import os
import sys
import subprocess
import shutil
import urllib.parse

# Kiểm tra biến môi trường hoặc tham số VERSION
version = os.environ.get("VERSION")
if not version and len(sys.argv) > 1:
    version = sys.argv[1].strip()

if not version:
    print("ERROR: VERSION is missing")
    sys.exit(1)

BASE = "https://www.apkmirror.com"
V = version.replace(".", "-")
UA = "Mozilla/5.0 (Linux; Android 14; Mobile)"

def sleep(sec):
    import time
    time.sleep(sec)

def wget(url):
    try:
        result = subprocess.run(
            ["wget", "-q", "--max-redirect=10", "--timeout=60", "--tries=3", "-U", UA, url, "-O", "-"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
            errors="ignore",
            max_buffer=50 * 1024 * 1024
        )
        return result.stdout
    except Exception as e:
        return ""

def download(url, filename):
    subprocess.run([
        "wget", "-q", "--show-progress", "--max-redirect=10", "--timeout=180", 
        "--tries=5", "-U", UA, url, "-O", filename
    ], check=True)

def clean_url(url):
    return url.replace("&amp;", "&").replace("amp;", "")

def absolute_url(url, base):
    url = clean_url(url)
    if url.startswith("http://") or url.startswith("https://"):
        return url
    if url.startswith("//"):
        return "https:" + url
    return urllib.parse.urljoin(base, url)

def find_download_button(html):
    import re
    patterns = [
        r'downloadButton[\s\S]{0,2000}?href=["\']([^"\']+)["\']',
        r'<a[^>]*class=["\'][^"\']*downloadButton[^"']*["\'][^>]*href=["\']([^"\']+)["\']'
    ]
    for p in patterns:
        m = re.search(p, html, re.IGNORECASE)
        if m and m[1]:
            return clean_url(m[1])
    return None

def find_here(html):
    import re
    patterns = [
        r'href=["\']([^"\']+)["'][^>]*>\s*here\s*<',
        r'<a[^>]+href=["\']([^"\']+)["'][^>]*>\s*here\s*</a>',
        r'<a[^>]+href=["\']([^"\']+)["'][^>]*>[\s\S]{0,300}?here[\s\S]{0,300}?</a>'
    ]
    for p in patterns:
        m = re.search(p, html, re.IGNORECASE)
        if m and m[1]:
            return clean_url(m[1])
    return None

def check_file(filename):
    try:
        result = subprocess.run(["unzip", "-l", filename], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        out = result.stdout
        if "base.apk" in out:
            return "bundle"
        if "AndroidManifest.xml" in out:
            return "apk"
    except Exception:
        pass
    return "invalid"

def candidate(relative_path, number):
    page = f"{BASE}/apk/{relative_path}"
    temp = f"youtube-{number}.tmp"

    print("\n======================================")
    print(f"CANDIDATE {number}/4")
    print(page)
    print("======================================")

    try:
        html = wget(page)

        print("Waiting 15 seconds for downloadButton...")
        for i in range(15, 0, -1):
            sys.stdout.write(f"\rWaiting {i}s...")
            sys.stdout.flush()
            sleep(1)
        print("")

        button = find_download_button(html)
        retry = 0
        while not button and retry < 15:
            sleep(1)
            html = wget(page)
            button = find_download_button(html)
            retry += 1

        if not button:
            raise Exception("Không tìm thấy downloadButton")

        download_page = absolute_url(button, page)
        print("DOWNLOAD PAGE:")
        print(download_page)

        html2 = wget(download_page)

        print("Waiting 15 seconds for 'here'...")
        for i in range(15, 0, -1):
            sys.stdout.write(f"\rWaiting {i}s...")
            sys.stdout.flush()
            sleep(1)
        print("")

        real_url = find_here(html2)
        retry = 0
        while not real_url and retry < 15:
            sleep(1)
            html2 = wget(download_page)
            real_url = find_here(html2)
            retry += 1

        if not real_url:
            raise Exception("Không tìm thấy link here")

        real_url = absolute_url(real_url, download_page)

        print("REAL DOWNLOAD:")
        print(real_url)

        download(real_url, temp)

        file_type = check_file(temp)
        print("FILE TYPE:", file_type)

        if file_type == "bundle":
            print("Bundle detected - skip.")
            if os.path.exists(temp):
                os.remove(temp)
            return False

        if file_type != "apk":
            print("Invalid APK - skip.")
            if os.path.exists(temp):
                os.remove(temp)
            return False

        output = f"com.google.android.youtube-{version}-all.apk"
        if os.path.exists(output):
            os.remove(output)
        shutil.move(temp, output)

        print("NORMAL APK FOUND:", output)
        print("SIZE:", f"{(os.path.getsize(output) / 1024 / 1024):.2f}", "MB")
        return True

    except Exception as error:
        print(f"Candidate {number} failed: {error}")
        if os.path.exists(temp):
            os.remove(temp)
        return False

def main():
    candidates = [
        f"google-inc/youtube/youtube-{V}-release/youtube-{V}-2-android-apk-download/",
        f"google-inc/youtube/youtube-{V}-release/youtube-{V}-android-apk-download/",
        f"google-inc/youtube/youtube-{V}-release/youtube-{V}-3-android-apk-download/",
        f"google-inc/youtube/youtube-{V}-release/youtube-{V}-4-android-apk-download/"
    ]

    print("======================================")
    print("YouTube APKMirror Downloader (Python)")
    print("VERSION:", version)
    print("METHOD: wget")
    print("======================================")

    for i, path in enumerate(candidates):
        if candidate(path, i + 1):
            return

    raise Exception(f"Không tìm thấy NORMAL APK cho {version}")

if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print("\n======================================")
        print("ERROR:", error)
        print("======================================")
        sys.exit(1)

import os
import sys
import subprocess
import shutil
import urllib.parse
import time
import re


# ============================================================
# CONFIG
# ============================================================

version = os.environ.get("VERSION")

if not version and len(sys.argv) > 1:
    version = sys.argv[1].strip()

if not version:
    print("ERROR: VERSION is missing")
    sys.exit(1)

BASE = "https://www.apkmirror.com"
V = version.replace(".", "-")
UA = "Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 Chrome/140.0.0.0 Mobile Safari/537.36"


# ============================================================
# HELPERS
# ============================================================

def sleep(sec):
    time.sleep(sec)


def wget(url):
    """
    Download HTML page and return it as text.
    """
    try:
        result = subprocess.run(
            [
                "wget",
                "-q",
                "--max-redirect=10",
                "--timeout=60",
                "--tries=3",
                "-U",
                UA,
                url,
                "-O",
                "-"
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
            errors="ignore"
        )

        return result.stdout

    except Exception as e:
        print(f"wget error: {e}")
        return ""


def download(url, filename):
    """
    Download binary APK.
    """
    subprocess.run(
        [
            "wget",
            "-q",
            "--show-progress",
            "--max-redirect=10",
            "--timeout=180",
            "--tries=5",
            "-U",
            UA,
            url,
            "-O",
            filename
        ],
        check=True
    )


def clean_url(url):
    if not url:
        return url

    return (
        url
        .replace("&amp;", "&")
        .replace("amp;", "")
        .strip()
    )


def absolute_url(url, base):
    url = clean_url(url)

    if not url:
        return None

    if url.startswith("http://") or url.startswith("https://"):
        return url

    if url.startswith("//"):
        return "https:" + url

    return urllib.parse.urljoin(base, url)


# ============================================================
# APKMIRROR PARSERS
# ============================================================

def find_download_button(html):
    """
    Find APKMirror downloadButton URL.

    Fixed regex quoting issue that caused:
    SyntaxError: unexpected character after line continuation character
    """

    if not html:
        return None

    patterns = [
        r'downloadButton[\s\S]{0,2000}?href=["\']([^"\']+)["\']',

        r'<a[^>]*'
        r'class=["\'][^"\']*downloadButton[^"\']*["\']'
        r'[^>]*href=["\']([^"\']+)["\']',

        r'<a[^>]*'
        r'href=["\']([^"\']+)["\']'
        r'[^>]*class=["\'][^"\']*downloadButton[^"\']*["\']',
    ]

    for pattern in patterns:
        match = re.search(pattern, html, re.IGNORECASE)

        if match:
            url = match.group(1)

            if url:
                return clean_url(url)

    return None


def find_here(html):
    """
    Find final APKMirror 'here' download URL.
    """

    if not html:
        return None

    patterns = [
        r'href=["\']([^"\']+)["\'][^>]*>\s*here\s*<',

        r'<a[^>]+'
        r'href=["\']([^"\']+)["\']'
        r'[^>]*>\s*here\s*</a>',

        r'<a[^>]+'
        r'href=["\']([^"\']+)["\']'
        r'[^>]*>[\s\S]{0,300}?'
        r'\bhere\b'
        r'[\s\S]{0,300}?</a>',
    ]

    for pattern in patterns:
        match = re.search(pattern, html, re.IGNORECASE)

        if match:
            url = match.group(1)

            if url:
                return clean_url(url)

    return None


# ============================================================
# FILE VALIDATION
# ============================================================

def check_file(filename):
    """
    Detect whether downloaded file is:
      - normal APK
      - APK bundle / split package
      - invalid
    """

    if not os.path.exists(filename):
        return "invalid"

    try:
        result = subprocess.run(
            [
                "unzip",
                "-l",
                filename
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8",
            errors="ignore"
        )

        out = result.stdout

        if result.returncode != 0:
            return "invalid"

        # APK bundle / split package indicators
        if (
            "base.apk" in out
            or "splits/" in out
            or "split_config." in out
        ):
            return "bundle"

        # Normal APK
        if "AndroidManifest.xml" in out:
            return "apk"

    except Exception as e:
        print(f"File check error: {e}")

    return "invalid"


# ============================================================
# CANDIDATE PROCESSOR
# ============================================================

def candidate(relative_path, number):
    page = f"{BASE}/apk/{relative_path}"
    temp = f"youtube-{number}.tmp"

    print()
    print("======================================")
    print(f"CANDIDATE {number}/4")
    print(page)
    print("======================================")

    try:
        # ----------------------------------------------------
        # STEP 1: APKMirror version page
        # ----------------------------------------------------

        html = wget(page)

        if not html:
            raise Exception("Không tải được APKMirror page")

        print()
        print("Waiting 15 seconds for downloadButton...")

        for i in range(15, 0, -1):
            sys.stdout.write(f"\rWaiting {i}s...")
            sys.stdout.flush()
            sleep(1)

        print()

        # ----------------------------------------------------
        # STEP 2: Find download button
        # ----------------------------------------------------

        button = find_download_button(html)

        retry = 0

        while not button and retry < 15:
            retry += 1

            print(f"Retry downloadButton {retry}/15...")

            sleep(1)

            html = wget(page)

            button = find_download_button(html)

        if not button:
            raise Exception("Không tìm thấy downloadButton")

        download_page = absolute_url(button, page)

        if not download_page:
            raise Exception("Download page URL không hợp lệ")

        print()
        print("DOWNLOAD PAGE:")
        print(download_page)

        # ----------------------------------------------------
        # STEP 3: Download page
        # ----------------------------------------------------

        html2 = wget(download_page)

        if not html2:
            raise Exception("Không tải được download page")

        print()
        print("Waiting 15 seconds for 'here'...")

        for i in range(15, 0, -1):
            sys.stdout.write(f"\rWaiting {i}s...")
            sys.stdout.flush()
            sleep(1)

        print()

        # ----------------------------------------------------
        # STEP 4: Find final download URL
        # ----------------------------------------------------

        real_url = find_here(html2)

        retry = 0

        while not real_url and retry < 15:
            retry += 1

            print(f"Retry final URL {retry}/15...")

            sleep(1)

            html2 = wget(download_page)

            real_url = find_here(html2)

        if not real_url:
            raise Exception("Không tìm thấy link here")

        real_url = absolute_url(real_url, download_page)

        if not real_url:
            raise Exception("Final download URL không hợp lệ")

        print()
        print("REAL DOWNLOAD:")
        print(real_url)

        # ----------------------------------------------------
        # STEP 5: Download APK
        # ----------------------------------------------------

        if os.path.exists(temp):
            os.remove(temp)

        print()
        print("Downloading APK...")

        download(real_url, temp)

        # ----------------------------------------------------
        # STEP 6: Validate file
        # ----------------------------------------------------

        file_type = check_file(temp)

        print()
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

        # ----------------------------------------------------
        # STEP 7: Move final APK
        # ----------------------------------------------------

        output = f"com.google.android.youtube-{version}-all.apk"

        if os.path.exists(output):
            os.remove(output)

        shutil.move(temp, output)

        size_mb = os.path.getsize(output) / 1024 / 1024

        print()
        print("======================================")
        print("NORMAL APK FOUND")
        print("======================================")
        print("FILE:", output)
        print("SIZE:", f"{size_mb:.2f} MB")
        print()

        return True

    except Exception as error:

        print()
        print(f"Candidate {number} failed: {error}")

        if os.path.exists(temp):
            try:
                os.remove(temp)
            except Exception:
                pass

        return False


# ============================================================
# MAIN
# ============================================================

def main():

    candidates = [
        f"google-inc/youtube/youtube-{V}-release/"
        f"youtube-{V}-2-android-apk-download/",

        f"google-inc/youtube/youtube-{V}-release/"
        f"youtube-{V}-android-apk-download/",

        f"google-inc/youtube/youtube-{V}-release/"
        f"youtube-{V}-3-android-apk-download/",

        f"google-inc/youtube/youtube-{V}-release/"
        f"youtube-{V}-4-android-apk-download/",
    ]

    print("======================================")
    print("YouTube APKMirror Downloader")
    print("======================================")
    print("VERSION:", version)
    print("METHOD: wget")
    print("======================================")

    for i, path in enumerate(candidates, start=1):

        if candidate(path, i):
            return

    raise Exception(
        f"Không tìm thấy NORMAL APK cho {version}"
    )


# ============================================================
# ENTRY POINT
# ============================================================

if __name__ == "__main__":

    try:
        main()

    except KeyboardInterrupt:

        print()
        print("ERROR: Interrupted by user")
        sys.exit(130)

    except Exception as error:

        print()
        print("======================================")
        print("ERROR:", error)
        print("======================================")

        sys.exit(1)

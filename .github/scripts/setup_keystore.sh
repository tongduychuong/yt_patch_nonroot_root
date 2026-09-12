#!/usr/bin/env bash
set -e

# Cấu hình Git để commit file Keystore nếu cần
git config --global user.name "github-actions[bot]"
git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"

KEYSTORE_PATH="keys/keystore.jks"

if [ -n "$KEYSTORE_BASE64" ]; then
  echo "-> Dùng KeyStore từ GitHub Secret (KEYSTORE_BASE64)"
  echo "$KEYSTORE_BASE64" | base64 -d > release.jks
  echo "KS_PATH=release.jks" >> $GITHUB_ENV
  echo "KS_PASS=$KEYSTORE_PASSWORD" >> $GITHUB_ENV
  echo "KS_ALIAS=$KEY_ALIAS" >> $GITHUB_ENV
  echo "KS_KEY_PASS=$KEY_PASSWORD" >> $GITHUB_ENV
else
  # Kiểm tra xem file keystore đã có sẵn trong thư mục keys/ chưa
  if [ -f "$KEYSTORE_PATH" ]; then
    echo "-> Đã tìm thấy $KEYSTORE_PATH sẵn có trong repository!"
  else
    echo "-> Tạo thư mục keys/ và khởi tạo Keystore tự động mới (lần đầu tiên)..."
    mkdir -p keys
    keytool -genkeypair -v -keystore "$KEYSTORE_PATH" -alias autokey -keyalg RSA -keysize 2048 -validity 10000 -storepass 123456 -keypass 123456 -dname "CN=AutoBuilder, OU=Morphe, O=MorpheApp, L=City, S=State, C=US"
    
    echo "-> Commit và đẩy file $KEYSTORE_PATH lên repository..."
    git add "$KEYSTORE_PATH"
    git commit -m "chore: auto-generate signing keystore at keys/ [skip ci]" || echo "No changes to commit"
    
    # Push code lên branch hiện tại
    git push origin HEAD:${GITHUB_REF#refs/heads/} || echo "Push failed or already up-to-date"
  fi

  echo "KS_PATH=$KEYSTORE_PATH" >> $GITHUB_ENV
  echo "KS_PASS=123456" >> $GITHUB_ENV
  echo "KS_ALIAS=autokey" >> $GITHUB_ENV
  echo "KS_KEY_PASS=123456" >> $GITHUB_ENV
fi

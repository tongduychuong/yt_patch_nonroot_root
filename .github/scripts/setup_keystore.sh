#!/usr/bin/env bash
set -e

if [ -n "$KEYSTORE_BASE64" ]; then
  echo "-> Dùng KeyStore từ GitHub Secret (KEYSTORE_BASE64)"
  echo "$KEYSTORE_BASE64" | base64 -d > release.jks
  echo "KS_PATH=release.jks" >> $GITHUB_ENV
  echo "KS_PASS=$KEYSTORE_PASSWORD" >> $GITHUB_ENV
  echo "KS_ALIAS=$KEY_ALIAS" >> $GITHUB_ENV
  echo "KS_KEY_PASS=$KEY_PASSWORD" >> $GITHUB_ENV
else
  gh cache list --repo "$GITHUB_REPOSITORY" --key "autokey-keystore" --json key --jq '.[0].key' | grep -q "autokey-keystore" && IS_CACHED="true" || IS_CACHED="false"
  
  if [ "$IS_CACHED" == "true" ]; then
    echo "-> Khôi phục Keystore tự động từ GitHub Cache"
    gh cache download --repo "$GITHUB_REPOSITORY" --key "autokey-keystore" --dir /tmp/ks_cache || true
  fi

  if [ -f "/tmp/ks_cache/auto-release.jks" ]; then
    cp /tmp/ks_cache/auto-release.jks auto-release.jks
    echo "-> Đã khôi phục auto-release.jks thành công!"
  else
    echo "-> Tạo Keystore tự động mới (lần đầu tiên)..."
    keytool -genkeypair -v -keystore auto-release.jks -alias autokey -keyalg RSA -keysize 2048 -validity 10000 -storepass 123456 -keypass 123456 -dname "CN=AutoBuilder, OU=Morphe, O=MorpheApp, L=City, S=State, C=US"
    
    echo "-> Lưu Keystore vào GitHub Cache cho các lần build sau..."
    mkdir -p /tmp/ks_cache
    cp auto-release.jks /tmp/ks_cache/auto-release.jks
    gh cache delete "autokey-keystore" --repo "$GITHUB_REPOSITORY" || true
    gh cache upload --repo "$GITHUB_REPOSITORY" --key "autokey-keystore" /tmp/ks_cache/auto-release.jks || true
  fi

  echo "KS_PATH=auto-release.jks" >> $GITHUB_ENV
  echo "KS_PASS=123456" >> $GITHUB_ENV
  echo "KS_ALIAS=autokey" >> $GITHUB_ENV
  echo "KS_KEY_PASS=123456" >> $GITHUB_ENV
fi

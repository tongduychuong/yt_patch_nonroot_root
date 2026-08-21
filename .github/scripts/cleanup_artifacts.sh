#!/usr/bin/env bash
set -e

echo "-> Đang tiến hành xóa tất cả Artifacts của RunID: $GITHUB_RUN_ID..."
ARTIFACT_IDS=$(gh api "repos/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}/artifacts" --jq '.artifacts[].id')

if [ -n "$ARTIFACT_IDS" ]; then
  for ART_ID in $ARTIFACT_IDS; do
    echo "  + Đang xóa Artifact ID: $ART_ID"
    gh api -X DELETE "repos/${GITHUB_REPOSITORY}/actions/artifacts/$ART_ID" || true
  done
  echo "-> Đã xóa sạch toàn bộ Artifacts!"
else
  echo "-> Không tìm thấy Artifacts nào để xóa."
fi

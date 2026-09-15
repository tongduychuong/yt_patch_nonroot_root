#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Morphe Stable / Dev Patch Checker
#
# Repository releases:
#
#   stable-<youtube>-<timestamp>
#   dev-<youtube>-<timestamp>
#
# Stable chỉ kiểm tra stable-*
# Dev chỉ kiểm tra dev-*
#
# Patch version được lấy từ release body:
#
# Stable:
#   📌 **Stable Patch Version:** [TAG](...)
#
# Dev:
#   🧪 **Dev Patch Version:** [TAG](...)
# ============================================================

PATCH_REPO="MorpheApp/morphe-patches"
BUILD_REPO="${GITHUB_REPOSITORY}"

FORCE_BUILD="${FORCE_BUILD:-false}"

HAS_NEW_STABLE="false"
HAS_NEW_DEV="false"

echo
echo "============================================================"
echo "              MORPHE PATCH UPDATE CHECK"
echo "============================================================"
echo "Build repository : $BUILD_REPO"
echo "Patch repository : $PATCH_REPO"
echo "Force build      : $FORCE_BUILD"
echo "============================================================"
echo

# ============================================================
# Get latest Stable patch
# ============================================================

echo "[1] Finding latest Stable Morphe patch..."

LATEST_STABLE_TAG="$(
  gh api \
    "repos/${PATCH_REPO}/releases?per_page=100" \
    --paginate \
    --jq '
      .[]
      | select(.prerelease == false)
      | select(.draft == false)
      | .tag_name
    ' |
    head -n 1
)"

if [ -z "$LATEST_STABLE_TAG" ]; then
  echo "ERROR: Cannot find latest Stable patch."
  exit 1
fi

echo "Latest Stable Patch: $LATEST_STABLE_TAG"
echo

# ============================================================
# Get latest Dev patch
# ============================================================

echo "[2] Finding latest Dev Morphe patch..."

LATEST_DEV_TAG="$(
  gh api \
    "repos/${PATCH_REPO}/releases?per_page=100" \
    --paginate \
    --jq '
      .[]
      | select(.prerelease == true)
      | select(.draft == false)
      | .tag_name
    ' |
    head -n 1
)"

if [ -z "$LATEST_DEV_TAG" ]; then
  echo "WARNING: No prerelease Dev patch found."

  # Fallback:
  # Some repositories may not correctly mark Dev releases
  # as prerelease. Try to detect dev/beta/alpha tags.

  LATEST_DEV_TAG="$(
    gh api \
      "repos/${PATCH_REPO}/releases?per_page=100" \
      --paginate \
      --jq '
        .[]
        | select(.draft == false)
        | .tag_name
      ' |
      grep -Ei '(^|[-_.])(dev|beta|alpha|pre)([-_.]|$)' |
      head -n 1 || true
  )"
fi

if [ -n "$LATEST_DEV_TAG" ]; then
  echo "Latest Dev Patch: $LATEST_DEV_TAG"
else
  echo "Latest Dev Patch: NONE"
fi

echo

# ============================================================
# Get latest build release by prefix
# ============================================================

get_latest_release() {

  local PREFIX="$1"

  gh api \
    "repos/${BUILD_REPO}/releases?per_page=100" \
    --jq "
      [
        .[]
        | select(.draft == false)
        | select(.tag_name | startswith(\"${PREFIX}-\"))
      ]
      | sort_by(.published_at // .created_at)
      | reverse
      | .[0]
    " 2>/dev/null || echo "null"
}

# ============================================================
# Extract patch tag from release body
# ============================================================

extract_patch_tag() {

  local BODY="$1"

  echo "$BODY" |
    grep -E \
      '(Stable Patch Version|Dev Patch Version|Stable Patch|Dev Patch)' |
    grep -Eo '\[[^]]+\]' |
    head -n 1 |
    sed -E 's/^\[//; s/\]$//' ||
    true
}

# ============================================================
# CHECK STABLE
# ============================================================

echo "============================================================"
echo "CHECK STABLE"
echo "============================================================"

STABLE_RELEASE="$(
  get_latest_release "stable"
)"

if [ "$STABLE_RELEASE" = "null" ] || [ -z "$STABLE_RELEASE" ]; then

  echo "No stable-* release found."
  echo "=> BUILD STABLE"

  HAS_NEW_STABLE="true"

else

  STABLE_RELEASE_TAG="$(
    echo "$STABLE_RELEASE" |
      jq -r '.tag_name // empty'
  )"

  STABLE_RELEASE_BODY="$(
    echo "$STABLE_RELEASE" |
      jq -r '.body // empty'
  )"

  LAST_STABLE_PATCH="$(
    extract_patch_tag "$STABLE_RELEASE_BODY"
  )"

  echo "Latest Stable Release : $STABLE_RELEASE_TAG"
  echo "Built Stable Patch    : ${LAST_STABLE_PATCH:-UNKNOWN}"
  echo "Latest Morphe Patch   : $LATEST_STABLE_TAG"

  if [ "$LAST_STABLE_PATCH" = "$LATEST_STABLE_TAG" ]; then

    echo
    echo "=> Stable patch already built."
    echo "=> SKIP STABLE"

    HAS_NEW_STABLE="false"

  else

    echo
    echo "=> New Stable patch detected."
    echo "=> BUILD STABLE"

    HAS_NEW_STABLE="true"

  fi
fi

echo

# ============================================================
# CHECK DEV
# ============================================================

echo "============================================================"
echo "CHECK DEV"
echo "============================================================"

if [ -z "$LATEST_DEV_TAG" ]; then

  echo "No Dev patch found."
  echo "=> SKIP DEV"

  HAS_NEW_DEV="false"

else

  DEV_RELEASE="$(
    get_latest_release "dev"
  )"

  if [ "$DEV_RELEASE" = "null" ] || [ -z "$DEV_RELEASE" ]; then

    echo "No dev-* release found."
    echo "=> BUILD DEV"

    HAS_NEW_DEV="true"

  else

    DEV_RELEASE_TAG="$(
      echo "$DEV_RELEASE" |
        jq -r '.tag_name // empty'
    )"

    DEV_RELEASE_BODY="$(
      echo "$DEV_RELEASE" |
        jq -r '.body // empty'
    )"

    LAST_DEV_PATCH="$(
      extract_patch_tag "$DEV_RELEASE_BODY"
    )"

    echo "Latest Dev Release : $DEV_RELEASE_TAG"
    echo "Built Dev Patch    : ${LAST_DEV_PATCH:-UNKNOWN}"
    echo "Latest Morphe Patch: $LATEST_DEV_TAG"

    if [ "$LAST_DEV_PATCH" = "$LATEST_DEV_TAG" ]; then

      echo
      echo "=> Dev patch already built."
      echo "=> SKIP DEV"

      HAS_NEW_DEV="false"

    else

      echo
      echo "=> New Dev patch detected."
      echo "=> BUILD DEV"

      HAS_NEW_DEV="true"

    fi
  fi
fi

echo

# ============================================================
# FORCE BUILD
# ============================================================

if [ "$FORCE_BUILD" = "true" ]; then

  echo "============================================================"
  echo "FORCE BUILD ENABLED"
  echo "============================================================"
  echo "Ignoring patch check."
  echo "Stable => BUILD"
  echo "Dev    => BUILD"
  echo "============================================================"

  HAS_NEW_STABLE="true"
  HAS_NEW_DEV="true"
fi

# ============================================================
# SHOULD BUILD
# ============================================================

SHOULD_BUILD="false"

if [ "$HAS_NEW_STABLE" = "true" ] ||
   [ "$HAS_NEW_DEV" = "true" ]; then

  SHOULD_BUILD="true"

fi

# ============================================================
# SUMMARY
# ============================================================

echo
echo "============================================================"
echo "                    FINAL RESULT"
echo "============================================================"
echo
echo "Latest Stable Patch : $LATEST_STABLE_TAG"
echo "Latest Dev Patch    : ${LATEST_DEV_TAG:-NONE}"
echo
echo "Build Stable        : $HAS_NEW_STABLE"
echo "Build Dev           : $HAS_NEW_DEV"
echo "Should Build        : $SHOULD_BUILD"
echo
echo "============================================================"

# ============================================================
# GitHub Actions Outputs
# ============================================================

{
  echo "has_new_stable=$HAS_NEW_STABLE"
  echo "has_new_dev=$HAS_NEW_DEV"
  echo "latest_stable_tag=$LATEST_STABLE_TAG"
  echo "latest_dev_tag=${LATEST_DEV_TAG:-}"
  echo "should_build=$SHOULD_BUILD"
} >> "$GITHUB_OUTPUT"

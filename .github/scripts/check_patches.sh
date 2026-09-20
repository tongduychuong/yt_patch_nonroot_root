#!/usr/bin/env bash
set -euo pipefail

PATCH_REPO="MorpheApp/morphe-patches"
BUILD_REPO="${GITHUB_REPOSITORY}"
FORCE_BUILD="${FORCE_BUILD:-false}"

HAS_NEW_STABLE="false"
HAS_NEW_DEV="false"

echo "============================================================"
echo "            MORPHE PATCH UPDATE CHECK"
echo "============================================================"

# Fetch the complete release list first. Do not pipe gh/jq into
# head/awk that exits early: that causes SIGPIPE / exit 141.
PATCH_RELEASES_JSON="$(
  gh api "repos/${PATCH_REPO}/releases?per_page=100" --paginate
)"

# Latest stable: gh API returns releases newest first.
mapfile -t STABLE_PATCHES < <(
  printf '%s' "$PATCH_RELEASES_JSON" |
    jq -r '.[] | select(.draft == false) | select(.prerelease == false) | .tag_name' |
    sort -rV
)

if [ "${#STABLE_PATCHES[@]}" -eq 0 ]; then
  echo "ERROR: Cannot find latest Stable Morphe patch."
  exit 1
fi

LATEST_STABLE_TAG="${STABLE_PATCHES[0]}"
echo "Latest Stable Patch: ${LATEST_STABLE_TAG}"

# Latest dev (with sort -rV to ensure correct semantic versioning).
mapfile -t DEV_PATCHES < <(
  printf '%s' "$PATCH_RELEASES_JSON" |
    jq -r '.[] | select(.draft == false) | select(.prerelease == true) | .tag_name' |
    sort -rV
)

LATEST_DEV_TAG=""

if [ "${#DEV_PATCHES[@]}" -gt 0 ]; then
  LATEST_DEV_TAG="${DEV_PATCHES[0]}"
fi

# Fallback for Dev releases not marked as prerelease.
if [ -z "$LATEST_DEV_TAG" ]; then
  mapfile -t DEV_FALLBACK_PATCHES < <(
    printf '%s' "$PATCH_RELEASES_JSON" |
      jq -r '.[] | select(.draft == false) | .tag_name' |
      grep -Ei '(^|[-_.])(dev|beta|alpha|pre)([-_.]|$)' |
      sort -rV || true
  )

  if [ "${#DEV_FALLBACK_PATCHES[@]}" -gt 0 ]; then
    LATEST_DEV_TAG="${DEV_FALLBACK_PATCHES[0]}"
  fi
fi

echo "Latest Dev Patch: ${LATEST_DEV_TAG:-NONE}"

# Fetch our releases completely.
echo
echo "Loading existing build releases..."

BUILD_RELEASES_JSON="$(
  gh api "repos/${BUILD_REPO}/releases?per_page=100" --paginate
)"

if [ -z "$BUILD_RELEASES_JSON" ]; then
  BUILD_RELEASES_JSON="[]"
fi

get_latest_release() {
  local PREFIX="$1"

  printf '%s' "$BUILD_RELEASES_JSON" |
    jq -c --arg prefix "${PREFIX}-" '
      [
        .[]
        | select(.draft == false)
        | select(.tag_name | startswith($prefix))
      ]
      | sort_by(.published_at // .created_at)
      | reverse
      | .[0] // null
    '
}

extract_patch_tag() {
  local BODY="$1"
  local RESULT=""

  # Read all matching lines before returning, avoiding early pipe
  # termination and therefore avoiding SIGPIPE.
  while IFS= read -r LINE; do
    [ -z "$RESULT" ] || continue

    if [[ "$LINE" =~ (Stable\ Patch\ Version|Dev\ Patch\ Version|Stable\ Patch|Dev\ Patch) ]]; then
      if [[ "$LINE" =~ \[([^]]+)\] ]]; then
        RESULT="${BASH_REMATCH[1]}"
      fi
    fi
  done <<< "$BODY"

  printf '%s' "$RESULT"
}

# ============================================================
# CHECK STABLE
# ============================================================

echo
echo "============================================================"
echo "CHECK STABLE"
echo "============================================================"

STABLE_RELEASE="$(get_latest_release "stable")"

if [ "$STABLE_RELEASE" = "null" ] || [ -z "$STABLE_RELEASE" ]; then

  echo "No stable-* release found."
  echo "=> BUILD STABLE"
  HAS_NEW_STABLE="true"

else

  STABLE_RELEASE_TAG="$(printf '%s' "$STABLE_RELEASE" | jq -r '.tag_name // empty')"
  STABLE_RELEASE_BODY="$(printf '%s' "$STABLE_RELEASE" | jq -r '.body // empty')"
  LAST_STABLE_PATCH="$(extract_patch_tag "$STABLE_RELEASE_BODY")"

  echo "Latest Stable Release : ${STABLE_RELEASE_TAG}"
  echo "Built Stable Patch    : ${LAST_STABLE_PATCH:-UNKNOWN}"
  echo "Latest Morphe Patch   : ${LATEST_STABLE_TAG}"

  if [ -n "$LAST_STABLE_PATCH" ] &&
     [ "$LAST_STABLE_PATCH" = "$LATEST_STABLE_TAG" ]; then
    echo "=> SKIP STABLE"
    HAS_NEW_STABLE="false"
  else
    echo "=> BUILD STABLE"
    HAS_NEW_STABLE="true"
  fi
fi

# ============================================================
# CHECK DEV
# ============================================================

echo
echo "============================================================"
echo "CHECK DEV"
echo "============================================================"

if [ -z "$LATEST_DEV_TAG" ]; then

  echo "No Dev patch found."
  echo "=> SKIP DEV"
  HAS_NEW_DEV="false"

else

  DEV_RELEASE="$(get_latest_release "dev")"

  if [ "$DEV_RELEASE" = "null" ] || [ -z "$DEV_RELEASE" ]; then

    echo "No dev-* release found."
    echo "=> BUILD DEV"
    HAS_NEW_DEV="true"

  else

    DEV_RELEASE_TAG="$(printf '%s' "$DEV_RELEASE" | jq -r '.tag_name // empty')"
    DEV_RELEASE_BODY="$(printf '%s' "$DEV_RELEASE" | jq -r '.body // empty')"
    LAST_DEV_PATCH="$(extract_patch_tag "$DEV_RELEASE_BODY")"

    echo "Latest Dev Release : ${DEV_RELEASE_TAG}"
    echo "Built Dev Patch    : ${LAST_DEV_PATCH:-UNKNOWN}"
    echo "Latest Morphe Patch: ${LATEST_DEV_TAG}"

    if [ -n "$LAST_DEV_PATCH" ] &&
       [ "$LAST_DEV_PATCH" = "$LATEST_DEV_TAG" ]; then
      echo "=> SKIP DEV"
      HAS_NEW_DEV="false"
    else
      echo "=> BUILD DEV"
      HAS_NEW_DEV="true"
    fi
  fi
fi

# ============================================================
# FORCE BUILD
# ============================================================

if [ "$FORCE_BUILD" = "true" ]; then
  echo
  echo "============================================================"
  echo "FORCE BUILD ENABLED"
  echo "Ignoring patch check."
  echo "============================================================"

  HAS_NEW_STABLE="true"
  HAS_NEW_DEV="true"
fi

SHOULD_BUILD="false"

if [ "$HAS_NEW_STABLE" = "true" ] ||
   [ "$HAS_NEW_DEV" = "true" ]; then
  SHOULD_BUILD="true"
fi

echo
echo "============================================================"
echo "FINAL RESULT"
echo "============================================================"
echo "Latest Stable Patch : ${LATEST_STABLE_TAG}"
echo "Latest Dev Patch    : ${LATEST_DEV_TAG:-NONE}"
echo "Build Stable        : ${HAS_NEW_STABLE}"
echo "Build Dev           : ${HAS_NEW_DEV}"
echo "Should Build        : ${SHOULD_BUILD}"
echo "============================================================"

{
  echo "has_new_stable=${HAS_NEW_STABLE}"
  echo "has_new_dev=${HAS_NEW_DEV}"
  echo "latest_stable_tag=${LATEST_STABLE_TAG}"
  echo "latest_dev_tag=${LATEST_DEV_TAG:-}"
  echo "should_build=${SHOULD_BUILD}"
} >> "${GITHUB_OUTPUT}"

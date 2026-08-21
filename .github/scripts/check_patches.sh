#!/usr/bin/env bash
set -e

LATEST_STABLE_TAG=$(gh release view --repo MorpheApp/morphe-patches --json tagName --jq '.tagName')

LATEST_DEV_TAG=$(gh api graphql -f query='
  query {
    repository(owner: "MorpheApp", name: "morphe-patches") {
      releases(first: 20, orderBy: {field: CREATED_AT, direction: DESC}) {
        nodes {
          tagName
          isPrerelease
        }
      }
    }
  }
' --jq '.data.repository.releases.nodes[] | select(.isPrerelease == true) | .tagName' | head -n 1)

if [ -z "$LATEST_DEV_TAG" ] || [ "$LATEST_DEV_TAG" == "null" ]; then
  LATEST_DEV_TAG=$(gh api repos/MorpheApp/morphe-patches/releases --jq '.[0].tag_name')
fi

RECENT_RELEASES_INFO=$(gh api "repos/${GITHUB_REPOSITORY}/releases?per_page=10" --jq '.[].body' 2>/dev/null || echo "")

HAS_NEW_STABLE="false"
HAS_NEW_DEV="false"

if echo "$RECENT_RELEASES_INFO" | grep -Fq "$LATEST_STABLE_TAG"; then
  echo "-> Stable Patch '$LATEST_STABLE_TAG' ĐÃ CÓ. BỎ QUA!"
else
  HAS_NEW_STABLE="true"
fi

if echo "$RECENT_RELEASES_INFO" | grep -Fq "$LATEST_DEV_TAG"; then
  echo "-> Dev Patch '$LATEST_DEV_TAG' ĐÃ CÓ. BỎ QUA!"
else
  HAS_NEW_DEV="true"
fi

SHOULD_BUILD="false"
if [ "$HAS_NEW_STABLE" == "true" ] || [ "$HAS_NEW_DEV" == "true" ] || [ "$FORCE_BUILD" == "true" ]; then
  SHOULD_BUILD="true"
fi

echo "has_new_stable=$HAS_NEW_STABLE" >> $GITHUB_OUTPUT
echo "has_new_dev=$HAS_NEW_DEV" >> $GITHUB_OUTPUT
echo "latest_stable_tag=$LATEST_STABLE_TAG" >> $GITHUB_OUTPUT
echo "latest_dev_tag=$LATEST_DEV_TAG" >> $GITHUB_OUTPUT
echo "should_build=$SHOULD_BUILD" >> $GITHUB_OUTPUT

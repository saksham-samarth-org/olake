#!/bin/bash
set -euo pipefail

known=$(make -s print.drivers)

if [ "$GITHUB_EVENT_NAME" = merge_group ] || { [ "$GITHUB_EVENT_NAME" = pull_request ] && [ "$GITHUB_BASE_REF" != master ]; }; then
  if [ "$GITHUB_EVENT_NAME" = merge_group ]; then
    # base_sha is the entry's parent commit, so this diff covers this entry's own changes.
    changed=$(git diff --name-only "$MERGE_GROUP_BASE_SHA" "$GITHUB_SHA")
  else
    changed=$(gh api --paginate \
      "repos/$GITHUB_REPOSITORY/pulls/$PR_NUMBER/files" \
      --jq '.[].filename')
  fi
  selected=""
  for file in $changed; do
    # No path filter applies to merge_group, so skip pure docs changes here.
    if [ "$GITHUB_EVENT_NAME" = merge_group ]; then
      case "$file" in *.md) continue ;; esac
    fi
    case "$file" in
      drivers/*/*|tests/*/*) d=${file#*/}; d=${d%%/*} ;;
      *) d="" ;;
    esac
    case " $known " in *" $d "*) selected="$selected $d"; continue ;; esac
    selected="$known"
    break
  done
else
  selected="$known"
fi

drivers=$(printf '%s\n' $selected | sort -u | jq -Rc '[., inputs] | map(select(. != ""))')
echo "drivers=$drivers" >> "$GITHUB_OUTPUT"
echo "Affected drivers: $drivers"

title_case() {
  jq -c 'map({key: ., value: ((.[0:1] | ascii_upcase) + .[1:])}) | from_entries'
}

labels=$(printf '%s' "$drivers" | title_case)
echo "driver-labels=$labels" >> "$GITHUB_OUTPUT"

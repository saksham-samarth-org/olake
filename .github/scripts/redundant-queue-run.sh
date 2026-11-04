#!/bin/bash
set -euo pipefail

# Prints true when this merge queue entry only repeats a tests.yml run that already passed on the PR
# against the same base commit; false otherwise, including for any event that is not merge_group.
# The PR run records the base it tested in a `tested-base-<pr head sha>` artifact (see test-preflight.yml).
# A queue entry behind another one has that entry's queue commit as base_sha, so it never matches.
redundant=false
if [ "$GITHUB_EVENT_NAME" = "merge_group" ]; then
  pr=$(sed -n 's#.*/pr-\([0-9][0-9]*\)-.*#\1#p' <<<"$MERGE_GROUP_HEAD_REF")
  if [ -n "$pr" ]; then
    pr_head=$(gh api "repos/$GITHUB_REPOSITORY/pulls/$pr" --jq .head.sha)
    run_id=$(gh run list --repo "$GITHUB_REPOSITORY" --workflow tests.yml --event pull_request \
      --commit "$pr_head" --status success --limit 1 --json databaseId --jq '.[0].databaseId // empty')
    if [ -n "$run_id" ]; then
      dir=$(mktemp -d)
      if gh run download "$run_id" --repo "$GITHUB_REPOSITORY" -n "tested-base-$pr_head" -D "$dir" >/dev/null 2>&1; then
        if [ "$(tr -d '[:space:]' <"$dir/tested-base")" = "$MERGE_GROUP_BASE_SHA" ]; then
          redundant=true
        fi
      fi
    fi
  fi
fi
echo "$redundant"

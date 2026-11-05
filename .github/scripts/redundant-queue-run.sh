#!/bin/bash
set -euo pipefail

# Returns true if this merge queue entry has already passed tests.yml
# on the PR against the same base commit.
# Returns false otherwise, including for events other than merge_group.
# The PR workflow saves the base commit it tested in an artifact named
# `tested-base-<pr head sha>`.
#
# If another PR is ahead in the merge queue, this entry uses that PR's
# queue commit as its base, so the base commits won't match.

# Prints true when CI can be skipped for this merge queue entry, false otherwise.
is_ci_skippable() {
  # Not a merge queue run: never skip.
  if [ "$GITHUB_EVENT_NAME" != "merge_group" ]; then
    echo false
    return
  fi

  # PR number, from a head_ref like gh-readonly-queue/staging/pr-7-<sha>.
  local pr
  pr=$(sed -n 's#.*/pr-\([0-9][0-9]*\)-.*#\1#p' <<<"$MERGE_GROUP_HEAD_REF")
  if [ -z "$pr" ]; then
    echo false
    return
  fi

  # A successful tests.yml run must exist for the PR's head commit.
  local pr_head run_id
  pr_head=$(gh api "repos/$GITHUB_REPOSITORY/pulls/$pr" --jq .head.sha)
  run_id=$(gh run list \
    --repo "$GITHUB_REPOSITORY" \
    --workflow tests.yml \
    --event pull_request \
    --commit "$pr_head" \
    --status success \
    --limit 1 \
    --json databaseId \
    --jq '.[0].databaseId // empty')
  if [ -z "$run_id" ]; then
    echo false
    return
  fi

  # That run must have left the base commit it tested against.
  local dir
  dir=$(mktemp -d)
  if ! gh run download "$run_id" --repo "$GITHUB_REPOSITORY" -n "tested-base-$pr_head" -D "$dir" >/dev/null 2>&1; then
    echo false
    return
  fi

  # Skippable only when the queue entry is built on that same base commit.
  if [ "$(tr -d '[:space:]' <"$dir/tested-base")" = "$MERGE_GROUP_BASE_SHA" ]; then
    echo true
  else
    echo false
  fi
}

# `|| echo false`: if a command fails unexpectedly (e.g. a GitHub API error), run CI as normal.
is_ci_skippable || echo false

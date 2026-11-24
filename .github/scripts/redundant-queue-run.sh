#!/bin/bash
set -euo pipefail

# Returns true if this merge queue entry repeats a PR that already passed:
# same tree as the PR head, and the PR head's "All Required Checks Passed"
# status is success. Returns false otherwise, including for events other than
# merge_group.
#
# REDUNDANT_GATE_CONTEXT  status to check (default: All Required Checks Passed)
#
# If another PR is ahead in the merge queue, the trees differ, so CI runs.

gate_context="${REDUNDANT_GATE_CONTEXT:-All Required Checks Passed}"

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

  # The queue commit must have the same tree as the PR head: the PR was up to
  # date with its base, so the queue would test the files the PR already passed.
  local pr_head queue_tree pr_tree
  pr_head=$(gh api "repos/$GITHUB_REPOSITORY/pulls/$pr" --jq .head.sha)
  queue_tree=$(gh api "repos/$GITHUB_REPOSITORY/git/commits/$MERGE_GROUP_HEAD_SHA" --jq .tree.sha)
  pr_tree=$(gh api "repos/$GITHUB_REPOSITORY/git/commits/$pr_head" --jq .tree.sha)
  if [ -z "$queue_tree" ] || [ "$queue_tree" != "$pr_tree" ]; then
    echo false
    return
  fi

  # And the PR head's gate status must be green (newest status first). This
  # holds even when Tests never ran on the PR (no code changes).
  local state
  state=$(gh api \
    "repos/$GITHUB_REPOSITORY/commits/$pr_head/statuses" \
    --paginate \
    --jq "[.[] | select(.context == \"$gate_context\")] | .[0].state // empty" \
    | head -n 1)
  if [ "$state" = "success" ]; then
    # Audit trail for the skip. Goes to the step summary file, never stdout,
    # because stdout is captured as the `skip` output.
    {
      echo "### Queue gate: CI skipped"
      echo "- PR: #$pr"
      echo "- PR head: \`$pr_head\`"
      echo "- Queue commit: \`$MERGE_GROUP_HEAD_SHA\`"
      echo "- Shared tree: \`$queue_tree\`"
      echo "- \`$gate_context\` on PR head: \`$state\`"
    } >>"${GITHUB_STEP_SUMMARY:-/dev/null}"
    echo true
  else
    echo false
  fi
}

# `|| echo false`: if a command fails unexpectedly (e.g. a GitHub API error), run CI as normal.
is_ci_skippable || echo false

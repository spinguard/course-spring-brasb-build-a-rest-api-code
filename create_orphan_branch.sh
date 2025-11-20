#!/bin/bash

# Script to create an orphaned branch from main root commit and cherry-pick all subsequent commits
# Usage: ./create_orphan_branch.sh

set -e  # Exit on error

BRANCH_NAME="v2.0.132"
MAIN_BRANCH="main"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository"
    exit 1
fi

# Check if branch already exists
if git show-ref --verify --quiet refs/heads/"$BRANCH_NAME"; then
    echo "Error: Branch '$BRANCH_NAME' already exists"
    exit 1
fi

# Get the root commit of main branch
ROOT_COMMIT=$(git rev-list --max-parents=0 "$MAIN_BRANCH" | head -1)

if [ -z "$ROOT_COMMIT" ]; then
    echo "Error: Could not find root commit of $MAIN_BRANCH"
    exit 1
fi

echo "Root commit: $ROOT_COMMIT"

# Get all commits from main branch (excluding the root commit itself)
COMMITS=$(git rev-list --reverse "$ROOT_COMMIT".."$MAIN_BRANCH")

if [ -z "$COMMITS" ]; then
    echo "Warning: No commits found after root commit"
fi

# Create orphaned branch from root commit
echo "Creating orphaned branch '$BRANCH_NAME' from root commit..."
git checkout --orphan "$BRANCH_NAME"
git reset --hard "$ROOT_COMMIT"

# Count total commits for progress
TOTAL_COMMITS=$(echo "$COMMITS" | wc -l | tr -d ' ')
CURRENT=0

# Cherry-pick each commit
if [ -n "$COMMITS" ]; then
    echo "Cherry-picking $TOTAL_COMMITS commits..."
    for commit in $COMMITS; do
        CURRENT=$((CURRENT + 1))
        echo "[$CURRENT/$TOTAL_COMMITS] Cherry-picking $commit..."

        if ! git cherry-pick "$commit"; then
            echo "Error: Failed to cherry-pick commit $commit"
            echo "You may need to resolve conflicts manually and continue with: git cherry-pick --continue"
            exit 1
        fi
    done
    echo "Successfully cherry-picked all commits!"
else
    echo "No commits to cherry-pick (branch only contains root commit)"
fi

echo "Branch '$BRANCH_NAME' created successfully!"
echo "Current branch: $(git branch --show-current)"

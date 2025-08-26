#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: ./git-pr.sh <branch-name>"
    exit 1
fi

BRANCH_NAME=$1

if [[ $BRANCH_NAME == feature/* ]]; then
    BRANCH_TYPE="feature"
    TARGET_BRANCHES=("dev")
    LABELS=("feature")
elif [[ $BRANCH_NAME == release/* ]]; then
    BRANCH_TYPE="release"
    TARGET_BRANCHES=("main" "dev")
    LABELS=("release" "backmerge")
elif [[ $BRANCH_NAME == hotfix/* ]]; then
    BRANCH_TYPE="hotfix"
    TARGET_BRANCHES=("main" "dev")
    LABELS=("hotfix" "backmerge")
else
    echo "Branch type not recognized. Please use feature/, release/, or hotfix/."
    exit 1
fi

echo "Pushing branch $BRANCH_NAME to origin..."
git push --set-upstream origin "$BRANCH_NAME"

for i in "${!TARGET_BRANCHES[@]}"; do
    TARGET_BRANCH="${TARGET_BRANCHES[$i]}"
    LABEL="${LABELS[$i]}"

    EXISTING_PR=$(gh pr list --base "$TARGET_BRANCH" --head "$BRANCH_NAME" --state open --json number --jq ".[0].number")
    
    if [ -n "$EXISTING_PR" ]; then
        echo "Open PR #$EXISTING_PR already exists for $BRANCH_NAME -> $TARGET_BRANCH"
        continue
    fi

    if [ "$TARGET_BRANCH" == "main" ]; then
        DEFAULT_TITLE="Merge $BRANCH_NAME into $TARGET_BRANCH"
        DEFAULT_BODY="This is an automated pull request for $BRANCH_TYPE."
    else
        DEFAULT_TITLE="Backmerge $BRANCH_NAME into $TARGET_BRANCH"
        DEFAULT_BODY="This is an automated backmerge pull request from $BRANCH_NAME."
    fi
    
    read -p "Enter PR title for $TARGET_BRANCH (or press Enter for '$DEFAULT_TITLE'): " PR_TITLE
    if [ -z "$PR_TITLE" ]; then
        PR_TITLE="$DEFAULT_TITLE"
    fi
    
    read -p "Enter PR description for $TARGET_BRANCH (or press Enter for default): " PR_BODY
    if [ -z "$PR_BODY" ]; then
        PR_BODY="$DEFAULT_BODY"
    fi

    echo "Creating pull request for $BRANCH_NAME into $TARGET_BRANCH..."
    gh pr create \
        --base "$TARGET_BRANCH" \
        --head "$BRANCH_NAME" \
        --title "$PR_TITLE" \
        --body "$PR_BODY" \
        --label "$LABEL" \
        --assignee "@me"
    
    echo "Pull request to $TARGET_BRANCH created successfully!"
done
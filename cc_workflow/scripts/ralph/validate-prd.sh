#!/bin/bash
# PRD Validation Helper - Checks if tasks are appropriately sized
# Usage: ./validate-prd.sh [prd.json]

set -e

PRD_FILE="${1:-scripts/ralph/prd.json}"

if [ ! -f "$PRD_FILE" ]; then
  echo "❌ PRD file not found: $PRD_FILE"
  exit 1
fi

echo "🔍 Validating PRD: $PRD_FILE"
echo ""

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  echo "❌ jq is required but not installed"
  echo "   Install with: brew install jq"
  exit 1
fi

# Parse PRD
PROJECT=$(jq -r '.project // .projectName // "Unknown"' "$PRD_FILE")
BRANCH=$(jq -r '.branchName // "No branch"' "$PRD_FILE")
TOTAL_STORIES=$(jq '.userStories | length' "$PRD_FILE")

echo "📋 Project: $PROJECT"
echo "🌿 Branch: $BRANCH"
echo "📊 Total Stories: $TOTAL_STORIES"
echo ""

# Validate each story
echo "🎯 Story Analysis:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

WARNINGS=0
ERRORS=0

for i in $(seq 0 $((TOTAL_STORIES - 1))); do
  STORY_ID=$(jq -r ".userStories[$i].id" "$PRD_FILE")
  TITLE=$(jq -r ".userStories[$i].title" "$PRD_FILE")
  CRITERIA_COUNT=$(jq ".userStories[$i].acceptanceCriteria | length" "$PRD_FILE")
  PRIORITY=$(jq -r ".userStories[$i].priority" "$PRD_FILE")
  PASSES=$(jq -r ".userStories[$i].passes" "$PRD_FILE")

  echo ""
  echo "Story $((i + 1)): $STORY_ID - $TITLE"
  echo "  Priority: $PRIORITY | Status: $([ "$PASSES" = "true" ] && echo "✅ Complete" || echo "⏳ Pending")"
  echo "  Acceptance Criteria: $CRITERIA_COUNT items"

  # Check for issues
  if [ $CRITERIA_COUNT -eq 0 ]; then
    echo "  ❌ ERROR: No acceptance criteria defined"
    ERRORS=$((ERRORS + 1))
  elif [ $CRITERIA_COUNT -gt 5 ]; then
    echo "  ⚠️  WARNING: Many acceptance criteria ($CRITERIA_COUNT) - consider splitting"
    WARNINGS=$((WARNINGS + 1))
  fi

  # Check title length (rough complexity indicator)
  TITLE_LENGTH=${#TITLE}
  if [ $TITLE_LENGTH -gt 80 ]; then
    echo "  ⚠️  WARNING: Long title ($TITLE_LENGTH chars) - may be too complex"
    WARNINGS=$((WARNINGS + 1))
  fi

  # Check for vague terms
  if echo "$TITLE" | grep -qi -E "(refactor|rebuild|rewrite|entire|all|complete|full)"; then
    echo "  ⚠️  WARNING: Title contains broad scope words - may be too large"
    WARNINGS=$((WARNINGS + 1))
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Summary
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo "✅ PRD looks good! All stories are well-scoped."
  exit 0
elif [ $ERRORS -eq 0 ]; then
  echo "⚠️  PRD has $WARNINGS warnings but no errors."
  echo ""
  echo "💡 Tips for better task sizing:"
  echo "   • Each story should change 1-3 files"
  echo "   • Aim for 2-4 acceptance criteria per story"
  echo "   • Avoid broad terms like 'refactor', 'rebuild', 'entire'"
  echo "   • If a story feels complex, split it into smaller stories"
  exit 0
else
  echo "❌ PRD has $ERRORS errors and $WARNINGS warnings."
  echo ""
  echo "Fix errors before running Ralph."
  exit 1
fi

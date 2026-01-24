#!/bin/bash
# Simple Interactive PRD Creator (No Claude required)
# Usage: ./create-prd-interactive.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🎯 Ralph PRD Creator - Interactive Mode"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This will guide you through creating a PRD for Ralph."
echo ""

# Basic project info
read -p "Project/Feature Name: " PROJECT_NAME
read -p "Git Branch Name (e.g., ralph/my-feature): " BRANCH_NAME
read -p "Feature Description: " DESCRIPTION

echo ""
echo "Great! Now let's add user stories."
echo ""

# Initialize JSON structure
cat > "$SCRIPT_DIR/prd.json" <<EOF
{
  "project": "$PROJECT_NAME",
  "branchName": "$BRANCH_NAME",
  "description": "$DESCRIPTION",
  "userStories": []
}
EOF

STORY_COUNT=0

while true; do
  STORY_COUNT=$((STORY_COUNT + 1))
  STORY_ID=$(printf "US-%03d" $STORY_COUNT)

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "User Story $STORY_COUNT ($STORY_ID)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  read -p "Story Title: " TITLE

  if [ -z "$TITLE" ]; then
    echo ""
    echo "Empty title - stopping here."
    break
  fi

  read -p "Description (one sentence): " DESC
  read -p "Priority (1-5, higher number = lower priority): " PRIORITY

  echo ""
  echo "Acceptance Criteria (press Enter on empty line to finish):"
  CRITERIA=()
  CRITERIA_COUNT=1
  while true; do
    read -p "  $CRITERIA_COUNT. " CRITERION
    if [ -z "$CRITERION" ]; then
      break
    fi
    CRITERIA+=("$CRITERION")
    CRITERIA_COUNT=$((CRITERIA_COUNT + 1))
  done

  read -p "Technical Notes (optional): " NOTES

  # Build criteria JSON array
  CRITERIA_JSON="["
  for i in "${!CRITERIA[@]}"; do
    if [ $i -gt 0 ]; then
      CRITERIA_JSON+=","
    fi
    CRITERIA_JSON+="\"${CRITERIA[$i]}\""
  done
  CRITERIA_JSON+="]"

  # Add story to PRD using jq
  if command -v jq &> /dev/null; then
    TMP_FILE=$(mktemp)
    jq --arg id "$STORY_ID" \
       --arg title "$TITLE" \
       --arg desc "$DESC" \
       --argjson criteria "$CRITERIA_JSON" \
       --argjson priority "$PRIORITY" \
       --arg notes "$NOTES" \
       '.userStories += [{
         "id": $id,
         "title": $title,
         "description": $desc,
         "acceptanceCriteria": $criteria,
         "priority": $priority,
         "passes": false,
         "notes": $notes
       }]' "$SCRIPT_DIR/prd.json" > "$TMP_FILE"
    mv "$TMP_FILE" "$SCRIPT_DIR/prd.json"
  else
    echo "⚠️  jq not installed - cannot add story to JSON"
    echo "Please install jq: brew install jq"
    exit 1
  fi

  echo ""
  read -p "Add another story? (y/n): " ADD_MORE
  if [[ ! "$ADD_MORE" =~ ^[Yy] ]]; then
    break
  fi
  echo ""
done

echo ""
echo "✅ PRD created successfully!"
echo ""
echo "📄 Saved to: $SCRIPT_DIR/prd.json"
echo ""

# Pretty print the PRD
if command -v jq &> /dev/null; then
  echo "📊 Your PRD:"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  jq '.' "$SCRIPT_DIR/prd.json"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi

echo ""
echo "Next steps:"
echo "  1. Review: scripts/ralph/prd.json"
echo "  2. Validate: ./scripts/ralph/validate-prd.sh"
echo "  3. Run Ralph: ./scripts/ralph/ralph.sh"
echo ""

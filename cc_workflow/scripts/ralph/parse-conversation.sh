#!/bin/bash
# Parse a Claude conversation JSONL file to extract key information
# Usage: ./parse-conversation.sh <session-id>

set -e

SESSION_ID=$1

if [ -z "$SESSION_ID" ]; then
  echo "Usage: ./parse-conversation.sh <session-id>"
  echo ""
  echo "Session ID can be found in progress.txt or by running:"
  echo "  ./scripts/ralph/capture-session-id.sh"
  exit 1
fi

# Get the current project path (normalized)
PROJECT_PATH=$(pwd | sed 's/\//-/g')
CLAUDE_PROJECT_DIR="$HOME/.claude/projects/$PROJECT_PATH"
JSONL_FILE="$CLAUDE_PROJECT_DIR/$SESSION_ID.jsonl"

if [ ! -f "$JSONL_FILE" ]; then
  echo "Error: Conversation file not found: $JSONL_FILE"
  exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Conversation Analysis: $SESSION_ID"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Count total entries
TOTAL_LINES=$(wc -l < "$JSONL_FILE")
echo "📊 Total log entries: $TOTAL_LINES"
echo ""

# Extract errors from tool results
echo "❌ Errors Encountered:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ERROR_COUNT=$(jq -r 'select(.type == "tool-result" and .result.error != null) |
  "\(.timestamp | split("T")[1] | split(".")[0]): \(.name) - \(.result.error)"' "$JSONL_FILE" 2>/dev/null | head -10)

if [ -z "$ERROR_COUNT" ]; then
  echo "✅ No errors found"
else
  echo "$ERROR_COUNT"
fi
echo ""

# Extract files that were written
echo "📝 Files Modified (Write tool):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
jq -r 'select(.type == "tool-use" and .name == "Write") |
  .input.file_path' "$JSONL_FILE" 2>/dev/null | sort -u | head -20 || echo "None found"
echo ""

# Extract files that were edited
echo "✏️  Files Edited (Edit tool):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
jq -r 'select(.type == "tool-use" and .name == "Edit") |
  .input.file_path' "$JSONL_FILE" 2>/dev/null | sort -u | head -20 || echo "None found"
echo ""

# Extract bash commands run
echo "💻 Bash Commands Executed:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
jq -r 'select(.type == "tool-use" and .name == "Bash") |
  .input.description // .input.command' "$JSONL_FILE" 2>/dev/null | head -15 || echo "None found"
echo ""

# Extract git commits
echo "🔀 Git Commits:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
jq -r 'select(.type == "tool-use" and .name == "Bash" and
  (.input.command | contains("git commit"))) |
  .input.command' "$JSONL_FILE" 2>/dev/null | sed 's/git commit//' | head -10 || echo "None found"
echo ""

# Extract key decisions (assistant messages mentioning "decided", "chose", "will")
echo "🎯 Key Decisions/Actions:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
jq -r 'select(.type == "assistant" and .message.content != null) |
  .message.content |
  if type == "string" then
    select(. | test("(decided|chose|will implement|going to|approach)"; "i")) |
    .
  else
    empty
  end' "$JSONL_FILE" 2>/dev/null | grep -E "(decided|chose|will|approach)" | head -5 || echo "None found"
echo ""

# Extract quality check results
echo "✅ Quality Checks:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
jq -r 'select(.type == "tool-use" and .name == "Bash" and
  (.input.command | contains("check-types") or contains("npm run check"))) |
  .input.command' "$JSONL_FILE" 2>/dev/null | head -5 || echo "None found"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 To view full conversation:"
echo "   cat $JSONL_FILE | jq '.'"
echo ""
echo "💡 To search for specific content:"
echo "   cat $JSONL_FILE | jq 'select(.message.content | contains(\"search-term\"))'"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

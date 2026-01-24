#!/bin/bash
# Auto-extract key insights from a conversation and format for progress.txt
# Usage: ./extract-insights.sh <session-id> [output-file]

set -e

SESSION_ID=$1
OUTPUT_FILE=${2:-/dev/stdout}

if [ -z "$SESSION_ID" ]; then
  echo "Usage: ./extract-insights.sh <session-id> [output-file]"
  echo ""
  echo "If output-file is omitted, prints to stdout"
  exit 1
fi

# Get the current project path (normalized)
PROJECT_PATH=$(pwd | sed 's/\//-/g')
CLAUDE_PROJECT_DIR="$HOME/.claude/projects/$PROJECT_PATH"
JSONL_FILE="$CLAUDE_PROJECT_DIR/$SESSION_ID.jsonl"

if [ ! -f "$JSONL_FILE" ]; then
  echo "Error: Conversation file not found: $JSONL_FILE" >&2
  exit 1
fi

# Create temporary files for extraction
TMP_ERRORS=$(mktemp)
TMP_FILES=$(mktemp)
TMP_PATTERNS=$(mktemp)
TMP_GOTCHAS=$(mktemp)

# Trap to clean up temp files
trap "rm -f $TMP_ERRORS $TMP_FILES $TMP_PATTERNS $TMP_GOTCHAS" EXIT

# Extract errors and failures
jq -r 'select(.type == "tool-result" and .result.error != null) |
  "- \(.name) failed: \(.result.error | split("\n")[0])"' "$JSONL_FILE" > "$TMP_ERRORS" 2>/dev/null || true

# Extract files modified
{
  jq -r 'select(.type == "tool-use" and .name == "Write") |
    .input.file_path' "$JSONL_FILE" 2>/dev/null | sort -u
  jq -r 'select(.type == "tool-use" and .name == "Edit") |
    .input.file_path' "$JSONL_FILE" 2>/dev/null | sort -u
} | sort -u | sed 's/^/- /' > "$TMP_FILES" || true

# Extract patterns (mentions of "use", "pattern", "approach")
jq -r 'select(.type == "assistant" and .message.content != null) |
  .message.content |
  if type == "string" then
    select(. | test("(use|pattern|approach|should use|always|never)"; "i")) |
    split("\n")[] |
    select(length > 20 and length < 150) |
    select(. | test("(use|pattern|approach|should|always|never)"; "i"))
  else
    empty
  end' "$JSONL_FILE" 2>/dev/null | \
  grep -iE "(use|pattern|approach|should|always|never)" | \
  head -10 | \
  sed 's/^/- /' > "$TMP_PATTERNS" || true

# Extract gotchas (mentions of "must", "important", "note", "warning")
jq -r 'select(.type == "assistant" and .message.content != null) |
  .message.content |
  if type == "string" then
    select(. | test("(must|important|note|warning|gotcha|careful)"; "i")) |
    split("\n")[] |
    select(length > 20 and length < 150) |
    select(. | test("(must|important|note|warning|careful)"; "i"))
  else
    empty
  end' "$JSONL_FILE" 2>/dev/null | \
  grep -iE "(must|important|note|warning|careful)" | \
  head -10 | \
  sed 's/^/- /' > "$TMP_GOTCHAS" || true

# Generate insights output
{
  echo "### Auto-Extracted Insights (from conversation $SESSION_ID)"
  echo ""

  if [ -s "$TMP_ERRORS" ]; then
    echo "**Errors Encountered:**"
    cat "$TMP_ERRORS"
    echo ""
  fi

  if [ -s "$TMP_FILES" ]; then
    echo "**Files Modified:**"
    cat "$TMP_FILES"
    echo ""
  fi

  if [ -s "$TMP_PATTERNS" ]; then
    echo "**Patterns Discovered:**"
    cat "$TMP_PATTERNS" | head -5
    echo ""
  fi

  if [ -s "$TMP_GOTCHAS" ]; then
    echo "**Important Notes/Gotchas:**"
    cat "$TMP_GOTCHAS" | head -5
    echo ""
  fi

  echo "**Full conversation available at:**"
  echo "\`$JSONL_FILE\`"
  echo ""
  echo "**Parse with:**"
  echo "\`./scripts/ralph/parse-conversation.sh $SESSION_ID\`"

} > "$OUTPUT_FILE"

if [ "$OUTPUT_FILE" != "/dev/stdout" ]; then
  echo "✅ Insights extracted to: $OUTPUT_FILE"
fi

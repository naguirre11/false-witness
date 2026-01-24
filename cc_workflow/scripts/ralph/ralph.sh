#!/bin/bash
# Ralph Wiggum - Long-running AI agent loop (adapted for Claude Code CLI)
# Usage: ./ralph.sh [max_iterations]

set -e

MAX_ITERATIONS=${1:-10}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Project root is 3 levels up from cc_workflow/scripts/ralph
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
ARCHIVE_DIR="$SCRIPT_DIR/archive"
LAST_BRANCH_FILE="$SCRIPT_DIR/.last-branch"
SESSION_HISTORY_FILE="$SCRIPT_DIR/session-history.txt"
INSIGHTS_DIR="$SCRIPT_DIR/insights"

# Archive previous run if branch changed
if [ -f "$PRD_FILE" ] && [ -f "$LAST_BRANCH_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")

  if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
    # Archive the previous run
    DATE=$(date +%Y-%m-%d)
    # Strip "ralph/" prefix from branch name for folder
    FOLDER_NAME=$(echo "$LAST_BRANCH" | sed 's|^ralph/||')
    ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"

    echo "Archiving previous run: $LAST_BRANCH"
    mkdir -p "$ARCHIVE_FOLDER"
    [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/"
    [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
    echo "   Archived to: $ARCHIVE_FOLDER"

    # Reset progress file for new run
    echo "# Ralph Progress Log" > "$PROGRESS_FILE"
    echo "Started: $(date)" >> "$PROGRESS_FILE"
    echo "---" >> "$PROGRESS_FILE"
  fi
fi

# Track current branch
if [ -f "$PRD_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  if [ -n "$CURRENT_BRANCH" ]; then
    echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
  fi
fi

# Initialize progress file if it doesn't exist
if [ ! -f "$PROGRESS_FILE" ]; then
  echo "# Ralph Progress Log" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

# Initialize session history if it doesn't exist
if [ ! -f "$SESSION_HISTORY_FILE" ]; then
  echo "# Ralph Session History" > "$SESSION_HISTORY_FILE"
  echo "# Tracks Claude conversation IDs for each iteration" >> "$SESSION_HISTORY_FILE"
  echo "---" >> "$SESSION_HISTORY_FILE"
fi

# Create insights directory
mkdir -p "$INSIGHTS_DIR"

echo "Starting Ralph (Claude Code CLI) - Max iterations: $MAX_ITERATIONS"

for i in $(seq 1 $MAX_ITERATIONS); do
  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "  Ralph Iteration $i of $MAX_ITERATIONS"
  echo "═══════════════════════════════════════════════════════"

  # Run claude with the ralph prompt from the project root
  # Note: Using cat to pipe prompt and capturing output
  # Claude must run from project root to have access to the codebase
  OUTPUT=$(cd "$PROJECT_ROOT" && cat "$SCRIPT_DIR/prompt.md" | claude 2>&1 | tee /dev/stderr) || true

  # Capture session ID after iteration
  SESSION_ID=$("$SCRIPT_DIR/capture-session-id.sh" 2>/dev/null || echo "unknown")
  if [ "$SESSION_ID" != "unknown" ]; then
    echo "📝 Session ID: $SESSION_ID"

    # Log to session history
    echo "Iteration $i: $SESSION_ID ($(date))" >> "$SESSION_HISTORY_FILE"

    # Auto-extract insights (optional, runs in background)
    INSIGHT_FILE="$INSIGHTS_DIR/iteration-$i-$SESSION_ID.md"
    "$SCRIPT_DIR/extract-insights.sh" "$SESSION_ID" "$INSIGHT_FILE" 2>/dev/null &

    echo "💡 Insights being extracted to: $INSIGHT_FILE"
  fi

  # Check for completion signal
  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo ""
    echo "Ralph completed all tasks!"
    echo "Completed at iteration $i of $MAX_ITERATIONS"
    echo ""
    echo "📊 Session history: $SESSION_HISTORY_FILE"
    echo "📝 Progress log: $PROGRESS_FILE"
    echo "💡 Insights: $INSIGHTS_DIR/"
    exit 0
  fi

  echo "Iteration $i complete. Continuing..."
  sleep 2
done

echo ""
echo "Ralph reached max iterations ($MAX_ITERATIONS) without completing all tasks."
echo ""
echo "📊 Session history: $SESSION_HISTORY_FILE"
echo "📝 Progress log: $PROGRESS_FILE"
echo "💡 Insights: $INSIGHTS_DIR/"
echo ""
echo "Continue with: ./scripts/ralph/ralph.sh $MAX_ITERATIONS"
exit 1

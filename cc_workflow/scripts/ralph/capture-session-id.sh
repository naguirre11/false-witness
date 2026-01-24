#!/bin/bash
# Capture the current Claude session ID
# This script finds the most recent .jsonl file for the current project

set -e

# Get the current project path (normalized)
PROJECT_PATH=$(pwd | sed 's/\//-/g')

# Find the Claude projects directory for this project
CLAUDE_PROJECT_DIR="$HOME/.claude/projects/$PROJECT_PATH"

if [ ! -d "$CLAUDE_PROJECT_DIR" ]; then
  echo "Warning: Claude project directory not found: $CLAUDE_PROJECT_DIR" >&2
  exit 1
fi

# Find the most recently modified .jsonl file (current session)
LATEST_SESSION=$(ls -t "$CLAUDE_PROJECT_DIR"/*.jsonl 2>/dev/null | head -1)

if [ -z "$LATEST_SESSION" ]; then
  echo "Warning: No session files found in $CLAUDE_PROJECT_DIR" >&2
  exit 1
fi

# Extract just the session ID (filename without path and extension)
SESSION_ID=$(basename "$LATEST_SESSION" .jsonl)

echo "$SESSION_ID"

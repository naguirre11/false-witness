#!/bin/bash
# Interactive PRD Creator for Claude Code CLI
# Usage: ./create-prd.sh

set -e

echo "🤖 Ralph PRD Creator (Claude Code CLI)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Ask questions
echo "Let's create your PRD..."
echo ""

read -p "Project/Feature Name: " PROJECT_NAME
read -p "Git Branch Name (e.g., ralph/my-feature): " BRANCH_NAME
read -p "Number of user stories to create: " NUM_STORIES

echo ""
echo "Great! Now I'll use Claude to help generate detailed user stories."
echo ""

# Create a prompt for Claude
PROMPT="I'm creating a PRD for: $PROJECT_NAME

Please help me create $NUM_STORIES user stories in JSON format for this feature.

For each user story, provide:
- id: Sequential ID (US-001, US-002, etc.)
- title: Clear, action-oriented title
- description: One sentence describing the user story
- acceptanceCriteria: 2-4 specific, testable criteria
- priority: 1 (highest) to 5 (lowest)
- passes: false (all start as incomplete)
- notes: Any technical hints or file locations

Context about this project:
- It's a Next.js 14 app with Convex backend
- Routes are under /orgs/[orgId]/
- We use shadcn/ui components
- TypeScript strict mode

Format the output as a valid prd.json structure like this:
{
  \"project\": \"$PROJECT_NAME\",
  \"branchName\": \"$BRANCH_NAME\",
  \"description\": \"...\",
  \"userStories\": [...]
}

Make sure each story is small enough to complete in one iteration (1-3 files changed).
"

# Generate PRD using Claude
echo "🤖 Asking Claude to generate your PRD..."
echo ""

OUTPUT=$(echo "$PROMPT" | claude --dangerously-allow-all 2>&1) || {
  echo "❌ Failed to generate PRD with Claude"
  echo ""
  echo "You can still create the PRD manually by editing:"
  echo "  scripts/ralph/prd.json"
  exit 1
}

# Extract JSON from Claude's response (it might include explanation text)
# Look for content between first { and last }
EXTRACTED_JSON=$(echo "$OUTPUT" | sed -n '/{/,/}/p')

if [ -z "$EXTRACTED_JSON" ]; then
  echo "⚠️  Claude returned text but I couldn't extract JSON"
  echo ""
  echo "Here's what Claude said:"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "$OUTPUT"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Please copy the JSON above and save it to scripts/ralph/prd.json"
  exit 1
fi

# Save to prd.json
echo "$EXTRACTED_JSON" > scripts/ralph/prd.json

echo "✅ PRD created successfully!"
echo ""
echo "📄 Saved to: scripts/ralph/prd.json"
echo ""

# Validate it
if command -v jq &> /dev/null; then
  echo "🔍 Validating JSON format..."
  if jq empty scripts/ralph/prd.json 2>/dev/null; then
    echo "✅ Valid JSON"

    # Show summary
    echo ""
    echo "📊 PRD Summary:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    jq -r '"Project: \(.project // .projectName)\nBranch: \(.branchName)\nStories: \(.userStories | length)"' scripts/ralph/prd.json
    echo ""
    echo "User Stories:"
    jq -r '.userStories[] | "  \(.id): \(.title)"' scripts/ralph/prd.json
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  else
    echo "❌ Invalid JSON - please check the file manually"
  fi
fi

echo ""
echo "Next steps:"
echo "  1. Review/edit: scripts/ralph/prd.json"
echo "  2. Validate: ./scripts/ralph/validate-prd.sh"
echo "  3. Run Ralph: ./scripts/ralph/ralph.sh"
echo ""

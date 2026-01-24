#!/bin/bash
# Ralph Initialization Script
# Guides you through customizing Ralph for your project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "╔════════════════════════════════════════════════════════╗"
echo "║                                                        ║"
echo "║          Ralph for Claude Code CLI - Setup            ║"
echo "║                                                        ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "This script will customize Ralph for your project."
echo "Press Ctrl+C at any time to cancel."
echo ""
read -p "Press Enter to continue..."
echo ""

# ============================================================================
# Step 1: Project Information
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 1: Project Information"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

read -p "Project name (e.g., 'MyApp'): " PROJECT_NAME
echo ""

# ============================================================================
# Step 2: Quality Check Commands
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 2: Quality Check Commands"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "What commands does your project use for quality checks?"
echo ""

read -p "Type check command (e.g., 'npm run check-types'): " TYPE_CHECK_CMD
read -p "Linting command (e.g., 'npm run lint'): " LINT_CMD
read -p "Auto-fix formatting command (e.g., 'npm run lint:fix'): " FORMAT_CMD
echo ""

# ============================================================================
# Step 3: Browser Testing (optional)
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 3: Browser Testing Configuration (Optional)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Does your project need browser testing for UI changes?"
echo ""

read -p "Enable browser testing? (y/n, default: y): " ENABLE_BROWSER
ENABLE_BROWSER=${ENABLE_BROWSER:-y}

if [[ "$ENABLE_BROWSER" == "y" || "$ENABLE_BROWSER" == "Y" ]]; then
  echo ""
  read -p "Dev server URL (e.g., 'http://localhost:3000'): " DEV_SERVER_URL
  read -p "Test account email (for browser login): " TEST_EMAIL
  read -p "Test account password: " -s TEST_PASSWORD
  echo ""
  echo ""
else
  DEV_SERVER_URL=""
  TEST_EMAIL=""
  TEST_PASSWORD=""
fi

# ============================================================================
# Step 4: Project-Specific Patterns (optional)
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Step 4: Project-Specific Patterns (Optional)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Do you have any coding patterns Ralph should always follow?"
echo "Examples:"
echo "  - Never use .filter() - always use .withIndex()"
echo "  - All routes scoped under /app/"
echo "  - Use specific UI library components"
echo ""
echo "You can add these now or later by editing prompt.md"
echo ""

PATTERNS=()
while true; do
  read -p "Add a pattern? (press Enter to skip): " PATTERN
  if [ -z "$PATTERN" ]; then
    break
  fi
  PATTERNS+=("$PATTERN")
done

# ============================================================================
# Step 5: Summary and Confirmation
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Configuration Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Project Name: $PROJECT_NAME"
echo "Type Check: $TYPE_CHECK_CMD"
echo "Linting: $LINT_CMD"
echo "Formatting: $FORMAT_CMD"
if [ -n "$DEV_SERVER_URL" ]; then
  echo "Dev Server: $DEV_SERVER_URL"
  echo "Test Account: $TEST_EMAIL"
fi
if [ ${#PATTERNS[@]} -gt 0 ]; then
  echo "Patterns:"
  for pattern in "${PATTERNS[@]}"; do
    echo "  - $pattern"
  done
fi
echo ""

read -p "Apply these settings? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "Setup cancelled."
  exit 1
fi

# ============================================================================
# Step 6: Update prompt.md
# ============================================================================
echo ""
echo "Updating prompt.md..."

# Update type check command
sed -i.bak "s|npm run check-types|$TYPE_CHECK_CMD|g" "$SCRIPT_DIR/prompt.md"

# Update lint commands
sed -i.bak "s|npm run lint:fix|$FORMAT_CMD|g" "$SCRIPT_DIR/prompt.md"
sed -i.bak "s|npm run lint|$LINT_CMD|g" "$SCRIPT_DIR/prompt.md"

# Update browser testing if enabled
if [ -n "$DEV_SERVER_URL" ]; then
  sed -i.bak "s|\*\*\[REPLACE WITH YOUR DEV SERVER URL, e.g., http://localhost:3000\]\*\*|$DEV_SERVER_URL|g" "$SCRIPT_DIR/prompt.md"
  sed -i.bak "s|\*\*\[REPLACE WITH YOUR TEST ACCOUNT\]\*\*|$TEST_EMAIL / $TEST_PASSWORD|g" "$SCRIPT_DIR/prompt.md"
fi

# Add project-specific patterns if provided
if [ ${#PATTERNS[@]} -gt 0 ]; then
  # Create patterns string
  PATTERN_STRING=""
  for pattern in "${PATTERNS[@]}"; do
    PATTERN_STRING+="- $pattern\n"
  done

  # Replace placeholder with actual patterns
  sed -i.bak "/<!-- CUSTOMIZE: Add your project's specific patterns here -->/,/-->/c\\
<!-- Project-Specific Patterns -->\n$PATTERN_STRING" "$SCRIPT_DIR/prompt.md"
fi

# Remove backup file
rm -f "$SCRIPT_DIR/prompt.md.bak"

echo "✅ prompt.md updated"

# ============================================================================
# Step 7: Create example PRD
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Create Example PRD?"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Would you like to create an example PRD to test Ralph?"
echo ""

read -p "Create example PRD? (y/n, default: n): " CREATE_PRD
CREATE_PRD=${CREATE_PRD:-n}

if [[ "$CREATE_PRD" == "y" || "$CREATE_PRD" == "Y" ]]; then
  cat > "$SCRIPT_DIR/prd.json" << EOF
{
  "projectName": "$PROJECT_NAME - Ralph Test",
  "branchName": "ralph/test-run",
  "description": "Test Ralph with a simple story",
  "userStories": [
    {
      "id": "TEST-001",
      "title": "Add hello world comment to README",
      "priority": 1,
      "passes": false,
      "acceptanceCriteria": [
        "Add comment '<!-- Hello from Ralph! -->' at top of README.md",
        "Verify comment appears in file",
        "Commit changes"
      ],
      "notes": "This is a simple test story to verify Ralph is working correctly."
    }
  ]
}
EOF
  echo "✅ Created test PRD: $SCRIPT_DIR/prd.json"
  echo ""
  echo "You can now run: ./scripts/ralph/ralph.sh 1"
fi

# ============================================================================
# Final Instructions
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo ""
echo "1. Review prompt.md to verify customizations"
echo "2. Create a PRD file (or use one of the examples/)"
echo "3. Run: ./scripts/ralph/ralph.sh [max-iterations]"
echo ""
echo "Documentation:"
echo "  - README.md          - Quick start guide"
echo "  - QUICKSTART.md      - Detailed getting started"
echo "  - ARCHITECTURE.md    - Technical overview"
echo "  - LEARNING_SYSTEM.md - How Ralph learns"
echo ""
echo "Need help? Check README.md or QUICKSTART.md"
echo ""
echo "Happy autonomous coding! 🤖"
echo ""

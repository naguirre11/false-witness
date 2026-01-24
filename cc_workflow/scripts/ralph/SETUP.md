# Ralph Setup Guide

Two ways to set up Ralph for your project:

## Option A: Guided Setup (Recommended)

Run the interactive setup script:

```bash
./init.sh
```

This will guide you through:
1. Project information
2. Quality check commands
3. Browser testing configuration
4. Project-specific patterns
5. Optional example PRD creation

The script will update `prompt.md` with your project-specific settings.

---

## Option B: Manual Setup

### Step 1: Install Ralph

Copy the `ralph/` directory to your project:

```bash
# From the ralph directory
cp -R . /path/to/your/project/scripts/ralph/
```

### Step 2: Customize prompt.md

Edit `scripts/ralph/prompt.md` and replace these placeholders:

#### Quality Commands (Lines ~170-182)

Replace with your project's commands:

```markdown
1. **Type Check**: npm run check-types     ← Change to your command
2. **Format & Lint**: npm run lint:fix     ← Change to your command
3. **Lint Check**: npm run lint            ← Change to your command
```

#### Browser Testing Credentials (Lines ~188-189)

If you need browser testing, replace:

```markdown
- Test credentials: **[REPLACE WITH YOUR TEST ACCOUNT]**
- Dev server URL: **[REPLACE WITH YOUR DEV SERVER URL, e.g., http://localhost:3000]**
```

With your actual credentials:

```markdown
- Test credentials: **testuser@example.com / password123**
- Dev server URL: **http://localhost:3000**
```

If you don't need browser testing, you can remove the browser testing sections or leave them as-is.

#### Project-Specific Patterns (Lines ~200-207)

Replace the placeholder comments with your actual patterns:

**Before:**
```markdown
**Project-Specific Patterns:**
<!-- CUSTOMIZE: Add your project's specific patterns here -->
<!-- Examples:
- Never use X pattern - always use Y
- All functions need Z validators
- Use Type<"tableName"> types, not string
- All routes scoped under `/app/`
-->
```

**After (example for a Next.js + Prisma project):**
```markdown
**Project-Specific Patterns:**
- Never use Prisma `.findMany()` without pagination - always use cursor-based
- All API routes must return standardized `{ data, error }` format
- Use zod schemas for all API input validation
- All routes scoped under `/app/`
- Use shadcn/ui components from `@/components/ui`
```

#### Browser Testing Details (Lines ~218-221)

If using browser testing, update:

```markdown
1. Dev server should be running (check your project's README for the command)
2. ...
3. Login with test credentials: **[REPLACE WITH YOUR TEST ACCOUNT]**
```

To:

```markdown
1. Dev server should be running: npm run dev  ← Your command
2. ...
3. Login with test credentials: **testuser@example.com / password123**
```

### Step 3: Create Your First PRD

You can either:

**Use an example:**
```bash
cp scripts/ralph/examples/simple-ui-fix.prd.json scripts/ralph/prd.json
# Edit prd.json to match your project
```

**Use the interactive creator:**
```bash
./scripts/ralph/create-prd-interactive.sh
```

**Create manually:**
```bash
cp scripts/ralph/prd.json.example scripts/ralph/prd.json
# Edit prd.json with your user stories
```

### Step 4: Validate Your PRD

```bash
./scripts/ralph/validate-prd.sh
```

This checks for:
- Missing fields
- Too-large stories
- Vague acceptance criteria

### Step 5: Test Ralph

Run a short test (1-2 iterations):

```bash
./scripts/ralph/ralph.sh 2
```

Watch the output to verify:
- Ralph reads the PRD correctly
- Quality checks run with your configured commands
- Browser testing works (if enabled)
- Session tracking captures the conversation ID
- Insights are extracted

---

## What Gets Customized?

### Required Customizations

1. **Quality check commands** - Your project's specific commands
   - Type checking
   - Linting
   - Formatting

### Optional Customizations

2. **Browser testing** - Only if you have UI/frontend work
   - Test credentials
   - Dev server URL

3. **Project patterns** - Coding conventions Ralph should follow
   - Backend patterns
   - Frontend patterns
   - Architecture decisions

### Not Needed

- **Scripts (.sh files)** - Already portable, no changes needed
- **Documentation** - Generic and doesn't need customization
- **Example PRDs** - You'll replace these with your own

---

## Common Setups

### Next.js + TypeScript Project

```markdown
**Quality Commands:**
1. Type Check: npm run type-check
2. Format & Lint: npm run lint
3. Lint Check: npm run lint

**Browser Testing:**
- Test credentials: testuser@myapp.com / testpass123
- Dev server URL: http://localhost:3000

**Project Patterns:**
- All routes scoped under `/app/`
- Use Server Components by default, Client Components only when needed
- API routes return `{ data, error }` format
- Use zod for input validation
```

### React + Vite + Express API

```markdown
**Quality Commands:**
1. Type Check: npm run type-check
2. Format & Lint: npm run lint:fix
3. Lint Check: npm run lint

**Browser Testing:**
- Test credentials: test@localhost / password
- Dev server URL: http://localhost:5173

**Project Patterns:**
- API base URL: http://localhost:3001
- Use React Query for data fetching
- All forms use React Hook Form + yup validation
- Components in src/components/, organized by feature
```

### Backend-Only (FastAPI/Django/Express)

```markdown
**Quality Commands:**
1. Type Check: mypy . (or npm run type-check)
2. Format & Lint: black . (or npm run lint:fix)
3. Lint Check: flake8 (or npm run lint)

**Browser Testing:**
- Not needed (backend-only)

**Project Patterns:**
- All endpoints must have OpenAPI docs
- Use Pydantic models for validation
- Follow RESTful conventions
- Tests require test database running
```

---

## Verification Checklist

After setup, verify:

- [ ] `prompt.md` has your quality check commands (not the defaults)
- [ ] `prompt.md` has your test credentials (if using browser testing)
- [ ] `prompt.md` has your project patterns (if you added any)
- [ ] You have a `prd.json` file ready to use
- [ ] All `.sh` scripts are executable (`chmod +x scripts/ralph/*.sh`)
- [ ] Ralph can access your dev server (if using browser testing)

---

## Troubleshooting

### "Command not found" errors

Ralph is trying to run quality check commands that don't exist in your project.

**Fix**: Update `prompt.md` with the correct commands for your project.

### Browser testing fails

**Possible causes:**
- Dev server not running
- Wrong URL in prompt.md
- Wrong credentials in prompt.md
- dev-browser not installed

**Fix**:
1. Start your dev server
2. Verify URL and credentials in prompt.md
3. Test browser access manually first

### "No session ID captured"

**Possible causes:**
- Path normalization issue
- Claude project directory not found

**Fix**:
- Session tracking is optional, Ralph will still work
- Check that `~/.claude/projects/` exists
- Run `./scripts/ralph/capture-session-id.sh` manually to diagnose

### PRD validation warnings

**Not necessarily an error** - Ralph can handle larger stories, they just might not complete in one iteration.

**Action**: Consider splitting large stories into smaller ones if you see warnings.

---

## Next Steps

1. ✅ Setup complete
2. Create your first real PRD (not a test)
3. Run Ralph: `./scripts/ralph/ralph.sh 10`
4. Monitor progress in `scripts/ralph/progress.txt`
5. Review commits after each iteration
6. Adjust PRD as needed based on learnings

Happy autonomous coding! 🤖

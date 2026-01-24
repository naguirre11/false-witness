# Ralph for Claude Code CLI

> Autonomous AI agent loop for feature development with a 4-layer learning system

Ralph automates software development by running Claude Code CLI in an iterative loop, implementing user stories one at a time while learning from its own progress.

**Lineage**: Originally conceived by [Geoffrey Huntley](https://ghuntley.com/ralph/), adapted for Amp CLI by [snarktank](https://github.com/snarktank/ralph), and now enhanced for Claude Code CLI with **automatic conversation tracking, insight extraction, and a superior 4-layer learning system**.

## ✨ Key Features

- 🔄 **Autonomous Iteration** - Runs until all PRD tasks complete
- 🧠 **4-Layer Learning System** - Patterns, progress logs, git history, and full conversation logs
- 📊 **Auto-Session Tracking** - Captures conversation IDs automatically
- 💡 **Auto-Insight Extraction** - Analyzes conversations for patterns and gotchas
- 🌐 **Browser Testing** - Visual verification for UI changes (optional)
- 📝 **Structured Learnings** - Future iterations learn from past mistakes
- 🎨 **Interactive Flowchart** - Visual walkthrough of Ralph's workflow

## 🚀 Quick Start

### 1. Install
```bash
# Clone into your project
cd /path/to/your/project
mkdir -p scripts
cd scripts
git clone https://github.com/ardmhacha24/ralph-claude-code.git ralph
cd ralph
```

### 2. Setup
```bash
# Option A: Interactive setup (recommended)
./init.sh

# Option B: Manual setup
# See SETUP.md for instructions
```

### 3. Create PRD
```bash
# Interactive creator
./create-prd-interactive.sh

# Or copy an example
cp examples/simple-ui-fix.prd.json prd.json
# Edit prd.json with your stories
```

### 4. Run
```bash
./ralph.sh 10
```

## 📚 Documentation

- **[SETUP.md](./SETUP.md)** - First-time setup instructions
- **[QUICKSTART.md](./QUICKSTART.md)** - Detailed getting started guide
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Technical deep dive
- **[LEARNING_SYSTEM.md](./LEARNING_SYSTEM.md)** - How the 4-layer learning works
- **[flowchart/](./flowchart/)** - Interactive visualization

### Learning System

**Layer 1: Codebase Patterns** - Consolidated wisdom, read first every iteration
**Layer 2: Progress Entries** - Structured learnings with session IDs
**Layer 3: Git History** - Actual code changes via `git show`
**Layer 4: Conversation Logs** - Full JSONL logs for deep debugging

## 📖 How It Works

1. **Fresh Context Per Iteration** - Each iteration is a new Claude instance
2. **Reads Previous Learnings** - 4-layer learning system prevents repeated mistakes
3. **Implements User Story** - Follows patterns from previous iterations
4. **Runs Quality Checks** - Type checking, linting, browser testing
5. **Commits & Documents** - Saves code and learnings for next iteration
6. **Auto-Captures Session** - Saves conversation ID and extracts insights
7. **Continues Until Done** - Moves to next story automatically

## 🎨 Interactive Flowchart

View the complete Ralph workflow visually:

```bash
cd flowchart
npm install
npm run dev
# Open http://localhost:5173
```

## 🔧 Requirements

- **Claude Code CLI** - Already installed if you're using Claude Code
- **jq** - JSON processor (usually pre-installed)
- **Git** - Version control
- **Node.js** - Only if using the flowchart visualization

## 💡 Example PRDs Included

- **simple-ui-fix.prd.json** - 3 simple stories (good for testing)
- **player-search.prd.json** - 4-story feature implementation
- **coach-dashboard-improvements.prd.json** - 6-story UI enhancement

## 🎓 Pro Tips

1. **Start Small** - Test with 1-2 story PRD first
2. **Keep Stories Focused** - Each should complete in one context window
3. **Monitor Progress** - Watch `progress.txt` between iterations
4. **Review Commits** - Check quality after each iteration
5. **Use Patterns Section** - Add discovered patterns to help future iterations

## 🛠️ Customization

Ralph needs minimal customization for your project:

**Required:**
- Quality check commands (type-check, lint)

**Optional:**
- Browser testing credentials (for UI work)
- Project-specific patterns (coding conventions)

The `init.sh` script guides you through all of this.

## 📊 Session Tracking & Insights

After each iteration, Ralph automatically:
- Captures the Claude conversation ID
- Logs to `session-history.txt`
- Extracts insights in background
- Saves to `insights/iteration-N-[session].md`

**Deep dive into any iteration:**
```bash
./parse-conversation.sh <session-id>
```

This shows:
- Errors encountered
- Files modified
- Commands executed
- Git commits
- Key decisions made

## 🤝 Contributing

Contributions welcome! This is the Claude Code CLI adaptation of Ralph, building on:
- [Geoffrey Huntley's original Ralph pattern](https://ghuntley.com/ralph/) - The foundational autonomous loop concept
- [snarktank's Amp CLI version](https://github.com/snarktank/ralph) - Thread tracking and 3-layer learning

Enhanced for Claude Code CLI with:
- Automatic session tracking via conversation IDs
- JSONL conversation parsing and analysis
- Background insight extraction after each iteration
- Superior 4-layer learning architecture
- Interactive setup wizard and comprehensive documentation

## 📄 License

Same as original Ralph project.

## 🙏 Credits

Ralph has evolved through three generations:

1. **Original Ralph Pattern** by [Geoffrey Huntley](https://ghuntley.com/ralph/)
   - Conceived the elegant autonomous loop concept: `while :; do cat PROMPT.md | claude-code ; done`
   - Introduced the idea of persistent memory through files between iterations
   - Article: [ghuntley.com/ralph](https://ghuntley.com/ralph/)

2. **Amp CLI Adaptation** by [snarktank (Ryan Carson)](https://github.com/snarktank/ralph)
   - Adapted Ralph for Amp CLI with thread URLs and skills system
   - Added 3-layer learning system and thread tracking
   - Repository: [github.com/snarktank/ralph](https://github.com/snarktank/ralph)

3. **This Claude Code CLI Version** by [Neil Barlow](https://github.com/ardmhacha24)
   - Enhanced with 4-layer learning system (added conversation log parsing)
   - Automatic session ID capture and insight extraction
   - Local JSONL conversation storage for deep debugging
   - Interactive setup wizard and comprehensive documentation
   - Browser testing integration and quality assurance framework

## 📞 Support

- Check the documentation in the `docs/` directory
- Review example PRDs in `examples/`
- Run `./validate-prd.sh` to check your PRD

---

**Ready to automate your feature development?** Run `./init.sh` to get started!

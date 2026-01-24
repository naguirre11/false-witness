# Ralph Flowchart Visualization

Interactive visualization showing how Ralph works with Claude Code CLI, featuring the 4-layer learning system.

## Features

- **Progressive Reveal**: Click "Next" to step through each phase of Ralph's workflow
- **Interactive Canvas**: Built with React Flow - drag, zoom, and pan
- **Color-Coded Phases**:
  - 🔵 **Setup** - Initial configuration and launch
  - 🟣 **Learning** - 4-layer learning system in action
  - ⚪ **Loop** - Core implementation iteration
  - 🟡 **Decision** - Workflow decision points
  - 🟢 **Done** - Completion state
- **Detailed Annotations**: Each step includes explanatory notes

## What It Shows

The flowchart visualizes Ralph's complete workflow:

1. **Setup Phase** (Steps 1-3)
   - Create PRD
   - Launch Ralph
   - Start iteration loop

2. **Four-Layer Learning System** (Steps 4-7)
   - Layer 1: Codebase Patterns
   - Layer 2: Progress Entries with Session IDs
   - Layer 3: Git History
   - Layer 4: Conversation Logs (NEW!)

3. **Implementation Loop** (Steps 8-13)
   - Pick user story
   - Implement using learned patterns
   - Quality checks
   - Commit code
   - Update PRD
   - Document learnings

4. **Post-Iteration** (Steps 14-15)
   - Capture session ID
   - Auto-extract insights

5. **Decision & Completion** (Steps 16-17)
   - Check for more stories
   - Loop back or exit

## Quick Start

### Install Dependencies

```bash
cd scripts/ralph/flowchart
npm install
```

### Run Development Server

```bash
npm run dev
```

Open http://localhost:5173 in your browser.

### Build for Production

```bash
npm run build
```

The built files will be in `dist/`.

## Usage

1. **Step Through**: Use "Next" and "Previous" buttons to see each phase
2. **View All**: Click "Show All" to see the complete flow at once
3. **Reset**: Start over from the beginning
4. **Explore**: Drag nodes, zoom in/out, pan around the canvas

## Technology Stack

- **React** - UI framework
- **TypeScript** - Type safety
- **React Flow** - Interactive flowchart library
- **Vite** - Build tool and dev server

## Customization

### Update the Workflow

Edit `src/App.tsx`:
- Modify `allNodes` array to change/add nodes
- Update `allEdges` array to change connections
- Edit `annotations` object to update step descriptions

### Change Styling

Edit `src/App.css`:
- Modify node colors
- Update layout/spacing
- Adjust annotation styles

## Comparison to Original Ralph

This flowchart is adapted from [snarktank/ralph](https://github.com/snarktank/ralph/tree/main/flowchart) but enhanced for Claude Code CLI:

| Feature | Original (Amp) | This (Claude Code) |
|---------|----------------|-------------------|
| Learning Layers | 3 layers | ✅ **4 layers** |
| Session Tracking | Thread URLs | ✅ **Session IDs + JSONL logs** |
| Insight Extraction | Manual | ✅ **Automatic** |
| Step Count | ~12 steps | **17 steps** (added learning details) |

## License

Same as the parent Ralph project.

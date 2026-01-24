import { useCallback, useState } from "react";
import ReactFlow, {
  Background,
  Controls,
  type Edge,
  MarkerType,
  type Node,
  useEdgesState,
  useNodesState,
} from "reactflow";
import "reactflow/dist/style.css";
import "./App.css";

// Define all nodes in the flowchart
const allNodes: Node[] = [
  // Setup Phase
  {
    id: "1",
    type: "default",
    data: { label: "1. Write PRD (prd.json)" },
    position: { x: 250, y: 50 },
    className: "setup",
  },
  {
    id: "2",
    type: "default",
    data: { label: "2. Run ralph.sh" },
    position: { x: 250, y: 150 },
    className: "setup",
  },
  {
    id: "3",
    type: "default",
    data: { label: "3. Start Iteration Loop" },
    position: { x: 250, y: 250 },
    className: "setup",
  },

  // Learning Phase (4-Layer System)
  {
    id: "4",
    type: "default",
    data: { label: "4. Read Layer 1: Codebase Patterns" },
    position: { x: 200, y: 370 },
    className: "learning",
  },
  {
    id: "5",
    type: "default",
    data: { label: "5. Read Layer 2: Progress Entries" },
    position: { x: 200, y: 470 },
    className: "learning",
  },
  {
    id: "6",
    type: "default",
    data: { label: "6. Read Layer 3: Git History" },
    position: { x: 200, y: 570 },
    className: "learning",
  },
  {
    id: "7",
    type: "default",
    data: { label: "7. (Optional) Layer 4: Conversation Logs" },
    position: { x: 200, y: 670 },
    className: "learning",
  },

  // Main Loop
  {
    id: "8",
    type: "default",
    data: { label: "8. Pick Incomplete User Story" },
    position: { x: 650, y: 370 },
    className: "loop",
  },
  {
    id: "9",
    type: "default",
    data: { label: "9. Implement Using Learned Patterns" },
    position: { x: 650, y: 470 },
    className: "loop",
  },
  {
    id: "10",
    type: "default",
    data: { label: "10. Run Quality Checks" },
    position: { x: 650, y: 570 },
    className: "loop",
  },
  {
    id: "11",
    type: "default",
    data: { label: "11. Commit If Passing" },
    position: { x: 650, y: 670 },
    className: "loop",
  },
  {
    id: "12",
    type: "default",
    data: { label: "12. Update prd.json" },
    position: { x: 650, y: 770 },
    className: "loop",
  },
  {
    id: "13",
    type: "default",
    data: { label: "13. Log to progress.txt" },
    position: { x: 650, y: 870 },
    className: "loop",
  },

  // Post-Iteration
  {
    id: "14",
    type: "default",
    data: { label: "14. Capture Session ID" },
    position: { x: 650, y: 970 },
    className: "learning",
  },
  {
    id: "15",
    type: "default",
    data: { label: "15. Extract Insights (Background)" },
    position: { x: 650, y: 1070 },
    className: "learning",
  },

  // Decision
  {
    id: "16",
    type: "default",
    data: { label: "More Stories?" },
    position: { x: 650, y: 1180 },
    className: "decision",
  },

  // Done
  {
    id: "17",
    type: "default",
    data: { label: "✅ All Complete!" },
    position: { x: 1050, y: 1180 },
    className: "done",
  },
];

// Define all edges
const allEdges: Edge[] = [
  {
    id: "e1-2",
    source: "1",
    target: "2",
    animated: false,
    markerEnd: { type: MarkerType.ArrowClosed },
  },
  {
    id: "e2-3",
    source: "2",
    target: "3",
    animated: false,
    markerEnd: { type: MarkerType.ArrowClosed },
  },
  {
    id: "e3-4",
    source: "3",
    target: "4",
    animated: false,
    markerEnd: { type: MarkerType.ArrowClosed },
  },
  {
    id: "e4-5",
    source: "4",
    target: "5",
    animated: false,
    markerEnd: { type: MarkerType.ArrowClosed },
  },
  {
    id: "e5-6",
    source: "5",
    target: "6",
    animated: false,
    markerEnd: { type: MarkerType.ArrowClosed },
  },
  {
    id: "e6-7",
    source: "6",
    target: "7",
    animated: false,
    markerEnd: { type: MarkerType.ArrowClosed },
  },
  {
    id: "e7-8",
    source: "7",
    target: "8",
    animated: false,
    markerEnd: { type: MarkerType.ArrowClosed },
  },
  {
    id: "e8-9",
    source: "8",
    target: "9",
    animated: false,
    markerEnd: { type: MarkerType.ArrowClosed },
  },
  {
    id: "e9-10",
    source: "9",
    target: "10",
    animated: false,
    markerEnd: { type: MarkerType.ArrowClosed },
  },
  {
    id: "e10-11",
    source: "10",
    target: "11",
    animated: false,
    markerEnd: { type: MarkerType.ArrowClosed },
  },
  {
    id: "e11-12",
    source: "11",
    target: "12",
    animated: false,
    markerEnd: { type: MarkerType.ArrowClosed },
  },
  {
    id: "e12-13",
    source: "12",
    target: "13",
    animated: false,
    markerEnd: { type: MarkerType.ArrowClosed },
  },
  {
    id: "e13-14",
    source: "13",
    target: "14",
    animated: false,
    markerEnd: { type: MarkerType.ArrowClosed },
  },
  {
    id: "e14-15",
    source: "14",
    target: "15",
    animated: false,
    markerEnd: { type: MarkerType.ArrowClosed },
  },
  {
    id: "e15-16",
    source: "15",
    target: "16",
    animated: false,
    markerEnd: { type: MarkerType.ArrowClosed },
  },
  {
    id: "e16-17",
    source: "16",
    target: "17",
    label: "No",
    animated: false,
    markerEnd: { type: MarkerType.ArrowClosed },
  },
  {
    id: "e16-4",
    source: "16",
    target: "4",
    label: "Yes",
    animated: false,
    markerEnd: { type: MarkerType.ArrowClosed },
    type: "smoothstep",
  },
];

// Annotations for each step
const annotations: Record<number, { title: string; content: string[] }> = {
  1: {
    title: "Create Your PRD",
    content: [
      "Define user stories in JSON format",
      "Each story has: id, title, priority, acceptance criteria",
      "Example: scripts/ralph/examples/player-search.prd.json",
    ],
  },
  2: {
    title: "Launch Ralph",
    content: [
      "Run: ./scripts/ralph/ralph.sh 10",
      "Ralph creates feature branch automatically",
      "Each iteration is a fresh Claude instance",
    ],
  },
  3: {
    title: "Iteration Loop Starts",
    content: [
      "Each iteration = fresh Claude Code CLI session",
      "No memory from previous iterations",
      "Learning happens via 4-layer system",
    ],
  },
  4: {
    title: "Layer 1: Codebase Patterns",
    content: [
      "Top section of progress.txt",
      "Consolidated wisdom from all iterations",
      "Architectural patterns, gotchas, conventions",
      "ALWAYS read this first!",
    ],
  },
  5: {
    title: "Layer 2: Progress Entries",
    content: [
      "Structured log per iteration with session IDs",
      "What worked, what failed, mistakes made",
      "Links to git commits and conversation logs",
      "Read last 3-5 entries for recent context",
    ],
  },
  6: {
    title: "Layer 3: Git History",
    content: [
      "git log --oneline -10",
      "git show [commit-hash]",
      "Actual code changes from previous iterations",
      "Ground truth for what was implemented",
    ],
  },
  7: {
    title: "Layer 4: Conversation Logs",
    content: [
      "Full JSONL logs of Claude conversations",
      "Auto-captured session IDs",
      "Parse with: ./scripts/ralph/parse-conversation.sh",
      "Deep dive when debugging complex issues",
    ],
  },
  8: {
    title: "Pick Next Story",
    content: [
      "Read prd.json",
      "Find highest priority story where passes: false",
      "Continue partial work if Status: Partial",
    ],
  },
  9: {
    title: "Implement Using Patterns",
    content: [
      "Apply learned patterns from Layer 1",
      "Avoid mistakes documented in Layer 2",
      "Reference git commits from Layer 3",
      "Check conversation logs if needed (Layer 4)",
    ],
  },
  10: {
    title: "Quality Checks",
    content: [
      "npm run check-types",
      "npm run check (linting)",
      "npx ultracite fix (formatting)",
      "Only commit if all checks pass",
    ],
  },
  11: {
    title: "Commit Code",
    content: [
      "Git commit with descriptive message",
      "Include user story ID in message",
      "Commit hash saved in progress.txt",
      "Co-authored by Claude Sonnet 4.5",
    ],
  },
  12: {
    title: "Update PRD",
    content: [
      "Set passes: true if story complete",
      "Keep passes: false if partial",
      "Ralph picks next incomplete story",
    ],
  },
  13: {
    title: "Document Learnings",
    content: [
      "What was implemented",
      "Patterns discovered",
      "Gotchas encountered",
      "Mistakes made (for future iterations!)",
      "Session ID for reference",
    ],
  },
  14: {
    title: "Capture Session ID",
    content: [
      "./scripts/ralph/capture-session-id.sh",
      "Finds current Claude conversation ID",
      "Example: 71aaf1aa-3b9c-4661-aee6-d60a7eea4ff6",
      "Logged to session-history.txt",
    ],
  },
  15: {
    title: "Auto-Extract Insights",
    content: [
      "Runs in background (non-blocking)",
      "./scripts/ralph/extract-insights.sh",
      "Analyzes JSONL conversation logs",
      "Saves to insights/iteration-N-[session].md",
      "Extracts: errors, patterns, gotchas, files",
    ],
  },
  16: {
    title: "Check Completion",
    content: [
      "Are there more incomplete stories?",
      "If yes: Start next iteration (fresh Claude instance)",
      "If no: Ralph exits with success",
    ],
  },
  17: {
    title: "Feature Complete!",
    content: [
      "All user stories have passes: true",
      "Code committed and quality checks passed",
      "Session history saved",
      "Insights extracted",
      "Ready to create pull request!",
    ],
  },
};

function App() {
  const [currentStep, setCurrentStep] = useState(0);
  const [nodes, setNodes, onNodesChange] = useNodesState([]);
  const [edges, setEdges, onEdgesChange] = useEdgesState([]);

  const showNextStep = useCallback(() => {
    if (currentStep < allNodes.length) {
      const nextStep = currentStep + 1;
      setNodes(allNodes.slice(0, nextStep));
      setEdges(
        allEdges
          .filter(
            (edge) =>
              allNodes.slice(0, nextStep).find((n) => n.id === edge.source) &&
              allNodes.slice(0, nextStep).find((n) => n.id === edge.target)
          )
          .map((edge, index) => ({
            ...edge,
            animated:
              index ===
              allEdges.filter(
                (e) =>
                  allNodes.slice(0, nextStep).find((n) => n.id === e.source) &&
                  allNodes.slice(0, nextStep).find((n) => n.id === e.target)
              ).length -
                1,
          }))
      );
      setCurrentStep(nextStep);
    }
  }, [currentStep, setNodes, setEdges]);

  const showPrevStep = useCallback(() => {
    if (currentStep > 0) {
      const prevStep = currentStep - 1;
      setNodes(allNodes.slice(0, prevStep));
      setEdges(
        allEdges.filter(
          (edge) =>
            allNodes.slice(0, prevStep).find((n) => n.id === edge.source) &&
            allNodes.slice(0, prevStep).find((n) => n.id === edge.target)
        )
      );
      setCurrentStep(prevStep);
    }
  }, [currentStep, setNodes, setEdges]);

  const reset = useCallback(() => {
    setNodes([]);
    setEdges([]);
    setCurrentStep(0);
  }, [setNodes, setEdges]);

  const showAll = useCallback(() => {
    setNodes(allNodes);
    setEdges(allEdges);
    setCurrentStep(allNodes.length);
  }, [setNodes, setEdges]);

  const currentAnnotation = annotations[currentStep];

  return (
    <div className="app-container">
      <div className="header">
        <h1>How Ralph Works with Claude Code CLI</h1>
        <p>
          Interactive visualization of the autonomous agent loop with 4-layer
          learning system
        </p>
      </div>

      <div className="controls">
        <button onClick={reset}>Reset</button>
        <button disabled={currentStep === 0} onClick={showPrevStep}>
          Previous
        </button>
        <button
          disabled={currentStep >= allNodes.length}
          onClick={showNextStep}
        >
          Next
        </button>
        <button onClick={showAll}>Show All</button>

        <span className="step-info">
          Step {currentStep} of {allNodes.length}
        </span>

        <div className="legend">
          <div className="legend-item">
            <div
              className="legend-color"
              style={{
                background: "linear-gradient(135deg, #3b82f6 0%, #2563eb 100%)",
              }}
            />
            <span>Setup</span>
          </div>
          <div className="legend-item">
            <div
              className="legend-color"
              style={{
                background: "linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%)",
              }}
            />
            <span>Learning</span>
          </div>
          <div className="legend-item">
            <div
              className="legend-color"
              style={{
                background: "linear-gradient(135deg, #6b7280 0%, #4b5563 100%)",
              }}
            />
            <span>Loop</span>
          </div>
          <div className="legend-item">
            <div
              className="legend-color"
              style={{
                background: "linear-gradient(135deg, #f59e0b 0%, #d97706 100%)",
              }}
            />
            <span>Decision</span>
          </div>
          <div className="legend-item">
            <div
              className="legend-color"
              style={{
                background: "linear-gradient(135deg, #10b981 0%, #059669 100%)",
              }}
            />
            <span>Done</span>
          </div>
        </div>
      </div>

      <div className="flow-container">
        <ReactFlow
          edges={edges}
          fitView
          maxZoom={1.5}
          minZoom={0.5}
          nodes={nodes}
          onEdgesChange={onEdgesChange}
          onNodesChange={onNodesChange}
        >
          <Controls />
          <Background />
        </ReactFlow>

        {currentAnnotation && (
          <div className="annotation" style={{ top: 100, left: 20 }}>
            <h3>{currentAnnotation.title}</h3>
            {currentAnnotation.content.map((line, index) => (
              <p key={index}>{line}</p>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

export default App;

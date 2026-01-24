"""
Coordinator: Routes messages between Orchestrator Claude and Agent Claude.

This is the thin Python layer that manages the two-Claude architecture.
"""

import subprocess
import json
import re
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum, auto
from pathlib import Path
from typing import List, Optional

from .config import Config
from .state_collector import StateCollector
from .token_tracker import TokenTracker, TokenUsage


class CompletionStatus(Enum):
    """Final status of the orchestration run."""
    SUCCESS = auto()
    BLOCKED = auto()
    MAX_ITERATIONS = auto()
    TOKEN_LIMIT = auto()
    ERROR = auto()


class OrchestratorAction(Enum):
    """Actions the Orchestrator can request."""
    AGENT_TASK = auto()  # Run the agent with a task
    DONE = auto()  # All work complete
    BLOCKED = auto()  # Need human intervention
    BREAK_DOWN_TICKET = auto()  # Agent should create tasks from ticket
    CONTINUE = auto()  # Continue with next available task


@dataclass
class OrchestratorDecision:
    """A decision made by the Orchestrator Claude."""
    action: OrchestratorAction
    agent_prompt: str = ""
    reasoning: str = ""
    task_id: Optional[str] = None
    raw_response: str = ""


@dataclass
class AgentResult:
    """Result from running the Agent Claude."""
    success: bool
    output: str
    task_completed: Optional[str] = None
    task_blocked: Optional[str] = None
    block_reason: str = ""
    commit_hash: Optional[str] = None
    files_changed: List[str] = field(default_factory=list)
    error: Optional[str] = None


class Coordinator:
    """Routes messages between Orchestrator Claude and Agent Claude."""

    def __init__(self, config: Config):
        self.config = config
        self.state = StateCollector(config)
        self.tokens = TokenTracker(
            warning_threshold=config.token_warning_threshold,
            limit=config.token_limit,
        )
        self.orchestrator_context: List[dict] = []
        self.iteration = 0

    def run(self, ticket_id: Optional[str] = None) -> CompletionStatus:
        """
        Main coordination loop.

        Args:
            ticket_id: Optional specific ticket to work on.
                      If None, uses the next ticket from the ready queue.
        """
        print(f"\n{'='*60}")
        print("Task Orchestrator Starting")
        print(f"{'='*60}\n")

        # Initial state
        initial_state = self._get_initial_state(ticket_id)
        print(f"Initial state:\n{initial_state}\n")

        for self.iteration in range(1, self.config.max_iterations + 1):
            print(f"\n--- Iteration {self.iteration} ---\n")

            # Check token limit
            if self.tokens.is_over_limit():
                print("Token limit exceeded. Stopping.")
                return CompletionStatus.TOKEN_LIMIT

            # 1. Collect current state
            state_summary = self.state.collect()

            # 2. Ask Orchestrator what to do
            decision = self._ask_orchestrator(state_summary)
            print(f"Orchestrator decision: {decision.action.name}")
            print(f"Reasoning: {decision.reasoning}")

            # 3. Handle decision
            if decision.action == OrchestratorAction.DONE:
                print("\nAll tasks complete!")
                self._print_summary()
                return CompletionStatus.SUCCESS

            if decision.action == OrchestratorAction.BLOCKED:
                print(f"\nBlocked: {decision.reasoning}")
                self._print_summary()
                return CompletionStatus.BLOCKED

            # 4. Run Agent Claude
            print(f"\nRunning agent with prompt:\n{decision.agent_prompt[:500]}...")
            agent_result = self._run_agent(decision.agent_prompt)

            # 5. Report results back to Orchestrator context
            self._update_orchestrator_context(decision, agent_result)

            # 6. Check for completion signals
            if agent_result.task_blocked:
                print(f"Agent blocked on task {agent_result.task_blocked}: {agent_result.block_reason}")

            if agent_result.error:
                print(f"Agent error: {agent_result.error}")

        print(f"\nMax iterations ({self.config.max_iterations}) reached.")
        self._print_summary()
        return CompletionStatus.MAX_ITERATIONS

    def _get_initial_state(self, ticket_id: Optional[str]) -> str:
        """Get initial state for the orchestration run."""
        lines = ["Initial Orchestration State", "=" * 30]

        # Task state
        tasks = self.state.get_tasks()
        if tasks:
            lines.append(f"\nExisting tasks: {len(tasks)}")
            pending = [t for t in tasks if t.status == "pending"]
            in_progress = [t for t in tasks if t.status == "in_progress"]
            completed = [t for t in tasks if t.status == "completed"]
            lines.append(f"  - Pending: {len(pending)}")
            lines.append(f"  - In Progress: {len(in_progress)}")
            lines.append(f"  - Completed: {len(completed)}")
        else:
            lines.append("\nNo existing tasks.")

        # Ticket state
        if ticket_id:
            lines.append(f"\nTarget ticket: {ticket_id}")
        else:
            next_ticket = self.state.get_next_ticket()
            if next_ticket:
                lines.append(f"\nNext ticket from queue: {next_ticket.id} - {next_ticket.title}")
            else:
                lines.append("\nNo tickets in ready queue.")

        return "\n".join(lines)

    def _ask_orchestrator(self, state: str) -> OrchestratorDecision:
        """Ask Orchestrator Claude what action to take."""
        # Build prompt
        prompt = self._build_orchestrator_prompt(state)

        # Run claude in headless mode
        try:
            result = subprocess.run(
                ["claude", "-p", prompt, "--output-format", "json"],
                capture_output=True,
                text=True,
                timeout=self.config.orchestrator_timeout,
                cwd=self.config.project_root,
            )

            if result.returncode != 0:
                print(f"Orchestrator error: {result.stderr}")
                return OrchestratorDecision(
                    action=OrchestratorAction.BLOCKED,
                    reasoning=f"Orchestrator invocation failed: {result.stderr}",
                )

            return self._parse_orchestrator_response(result.stdout)

        except subprocess.TimeoutExpired:
            return OrchestratorDecision(
                action=OrchestratorAction.BLOCKED,
                reasoning="Orchestrator timed out",
            )
        except Exception as e:
            return OrchestratorDecision(
                action=OrchestratorAction.BLOCKED,
                reasoning=f"Orchestrator error: {e}",
            )

    def _build_orchestrator_prompt(self, state: str) -> str:
        """Build the prompt for Orchestrator Claude."""
        context_str = ""
        if self.orchestrator_context:
            context_str = "\n\n## Previous Actions\n"
            for ctx in self.orchestrator_context[-5:]:  # Last 5 actions
                context_str += f"\n{ctx.get('summary', '')}\n"

        return f"""You are the Orchestrator in a two-Claude task execution system.
Your role is to direct an Agent Claude to complete tasks efficiently.

## Current State
{state}
{context_str}

## Your Decision

Analyze the state and decide what the Agent should do next.
Respond in this exact format:

ACTION: [AGENT_TASK | DONE | BLOCKED | BREAK_DOWN_TICKET]
TASK_ID: [task ID if applicable, or "none"]
REASONING: [1-2 sentences explaining why]
AGENT_PROMPT: [detailed instructions for Agent Claude, or "none" if DONE/BLOCKED]

### Action Types:
- AGENT_TASK: Agent should work on a specific task
- DONE: All tasks are complete, no more work needed
- BLOCKED: Cannot proceed, need human intervention
- BREAK_DOWN_TICKET: Agent should create tasks from a ticket

### Guidelines:
1. If there are in_progress tasks, continue those first
2. If there are pending unblocked tasks, work on them
3. If no tasks exist but there's a ticket, break it down into tasks
4. If all tasks are complete, return DONE
5. If stuck with no way forward, return BLOCKED

Be specific in AGENT_PROMPT - tell the Agent exactly what to do.
"""

    def _parse_orchestrator_response(self, response: str) -> OrchestratorDecision:
        """Parse the Orchestrator's response into a decision."""
        # Try to parse JSON output format
        try:
            data = json.loads(response)
            text = data.get("result", response)
        except json.JSONDecodeError:
            text = response

        # Extract fields using regex
        action_match = re.search(r"ACTION:\s*(\w+)", text)
        task_id_match = re.search(r"TASK_ID:\s*(\S+)", text)
        reasoning_match = re.search(r"REASONING:\s*(.+?)(?=AGENT_PROMPT:|$)", text, re.DOTALL)
        prompt_match = re.search(r"AGENT_PROMPT:\s*(.+)", text, re.DOTALL)

        action_str = action_match.group(1) if action_match else "BLOCKED"
        task_id = task_id_match.group(1) if task_id_match else None
        if task_id == "none":
            task_id = None
        reasoning = reasoning_match.group(1).strip() if reasoning_match else ""
        agent_prompt = prompt_match.group(1).strip() if prompt_match else ""
        if agent_prompt == "none":
            agent_prompt = ""

        # Map action string to enum
        action_map = {
            "AGENT_TASK": OrchestratorAction.AGENT_TASK,
            "DONE": OrchestratorAction.DONE,
            "BLOCKED": OrchestratorAction.BLOCKED,
            "BREAK_DOWN_TICKET": OrchestratorAction.BREAK_DOWN_TICKET,
            "CONTINUE": OrchestratorAction.CONTINUE,
        }
        action = action_map.get(action_str.upper(), OrchestratorAction.BLOCKED)

        return OrchestratorDecision(
            action=action,
            agent_prompt=agent_prompt,
            reasoning=reasoning,
            task_id=task_id,
            raw_response=text,
        )

    def _run_agent(self, prompt: str) -> AgentResult:
        """Run Agent Claude with the given prompt."""
        # Add standard instructions to the prompt
        full_prompt = f"""{prompt}

## Completion Signals
When you complete a task, output: <task_complete>TASK_ID</task_complete>
If you get blocked, output: <task_blocked>TASK_ID: reason</task_blocked>

## Important
- Use TaskUpdate to mark tasks in_progress when starting
- Use TaskUpdate to mark tasks completed when done
- Commit your changes with descriptive messages
- If you run out of context, commit partial progress and document what's left
"""

        try:
            result = subprocess.run(
                ["claude", "-p", full_prompt],
                capture_output=True,
                text=True,
                timeout=self.config.agent_timeout,
                cwd=self.config.project_root,
            )

            output = result.stdout
            if result.returncode != 0:
                return AgentResult(
                    success=False,
                    output=output,
                    error=f"Agent returned non-zero exit code: {result.returncode}\n{result.stderr}",
                )

            # Parse completion signals
            task_completed = None
            task_blocked = None
            block_reason = ""

            complete_match = re.search(r"<task_complete>(\S+)</task_complete>", output)
            if complete_match:
                task_completed = complete_match.group(1)

            blocked_match = re.search(r"<task_blocked>(\S+):\s*(.+?)</task_blocked>", output)
            if blocked_match:
                task_blocked = blocked_match.group(1)
                block_reason = blocked_match.group(2)

            # Extract commit hash if present
            commit_match = re.search(r"\[[\w-]+\s+([a-f0-9]{7,})\]", output)
            commit_hash = commit_match.group(1) if commit_match else None

            return AgentResult(
                success=True,
                output=output,
                task_completed=task_completed,
                task_blocked=task_blocked,
                block_reason=block_reason,
                commit_hash=commit_hash,
            )

        except subprocess.TimeoutExpired:
            return AgentResult(
                success=False,
                output="",
                error="Agent timed out",
            )
        except Exception as e:
            return AgentResult(
                success=False,
                output="",
                error=f"Agent error: {e}",
            )

    def _update_orchestrator_context(
        self,
        decision: OrchestratorDecision,
        result: AgentResult,
    ) -> None:
        """Update the Orchestrator's context with the latest action/result."""
        summary = f"""
### Iteration {self.iteration}
**Action**: {decision.action.name}
**Task**: {decision.task_id or 'N/A'}
**Result**: {'Success' if result.success else 'Failed'}
"""
        if result.task_completed:
            summary += f"\n**Completed**: {result.task_completed}"
        if result.task_blocked:
            summary += f"\n**Blocked**: {result.task_blocked} - {result.block_reason}"
        if result.commit_hash:
            summary += f"\n**Commit**: {result.commit_hash}"
        if result.error:
            summary += f"\n**Error**: {result.error}"

        # Truncate output for context
        output_preview = result.output[:1000] if result.output else ""
        if len(result.output) > 1000:
            output_preview += "... [truncated]"

        self.orchestrator_context.append({
            "iteration": self.iteration,
            "action": decision.action.name,
            "task_id": decision.task_id,
            "success": result.success,
            "summary": summary,
            "output_preview": output_preview,
        })

    def _print_summary(self) -> None:
        """Print a summary of the orchestration run."""
        print("\n" + "=" * 60)
        print("Orchestration Summary")
        print("=" * 60)
        print(f"Iterations: {self.iteration}")
        print(f"Token usage: {self.tokens.total_tokens:,}")

        # Task summary
        tasks = self.state.get_tasks()
        completed = [t for t in tasks if t.status == "completed"]
        pending = [t for t in tasks if t.status == "pending"]
        in_progress = [t for t in tasks if t.status == "in_progress"]

        print(f"\nTasks:")
        print(f"  Completed: {len(completed)}")
        print(f"  In Progress: {len(in_progress)}")
        print(f"  Pending: {len(pending)}")

        if completed:
            print("\nCompleted tasks:")
            for t in completed:
                print(f"  - {t.id}: {t.subject}")

        print("=" * 60)

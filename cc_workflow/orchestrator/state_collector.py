"""
State collector for gathering context for Orchestrator Claude.
"""

import json
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional

from .config import Config


@dataclass
class Task:
    """Representation of a task from the persistent task system."""

    id: str
    subject: str
    description: str
    status: str  # pending, in_progress, completed
    owner: Optional[str] = None
    blocked_by: List[str] = None
    blocks: List[str] = None
    metadata: dict = None

    def __post_init__(self):
        if self.blocked_by is None:
            self.blocked_by = []
        if self.blocks is None:
            self.blocks = []
        if self.metadata is None:
            self.metadata = {}

    @property
    def is_available(self) -> bool:
        """Check if task can be worked on (pending, unowned, unblocked)."""
        return (
            self.status == "pending"
            and not self.owner
            and not self.blocked_by
        )


@dataclass
class Ticket:
    """Representation of a ticket from the ticket system."""

    id: str
    title: str
    priority: str
    status: str  # draft, ready, dev_in_progress, for_review, completed
    path: Path
    content: str = ""


class StateCollector:
    """Collects state information for Orchestrator Claude's context."""

    def __init__(self, config: Config):
        self.config = config

    def collect(self) -> str:
        """Gather current state summary for Orchestrator."""
        sections = [
            "# Current State",
            "",
            "## Task List",
            self.get_task_summary(),
            "",
            "## Active Ticket",
            self.get_active_ticket(),
            "",
            "## Git Status",
            self.get_git_status(),
            "",
            "## Recent Commits",
            self.get_recent_commits(),
            "",
        ]

        patterns = self.get_patterns()
        if patterns:
            sections.extend([
                "## Learned Patterns",
                patterns,
                "",
            ])

        return "\n".join(sections)

    def get_tasks(self) -> List[Task]:
        """Read all tasks from the task directory."""
        tasks = []
        task_dir = self.config.task_dir

        if not task_dir.exists():
            return tasks

        for f in task_dir.glob("*.json"):
            try:
                data = json.loads(f.read_text())
                tasks.append(Task(
                    id=data.get("id", f.stem),
                    subject=data.get("subject", ""),
                    description=data.get("description", ""),
                    status=data.get("status", "pending"),
                    owner=data.get("owner"),
                    blocked_by=data.get("blockedBy", []),
                    blocks=data.get("blocks", []),
                    metadata=data.get("metadata", {}),
                ))
            except (json.JSONDecodeError, KeyError) as e:
                print(f"Warning: Could not parse task file {f}: {e}")

        return tasks

    def get_task_summary(self) -> str:
        """Get a formatted summary of all tasks."""
        tasks = self.get_tasks()

        if not tasks:
            return "No tasks created yet."

        lines = []
        # Group by status
        for status in ["in_progress", "pending", "completed"]:
            status_tasks = [t for t in tasks if t.status == status]
            if status_tasks:
                lines.append(f"\n### {status.replace('_', ' ').title()}")
                for t in status_tasks:
                    blocked = f" [BLOCKED by: {', '.join(t.blocked_by)}]" if t.blocked_by else ""
                    owner = f" (@{t.owner})" if t.owner else ""
                    lines.append(f"- #{t.id} {t.subject}{owner}{blocked}")

        return "\n".join(lines) if lines else "No tasks found."

    def get_pending_tasks(self) -> List[Task]:
        """Get tasks that are available to work on."""
        tasks = self.get_tasks()
        return [t for t in tasks if t.is_available]

    def get_in_progress_tasks(self) -> List[Task]:
        """Get tasks currently being worked on."""
        tasks = self.get_tasks()
        return [t for t in tasks if t.status == "in_progress"]

    def get_active_ticket(self) -> str:
        """Check dev_in_progress folder for active ticket."""
        in_progress_dir = self.config.project_root / "tickets" / "dev_in_progress"

        if not in_progress_dir.exists():
            return "No active ticket (dev_in_progress folder not found)"

        tickets = list(in_progress_dir.glob("*.md"))
        if not tickets:
            return "No active ticket"

        # Read first ticket found
        ticket_path = tickets[0]
        content = ticket_path.read_text()

        # Extract title from frontmatter or filename
        lines = content.split("\n")
        title = ticket_path.stem
        for line in lines:
            if line.startswith("title:"):
                title = line.replace("title:", "").strip().strip('"')
                break

        return f"**{ticket_path.stem}**: {title}\n\nPath: {ticket_path}"

    def get_next_ticket(self) -> Optional[Ticket]:
        """Get the next ticket from the ready queue."""
        ready_dir = self.config.project_root / "tickets" / "ready"

        if not ready_dir.exists():
            return None

        # Check PRIORITIZATION_ROADMAP.md for NEXT marker
        roadmap_path = self.config.project_root / "tickets" / "PRIORITIZATION_ROADMAP.md"
        next_ticket_id = None

        if roadmap_path.exists():
            content = roadmap_path.read_text()
            for line in content.split("\n"):
                if "NEXT:" in line:
                    # Extract ticket ID (e.g., "NEXT: FW-061")
                    parts = line.split("NEXT:")
                    if len(parts) > 1:
                        next_ticket_id = parts[1].strip().split()[0]
                        break

        # Find the ticket file
        for ticket_path in ready_dir.glob("*.md"):
            if next_ticket_id and next_ticket_id in ticket_path.stem:
                content = ticket_path.read_text()
                title = self._extract_title(content, ticket_path.stem)
                return Ticket(
                    id=ticket_path.stem,
                    title=title,
                    priority="high",
                    status="ready",
                    path=ticket_path,
                    content=content,
                )

        # Fall back to first ready ticket
        tickets = list(ready_dir.glob("*.md"))
        if tickets:
            ticket_path = tickets[0]
            content = ticket_path.read_text()
            title = self._extract_title(content, ticket_path.stem)
            return Ticket(
                id=ticket_path.stem,
                title=title,
                priority="medium",
                status="ready",
                path=ticket_path,
                content=content,
            )

        return None

    def _extract_title(self, content: str, default: str) -> str:
        """Extract title from ticket frontmatter."""
        for line in content.split("\n"):
            if line.startswith("title:"):
                return line.replace("title:", "").strip().strip('"')
        return default

    def get_git_status(self) -> str:
        """Get current git status."""
        try:
            result = subprocess.run(
                ["git", "status", "--short"],
                capture_output=True,
                text=True,
                cwd=self.config.project_root,
                timeout=10,
            )
            status = result.stdout.strip()
            return status if status else "Working tree clean"
        except (subprocess.TimeoutExpired, FileNotFoundError):
            return "Unable to get git status"

    def get_recent_commits(self, n: int = 5) -> str:
        """Get recent commit summaries."""
        try:
            result = subprocess.run(
                ["git", "log", f"-{n}", "--oneline"],
                capture_output=True,
                text=True,
                cwd=self.config.project_root,
                timeout=10,
            )
            return result.stdout.strip() or "No commits found"
        except (subprocess.TimeoutExpired, FileNotFoundError):
            return "Unable to get git log"

    def get_patterns(self) -> str:
        """Get learned patterns from patterns file."""
        if self.config.patterns_file and self.config.patterns_file.exists():
            content = self.config.patterns_file.read_text()
            # Return first 50 lines (most important patterns)
            lines = content.split("\n")[:50]
            return "\n".join(lines)
        return ""

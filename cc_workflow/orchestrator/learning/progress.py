"""
Layer 2: Progress Log

Append-only log of iteration results. Provides chronological
record of what was done and learned.
"""

from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import List, Optional
import json


@dataclass
class ProgressEntry:
    """A single entry in the progress log."""

    timestamp: datetime
    iteration: int
    task_id: str
    status: str  # completed, partial, failed, blocked
    summary: str
    files_changed: List[str]
    commit_hash: Optional[str]
    learnings: str
    duration_seconds: Optional[float] = None

    def to_markdown(self) -> str:
        """Format as markdown for the log."""
        files_str = "\n".join(f"  - {f}" for f in self.files_changed) if self.files_changed else "  (none)"

        return f"""
## [{self.timestamp.strftime('%Y-%m-%d %H:%M:%S')}] Iteration {self.iteration} - {self.task_id}

**Status**: {self.status}
**Commit**: {self.commit_hash or 'N/A'}
{f'**Duration**: {self.duration_seconds:.1f}s' if self.duration_seconds else ''}

### Summary
{self.summary}

### Files Changed
{files_str}

### Learnings
{self.learnings or '(none recorded)'}

---
"""

    def to_dict(self) -> dict:
        """Convert to dictionary for JSON serialization."""
        return {
            "timestamp": self.timestamp.isoformat(),
            "iteration": self.iteration,
            "task_id": self.task_id,
            "status": self.status,
            "summary": self.summary,
            "files_changed": self.files_changed,
            "commit_hash": self.commit_hash,
            "learnings": self.learnings,
            "duration_seconds": self.duration_seconds,
        }

    @classmethod
    def from_dict(cls, data: dict) -> "ProgressEntry":
        """Create from dictionary."""
        return cls(
            timestamp=datetime.fromisoformat(data["timestamp"]),
            iteration=data["iteration"],
            task_id=data["task_id"],
            status=data["status"],
            summary=data["summary"],
            files_changed=data.get("files_changed", []),
            commit_hash=data.get("commit_hash"),
            learnings=data.get("learnings", ""),
            duration_seconds=data.get("duration_seconds"),
        )


class ProgressLog:
    """
    Append-only log of iteration results.

    Maintains both a human-readable markdown log and a
    machine-readable JSON log for analysis.
    """

    def __init__(self, log_dir: Path):
        self.log_dir = log_dir
        self.log_dir.mkdir(parents=True, exist_ok=True)

        self.markdown_path = log_dir / "progress.md"
        self.json_path = log_dir / "progress.jsonl"

        self._init_markdown()

    def _init_markdown(self) -> None:
        """Initialize markdown file with header if new."""
        if not self.markdown_path.exists():
            header = f"""# Progress Log

Chronological record of orchestration iterations.
Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

---
"""
            self.markdown_path.write_text(header)

    def record(self, entry: ProgressEntry) -> None:
        """Record a progress entry to both logs."""
        # Append to markdown
        with open(self.markdown_path, "a") as f:
            f.write(entry.to_markdown())

        # Append to JSONL
        with open(self.json_path, "a") as f:
            f.write(json.dumps(entry.to_dict()) + "\n")

    def record_iteration(
        self,
        iteration: int,
        task_id: str,
        status: str,
        summary: str,
        files_changed: List[str] = None,
        commit_hash: Optional[str] = None,
        learnings: str = "",
        duration_seconds: Optional[float] = None,
    ) -> ProgressEntry:
        """Convenience method to record an iteration result."""
        entry = ProgressEntry(
            timestamp=datetime.now(),
            iteration=iteration,
            task_id=task_id,
            status=status,
            summary=summary,
            files_changed=files_changed or [],
            commit_hash=commit_hash,
            learnings=learnings,
            duration_seconds=duration_seconds,
        )
        self.record(entry)
        return entry

    def get_recent(self, n: int = 10) -> List[ProgressEntry]:
        """Get the most recent n entries."""
        if not self.json_path.exists():
            return []

        entries = []
        with open(self.json_path) as f:
            for line in f:
                if line.strip():
                    try:
                        entries.append(ProgressEntry.from_dict(json.loads(line)))
                    except (json.JSONDecodeError, KeyError):
                        continue

        return entries[-n:]

    def get_by_task(self, task_id: str) -> List[ProgressEntry]:
        """Get all entries for a specific task."""
        if not self.json_path.exists():
            return []

        entries = []
        with open(self.json_path) as f:
            for line in f:
                if line.strip():
                    try:
                        entry = ProgressEntry.from_dict(json.loads(line))
                        if entry.task_id == task_id:
                            entries.append(entry)
                    except (json.JSONDecodeError, KeyError):
                        continue

        return entries

    def get_summary(self) -> str:
        """Get a summary of the progress log."""
        entries = self.get_recent(100)  # Last 100 entries

        if not entries:
            return "No progress entries recorded."

        total = len(entries)
        completed = sum(1 for e in entries if e.status == "completed")
        partial = sum(1 for e in entries if e.status == "partial")
        failed = sum(1 for e in entries if e.status == "failed")
        blocked = sum(1 for e in entries if e.status == "blocked")

        unique_tasks = len(set(e.task_id for e in entries))

        return f"""
Progress Summary
================
Total iterations: {total}
Unique tasks touched: {unique_tasks}

Outcomes:
  - Completed: {completed}
  - Partial: {partial}
  - Failed: {failed}
  - Blocked: {blocked}

Time span: {entries[0].timestamp.strftime('%Y-%m-%d %H:%M')} to {entries[-1].timestamp.strftime('%Y-%m-%d %H:%M')}
"""

    def extract_learnings(self) -> List[str]:
        """Extract all non-empty learnings from the log."""
        if not self.json_path.exists():
            return []

        learnings = []
        with open(self.json_path) as f:
            for line in f:
                if line.strip():
                    try:
                        data = json.loads(line)
                        if data.get("learnings"):
                            learnings.append(data["learnings"])
                    except json.JSONDecodeError:
                        continue

        return learnings

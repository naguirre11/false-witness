"""
Layer 3: Git History

Extract context from recent commits to understand what has been done.
"""

import subprocess
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import List, Optional


@dataclass
class CommitInfo:
    """Information about a git commit."""

    hash: str
    short_hash: str
    author: str
    date: datetime
    message: str
    files_changed: List[str]

    @property
    def summary(self) -> str:
        """Get one-line summary."""
        return f"{self.short_hash} {self.message.split(chr(10))[0]}"


class GitHistoryAnalyzer:
    """Extract context from recent commits."""

    def __init__(self, repo_path: Path):
        self.repo_path = repo_path

    def _run_git(self, *args) -> str:
        """Run a git command and return output."""
        try:
            result = subprocess.run(
                ["git"] + list(args),
                capture_output=True,
                text=True,
                cwd=self.repo_path,
                timeout=30,
            )
            return result.stdout.strip()
        except (subprocess.TimeoutExpired, FileNotFoundError):
            return ""

    def get_recent_commits(self, n: int = 10) -> List[CommitInfo]:
        """Get the most recent n commits."""
        # Get commit info in a parseable format
        format_str = "%H%n%h%n%an%n%aI%n%s%n---COMMIT---"
        output = self._run_git("log", f"-{n}", f"--format={format_str}")

        if not output:
            return []

        commits = []
        for block in output.split("---COMMIT---"):
            lines = block.strip().split("\n")
            if len(lines) >= 5:
                try:
                    commit = CommitInfo(
                        hash=lines[0],
                        short_hash=lines[1],
                        author=lines[2],
                        date=datetime.fromisoformat(lines[3]),
                        message=lines[4],
                        files_changed=[],
                    )
                    commits.append(commit)
                except (IndexError, ValueError):
                    continue

        return commits

    def get_commit_files(self, commit_hash: str) -> List[str]:
        """Get files changed in a specific commit."""
        output = self._run_git("diff-tree", "--no-commit-id", "--name-only", "-r", commit_hash)
        return [f for f in output.split("\n") if f.strip()]

    def get_recent_changes(self, n: int = 5) -> str:
        """Return formatted summary of recent commits."""
        commits = self.get_recent_commits(n)

        if not commits:
            return "No recent commits found."

        lines = ["Recent Commits:", ""]
        for c in commits:
            lines.append(f"- {c.short_hash} ({c.date.strftime('%Y-%m-%d')}) {c.message}")

        return "\n".join(lines)

    def get_commit_for_task(self, task_id: str) -> Optional[CommitInfo]:
        """Find commit associated with a task ID."""
        commits = self.get_recent_commits(50)  # Search last 50 commits

        for commit in commits:
            if task_id.lower() in commit.message.lower():
                commit.files_changed = self.get_commit_files(commit.hash)
                return commit

        return None

    def get_commits_for_ticket(self, ticket_id: str) -> List[CommitInfo]:
        """Find all commits associated with a ticket ID (e.g., FW-061)."""
        commits = self.get_recent_commits(100)

        matching = []
        for commit in commits:
            if ticket_id.lower() in commit.message.lower():
                commit.files_changed = self.get_commit_files(commit.hash)
                matching.append(commit)

        return matching

    def get_files_changed_since(self, since: str = "1 week ago") -> List[str]:
        """Get all files changed since a given time."""
        output = self._run_git("log", f"--since={since}", "--name-only", "--format=")
        files = set()
        for line in output.split("\n"):
            if line.strip():
                files.add(line.strip())
        return sorted(files)

    def get_current_branch(self) -> str:
        """Get the current branch name."""
        return self._run_git("branch", "--show-current")

    def get_uncommitted_changes(self) -> List[str]:
        """Get list of uncommitted changed files."""
        output = self._run_git("status", "--porcelain")
        files = []
        for line in output.split("\n"):
            if line.strip():
                # Format is "XY filename" where XY is status
                parts = line.split(maxsplit=1)
                if len(parts) > 1:
                    files.append(parts[1])
        return files

    def get_diff_summary(self, base: str = "HEAD~5") -> str:
        """Get summary of changes since base commit."""
        stat = self._run_git("diff", "--stat", base)
        return stat if stat else "No changes"

    def analyze_patterns(self) -> str:
        """Analyze commit patterns for insights."""
        commits = self.get_recent_commits(50)

        if not commits:
            return "Insufficient commit history for analysis."

        # Analyze commit message patterns
        prefixes = {}
        for c in commits:
            msg = c.message.lower()
            if ":" in msg:
                prefix = msg.split(":")[0]
                prefixes[prefix] = prefixes.get(prefix, 0) + 1

        # Find most common files touched
        all_files = []
        for c in commits[:20]:
            c.files_changed = self.get_commit_files(c.hash)
            all_files.extend(c.files_changed)

        file_counts = {}
        for f in all_files:
            file_counts[f] = file_counts.get(f, 0) + 1

        hot_files = sorted(file_counts.items(), key=lambda x: -x[1])[:10]

        lines = [
            "Git Pattern Analysis",
            "===================",
            "",
            "Commit prefixes used:",
        ]
        for prefix, count in sorted(prefixes.items(), key=lambda x: -x[1])[:5]:
            lines.append(f"  {prefix}: {count}")

        lines.extend([
            "",
            "Most frequently changed files:",
        ])
        for f, count in hot_files:
            lines.append(f"  {f}: {count} commits")

        return "\n".join(lines)

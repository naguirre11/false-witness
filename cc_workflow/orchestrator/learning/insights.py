"""
Layer 4: Session Insights

Parse Claude session JSONL files to extract patterns, errors,
and learnings from previous sessions.
"""

import json
import re
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import List, Optional, Set


@dataclass
class SessionInsight:
    """An insight extracted from a session."""

    category: str  # error, pattern, gotcha, success
    content: str
    context: str = ""
    timestamp: Optional[datetime] = None
    confidence: float = 1.0


@dataclass
class SessionSummary:
    """Summary of a parsed session."""

    session_id: str
    start_time: Optional[datetime]
    end_time: Optional[datetime]
    message_count: int
    tool_calls: List[str]
    errors: List[str]
    insights: List[SessionInsight] = field(default_factory=list)


class InsightExtractor:
    """
    Parse Claude session JSONL files to extract patterns and insights.

    Session files are located at:
    ~/.claude/projects/<project-hash>/<session-id>.jsonl
    """

    # Patterns to detect in session content
    ERROR_PATTERNS = [
        r"Error:?\s+(.+)",
        r"Exception:?\s+(.+)",
        r"failed:?\s+(.+)",
        r"cannot\s+(.+)",
        r"unable to\s+(.+)",
    ]

    GOTCHA_PATTERNS = [
        r"(?:note|important|remember|gotcha):?\s+(.+)",
        r"(?:turns out|actually|it seems)\s+(.+)",
        r"(?:the problem was|issue was|bug was)\s+(.+)",
    ]

    SUCCESS_PATTERNS = [
        r"(?:fixed|resolved|completed|done):?\s+(.+)",
        r"(?:tests pass|all tests|tests are green)",
        r"(?:commit|committed)\s+([a-f0-9]{7,})",
    ]

    def __init__(self, projects_dir: Optional[Path] = None):
        if projects_dir is None:
            projects_dir = Path.home() / ".claude" / "projects"
        self.projects_dir = projects_dir

    def find_session_files(self, project_hash: Optional[str] = None) -> List[Path]:
        """Find all session JSONL files."""
        if not self.projects_dir.exists():
            return []

        if project_hash:
            project_dir = self.projects_dir / project_hash
            if project_dir.exists():
                return list(project_dir.glob("*.jsonl"))
            return []

        # Search all projects
        return list(self.projects_dir.glob("*/*.jsonl"))

    def parse_session(self, session_path: Path) -> SessionSummary:
        """Parse a session JSONL file."""
        session_id = session_path.stem
        messages = []
        tool_calls = []
        errors = []
        start_time = None
        end_time = None

        try:
            with open(session_path) as f:
                for line in f:
                    if not line.strip():
                        continue
                    try:
                        entry = json.loads(line)
                        messages.append(entry)

                        # Extract timestamp
                        ts = entry.get("timestamp")
                        if ts:
                            dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
                            if start_time is None:
                                start_time = dt
                            end_time = dt

                        # Extract tool calls
                        if entry.get("type") == "tool_use":
                            tool_calls.append(entry.get("name", "unknown"))

                        # Look for errors in content
                        content = str(entry.get("content", ""))
                        for pattern in self.ERROR_PATTERNS:
                            matches = re.findall(pattern, content, re.IGNORECASE)
                            errors.extend(matches[:3])  # Limit per pattern

                    except json.JSONDecodeError:
                        continue

        except IOError as e:
            print(f"Warning: Could not read session file {session_path}: {e}")

        return SessionSummary(
            session_id=session_id,
            start_time=start_time,
            end_time=end_time,
            message_count=len(messages),
            tool_calls=tool_calls,
            errors=errors[:20],  # Limit total errors
        )

    def extract_insights(self, session_path: Path) -> List[SessionInsight]:
        """Extract insights from a session file."""
        insights = []

        try:
            with open(session_path) as f:
                for line in f:
                    if not line.strip():
                        continue
                    try:
                        entry = json.loads(line)
                        content = str(entry.get("content", ""))

                        # Extract timestamp
                        ts = entry.get("timestamp")
                        timestamp = None
                        if ts:
                            try:
                                timestamp = datetime.fromisoformat(ts.replace("Z", "+00:00"))
                            except ValueError:
                                pass

                        # Check for error patterns
                        for pattern in self.ERROR_PATTERNS:
                            for match in re.finditer(pattern, content, re.IGNORECASE):
                                insights.append(SessionInsight(
                                    category="error",
                                    content=match.group(1)[:200],
                                    context=content[max(0, match.start()-50):match.end()+50],
                                    timestamp=timestamp,
                                ))

                        # Check for gotcha patterns
                        for pattern in self.GOTCHA_PATTERNS:
                            for match in re.finditer(pattern, content, re.IGNORECASE):
                                insights.append(SessionInsight(
                                    category="gotcha",
                                    content=match.group(1)[:200] if match.lastindex else match.group(0)[:200],
                                    timestamp=timestamp,
                                ))

                        # Check for success patterns
                        for pattern in self.SUCCESS_PATTERNS:
                            for match in re.finditer(pattern, content, re.IGNORECASE):
                                insights.append(SessionInsight(
                                    category="success",
                                    content=match.group(0)[:200],
                                    timestamp=timestamp,
                                ))

                    except json.JSONDecodeError:
                        continue

        except IOError:
            pass

        return insights

    def extract_from_session(self, session_id: str) -> List[SessionInsight]:
        """Extract insights from a specific session by ID."""
        for session_path in self.find_session_files():
            if session_path.stem == session_id:
                return self.extract_insights(session_path)
        return []

    def get_recent_sessions(self, n: int = 5) -> List[SessionSummary]:
        """Get summaries of the most recent n sessions."""
        session_files = self.find_session_files()

        # Sort by modification time
        session_files.sort(key=lambda p: p.stat().st_mtime, reverse=True)

        summaries = []
        for path in session_files[:n]:
            summaries.append(self.parse_session(path))

        return summaries

    def get_common_errors(self, n_sessions: int = 10) -> List[str]:
        """Get the most common errors across recent sessions."""
        error_counts: dict[str, int] = {}

        for path in self.find_session_files()[-n_sessions:]:
            summary = self.parse_session(path)
            for error in summary.errors:
                # Normalize error message
                error_normalized = error.lower().strip()[:100]
                error_counts[error_normalized] = error_counts.get(error_normalized, 0) + 1

        # Return most common
        sorted_errors = sorted(error_counts.items(), key=lambda x: -x[1])
        return [error for error, count in sorted_errors[:10] if count > 1]

    def consolidate_insights(
        self,
        n_sessions: int = 10,
        min_confidence: float = 0.5,
    ) -> List[SessionInsight]:
        """
        Consolidate insights from multiple sessions.

        Deduplicates and ranks by frequency/confidence.
        """
        all_insights: List[SessionInsight] = []
        seen_content: Set[str] = set()

        for path in self.find_session_files()[-n_sessions:]:
            for insight in self.extract_insights(path):
                # Simple deduplication
                content_key = insight.content.lower()[:50]
                if content_key not in seen_content:
                    seen_content.add(content_key)
                    all_insights.append(insight)

        # Filter by confidence and sort by category priority
        category_priority = {"error": 0, "gotcha": 1, "pattern": 2, "success": 3}
        filtered = [i for i in all_insights if i.confidence >= min_confidence]
        filtered.sort(key=lambda i: category_priority.get(i.category, 99))

        return filtered[:50]  # Return top 50 insights

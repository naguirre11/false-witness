"""
Layer 1: Codebase Patterns

Top ~50 lines of consolidated wisdom, read FIRST every iteration.
Contains the most important, stable knowledge about the codebase.
"""

from datetime import datetime
from pathlib import Path
from typing import List, Optional


class PatternStore:
    """
    Manages the patterns file - a curated collection of the most
    important learnings about the codebase.

    The patterns file is read at the start of every agent invocation
    to provide essential context without wasting tokens on discovery.
    """

    MAX_LINES = 50
    HEADER = """# Codebase Patterns
# Auto-generated knowledge base. Most important patterns first.
# Last updated: {timestamp}

"""

    def __init__(self, path: Path):
        self.path = path
        self._ensure_exists()

    def _ensure_exists(self) -> None:
        """Create the patterns file if it doesn't exist."""
        if not self.path.exists():
            self.path.parent.mkdir(parents=True, exist_ok=True)
            header = self.HEADER.format(timestamp=datetime.now().isoformat())
            self.path.write_text(header)

    def get_patterns(self) -> str:
        """Return all patterns for agent context."""
        return self.path.read_text()

    def get_patterns_truncated(self, max_lines: int = None) -> str:
        """Return patterns, truncated to max_lines."""
        if max_lines is None:
            max_lines = self.MAX_LINES

        content = self.path.read_text()
        lines = content.split("\n")
        return "\n".join(lines[:max_lines])

    def add_pattern(self, pattern: str, priority: int = 0) -> None:
        """
        Add a new pattern to the store.

        Args:
            pattern: The pattern text to add
            priority: 0 = append to end, 1+ = insert near top
        """
        lines = self.path.read_text().split("\n")

        # Find insertion point
        # Skip header (lines starting with #)
        insert_idx = 0
        for i, line in enumerate(lines):
            if not line.startswith("#") and line.strip():
                insert_idx = i
                break

        # Insert based on priority
        if priority > 0:
            # High priority - insert near top (after header)
            lines.insert(insert_idx, f"- {pattern}")
        else:
            # Normal priority - append before last blank lines
            while lines and not lines[-1].strip():
                lines.pop()
            lines.append(f"- {pattern}")
            lines.append("")

        # Enforce max lines
        self._trim_to_limit(lines)

        self.path.write_text("\n".join(lines))

    def add_patterns_batch(self, patterns: List[str]) -> None:
        """Add multiple patterns at once."""
        for pattern in patterns:
            self.add_pattern(pattern)

    def _trim_to_limit(self, lines: List[str]) -> None:
        """Trim patterns to MAX_LINES, keeping header and most important."""
        if len(lines) <= self.MAX_LINES:
            return

        # Count header lines
        header_end = 0
        for i, line in enumerate(lines):
            if not line.startswith("#") and line.strip():
                header_end = i
                break

        # Keep header + first (MAX_LINES - header) patterns
        content_lines = lines[header_end:]
        keep_count = self.MAX_LINES - header_end

        # Prioritize lines with "CRITICAL" or "IMPORTANT" markers
        def priority_key(line: str) -> int:
            if "CRITICAL" in line.upper():
                return 0
            if "IMPORTANT" in line.upper():
                return 1
            return 2

        sorted_content = sorted(content_lines, key=priority_key)[:keep_count]

        # Rebuild
        lines.clear()
        lines.extend(self.path.read_text().split("\n")[:header_end])
        lines.extend(sorted_content)

    def search(self, keyword: str) -> List[str]:
        """Search patterns for a keyword."""
        content = self.path.read_text()
        return [
            line for line in content.split("\n")
            if keyword.lower() in line.lower()
        ]

    def clear(self) -> None:
        """Clear all patterns (keeps header)."""
        header = self.HEADER.format(timestamp=datetime.now().isoformat())
        self.path.write_text(header)


# Default patterns for False Witness project
DEFAULT_PATTERNS = """
# Codebase Patterns
# Auto-generated knowledge base for False Witness project.
# Last updated: {timestamp}

## GDScript Critical Rules
- NEVER use RefCounted - always Node or Resource
- Autoloads MUST extend Node, never use class_name in autoloads
- Use load() instead of preload() to break circular dependencies
- Lambda closures capture primitives by VALUE - use dict for reference capture

## Testing Patterns
- Run smoke tests before committing: ./cc_workflow/scripts/run-tests.ps1 -Mode smoke
- Use state dict for signal testing: var state = {{"received": false}}
- GUT tests in tests/unit/ for pure logic, tests/integration/ for managers

## Ticket Workflow
- Only ONE ticket in dev_in_progress at a time
- Move with: cc_workflow/scripts/ticket-move.ps1 FW-XXX status
- Update STATUS.md after moving tickets

## Git Conventions
- No Claude references in commits (no Co-Authored-By)
- Use conventional commits: feat:, fix:, docs:, refactor:
- Never force push without explicit permission

## File Paths on Windows
- Edit/Write tools: Use backslashes (C:\\Users\\...)
- Bash paths: Use forward slashes (C:/Users/...)
"""

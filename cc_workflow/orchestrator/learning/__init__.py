"""
Learning system for the orchestrator.

Implements a 4-layer learning approach:
1. Patterns - Top ~50 lines of consolidated wisdom
2. Progress - Append-only log of iteration results
3. Git History - Context from recent commits
4. Insights - Extracted patterns from session JSONL
"""

from .patterns import PatternStore
from .progress import ProgressLog
from .git_history import GitHistoryAnalyzer
from .insights import InsightExtractor

__all__ = [
    "PatternStore",
    "ProgressLog",
    "GitHistoryAnalyzer",
    "InsightExtractor",
]

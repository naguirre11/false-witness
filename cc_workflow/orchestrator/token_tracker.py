"""
Token usage tracking and monitoring.
"""

from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import List, Optional
import json


@dataclass
class TokenUsage:
    """Token usage for a single API call."""

    input_tokens: int = 0
    output_tokens: int = 0
    timestamp: datetime = field(default_factory=datetime.now)
    source: str = ""  # "orchestrator" or "agent"
    iteration: int = 0

    @property
    def total_tokens(self) -> int:
        return self.input_tokens + self.output_tokens

    def to_dict(self) -> dict:
        return {
            "input_tokens": self.input_tokens,
            "output_tokens": self.output_tokens,
            "timestamp": self.timestamp.isoformat(),
            "source": self.source,
            "iteration": self.iteration,
        }


class TokenTracker:
    """Track and monitor token usage across the orchestration session."""

    def __init__(
        self,
        warning_threshold: int = 50000,
        limit: int = 100000,
        log_path: Optional[Path] = None,
    ):
        self.warning_threshold = warning_threshold
        self.limit = limit
        self.log_path = log_path
        self.usage_records: List[TokenUsage] = []
        self._warned = False

    def record(self, usage: TokenUsage) -> None:
        """Record token usage from an API call."""
        self.usage_records.append(usage)

        # Log to file if configured
        if self.log_path:
            self._append_to_log(usage)

        # Check thresholds
        total = self.total_tokens
        if not self._warned and total > self.warning_threshold:
            self._warned = True
            print(f"WARNING: Token usage ({total}) exceeds warning threshold ({self.warning_threshold})")

    def record_from_response(
        self,
        response_data: dict,
        source: str,
        iteration: int,
    ) -> TokenUsage:
        """Extract and record token usage from API response."""
        # Handle different response formats
        usage_data = response_data.get("usage", {})
        input_tokens = usage_data.get("input_tokens", 0)
        output_tokens = usage_data.get("output_tokens", 0)

        usage = TokenUsage(
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            source=source,
            iteration=iteration,
        )
        self.record(usage)
        return usage

    @property
    def total_tokens(self) -> int:
        """Get total tokens used across all calls."""
        return sum(u.total_tokens for u in self.usage_records)

    @property
    def total_input_tokens(self) -> int:
        """Get total input tokens used."""
        return sum(u.input_tokens for u in self.usage_records)

    @property
    def total_output_tokens(self) -> int:
        """Get total output tokens used."""
        return sum(u.output_tokens for u in self.usage_records)

    @property
    def orchestrator_tokens(self) -> int:
        """Get tokens used by orchestrator."""
        return sum(u.total_tokens for u in self.usage_records if u.source == "orchestrator")

    @property
    def agent_tokens(self) -> int:
        """Get tokens used by agent."""
        return sum(u.total_tokens for u in self.usage_records if u.source == "agent")

    def is_over_limit(self) -> bool:
        """Check if we've exceeded the token limit."""
        return self.total_tokens > self.limit

    def get_summary(self) -> str:
        """Get a formatted summary of token usage."""
        return f"""
Token Usage Summary
==================
Total: {self.total_tokens:,} tokens
  - Input:  {self.total_input_tokens:,}
  - Output: {self.total_output_tokens:,}

By Source:
  - Orchestrator: {self.orchestrator_tokens:,}
  - Agent: {self.agent_tokens:,}

Iterations: {len(set(u.iteration for u in self.usage_records))}
API Calls: {len(self.usage_records)}

Status: {"OVER LIMIT" if self.is_over_limit() else "OK"}
"""

    def _append_to_log(self, usage: TokenUsage) -> None:
        """Append usage record to log file."""
        try:
            with open(self.log_path, "a") as f:
                f.write(json.dumps(usage.to_dict()) + "\n")
        except IOError as e:
            print(f"Warning: Could not write to token log: {e}")

    def save_summary(self, path: Path) -> None:
        """Save full usage data to a file."""
        data = {
            "summary": {
                "total_tokens": self.total_tokens,
                "input_tokens": self.total_input_tokens,
                "output_tokens": self.total_output_tokens,
                "orchestrator_tokens": self.orchestrator_tokens,
                "agent_tokens": self.agent_tokens,
                "num_calls": len(self.usage_records),
            },
            "records": [u.to_dict() for u in self.usage_records],
        }
        with open(path, "w") as f:
            json.dump(data, f, indent=2)

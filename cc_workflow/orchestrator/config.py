"""
Configuration management for the orchestrator system.
"""

from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional
import json
import os


@dataclass
class Config:
    """Configuration for the orchestrator system."""

    # Iteration limits
    max_iterations: int = 20
    max_agent_retries: int = 3

    # Paths
    project_root: Path = field(default_factory=lambda: Path.cwd())
    task_list_id: str = "false-witness"

    # Token limits (for monitoring, not hard enforcement)
    token_warning_threshold: int = 50000
    token_limit: int = 100000

    # Timeouts (seconds)
    agent_timeout: int = 600  # 10 minutes per agent invocation
    orchestrator_timeout: int = 60  # 1 minute for orchestrator decisions

    # Prompts
    orchestrator_prompt_path: Optional[Path] = None
    agent_prompt_path: Optional[Path] = None

    # Learning system
    patterns_file: Optional[Path] = None
    progress_file: Optional[Path] = None

    def __post_init__(self):
        """Set default paths after initialization."""
        orchestrator_dir = Path(__file__).parent

        if self.orchestrator_prompt_path is None:
            self.orchestrator_prompt_path = orchestrator_dir / "prompts" / "orchestrator.md"

        if self.agent_prompt_path is None:
            self.agent_prompt_path = orchestrator_dir / "prompts" / "agent.md"

        if self.patterns_file is None:
            self.patterns_file = orchestrator_dir / "patterns.txt"

        if self.progress_file is None:
            self.progress_file = orchestrator_dir / "progress.log"

    @property
    def task_dir(self) -> Path:
        """Get the task directory for this project."""
        return Path.home() / ".claude" / "tasks" / self.task_list_id

    @classmethod
    def from_env(cls) -> "Config":
        """Load configuration from environment variables."""
        task_list_id = os.environ.get("CLAUDE_CODE_TASK_LIST_ID", "false-witness")
        project_root = Path(os.environ.get("PROJECT_ROOT", Path.cwd()))

        return cls(
            task_list_id=task_list_id,
            project_root=project_root,
            max_iterations=int(os.environ.get("MAX_ITERATIONS", "20")),
        )

    @classmethod
    def from_file(cls, path: Path) -> "Config":
        """Load configuration from a JSON file."""
        with open(path) as f:
            data = json.load(f)

        # Convert string paths to Path objects
        if "project_root" in data:
            data["project_root"] = Path(data["project_root"])
        if "orchestrator_prompt_path" in data:
            data["orchestrator_prompt_path"] = Path(data["orchestrator_prompt_path"])
        if "agent_prompt_path" in data:
            data["agent_prompt_path"] = Path(data["agent_prompt_path"])

        return cls(**data)

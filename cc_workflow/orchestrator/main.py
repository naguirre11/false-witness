#!/usr/bin/env python3
"""
Task Orchestrator - Entry point for autonomous task execution.

Usage:
    python -m cc_workflow.orchestrator.main [OPTIONS]

Options:
    --ticket, -t TEXT       Specific ticket to work on
    --max-iterations, -n    Maximum iterations (default: 20)
    --dry-run              Show what would be done without executing
    --verbose, -v          Verbose output
"""

import argparse
import sys
from pathlib import Path

from .config import Config
from .coordinator import Coordinator, CompletionStatus


def main():
    parser = argparse.ArgumentParser(
        description="Task-based autonomous orchestration system",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    # Run orchestrator on next ticket from queue
    python -m cc_workflow.orchestrator.main

    # Work on a specific ticket
    python -m cc_workflow.orchestrator.main --ticket FW-061

    # Limit iterations
    python -m cc_workflow.orchestrator.main -n 10

    # Dry run (show plan without executing)
    python -m cc_workflow.orchestrator.main --dry-run
""",
    )

    parser.add_argument(
        "--ticket", "-t",
        help="Specific ticket ID to work on",
    )

    parser.add_argument(
        "--max-iterations", "-n",
        type=int,
        default=20,
        help="Maximum number of iterations (default: 20)",
    )

    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be done without executing",
    )

    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Verbose output",
    )

    parser.add_argument(
        "--project-root",
        type=Path,
        default=Path.cwd(),
        help="Project root directory (default: current directory)",
    )

    args = parser.parse_args()

    # Build configuration
    config = Config(
        max_iterations=args.max_iterations,
        project_root=args.project_root,
    )

    if args.verbose:
        print(f"Configuration:")
        print(f"  Project root: {config.project_root}")
        print(f"  Task list ID: {config.task_list_id}")
        print(f"  Max iterations: {config.max_iterations}")
        print(f"  Task directory: {config.task_dir}")
        print()

    if args.dry_run:
        print("Dry run mode - showing plan without executing")
        from .state_collector import StateCollector
        state = StateCollector(config)
        print("\nCurrent state:")
        print(state.collect())
        return 0

    # Create and run coordinator
    coordinator = Coordinator(config)

    try:
        result = coordinator.run(ticket_id=args.ticket)
    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
        result = CompletionStatus.ERROR

    # Exit with appropriate code
    exit_codes = {
        CompletionStatus.SUCCESS: 0,
        CompletionStatus.BLOCKED: 1,
        CompletionStatus.MAX_ITERATIONS: 2,
        CompletionStatus.TOKEN_LIMIT: 3,
        CompletionStatus.ERROR: 4,
    }

    return exit_codes.get(result, 4)


if __name__ == "__main__":
    sys.exit(main())

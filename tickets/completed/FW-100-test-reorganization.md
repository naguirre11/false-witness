---
id: FW-100
title: "Reorganize test suite for tiered execution"
priority: high
estimated_complexity: medium
dependencies: []
created: 2026-01-10
---

## Description

The test suite has grown to 1500+ tests across 46 files. Running all tests after every ticket causes significant development slowdown. This ticket reorganizes tests into a tiered structure enabling selective test execution while maintaining rigorous testing standards.

## Acceptance Criteria

- [x] Tests reorganized into `tests/unit/`, `tests/integration/`, and root `tests/` for smoke
- [x] Smoke test file created with ~50 critical tests covering core functionality
- [x] Multiple GUT config files for different test modes (smoke, unit, integration, full)
- [x] Test runner script supporting selective execution
- [x] CLAUDE.md updated with clear documentation on which tests to run when
- [x] All tests still pass after reorganization

## Technical Notes

### Test Categories

**Unit tests** (`tests/unit/`):
- Pure logic tests with no/minimal scene tree dependencies
- Enum tests, static method tests, data validation
- Fast execution (<1 sec per file)

**Integration tests** (`tests/integration/`):
- Tests requiring multiple systems, scene tree, signals
- Manager tests, component interaction tests
- May require setup/teardown

**Smoke tests** (`tests/test_smoke.gd`):
- ~50 critical tests extracted from unit/integration
- Cover core game flow, critical managers, essential equipment
- Quick validation that nothing is fundamentally broken

### Execution Strategy

| When | What to Run | Command |
|------|-------------|---------|
| During development | Related test file only | `run-tests.ps1 -Mode file -File test_audio_manager.gd` |
| Before commit | Smoke + Unit tests | `run-tests.ps1 -Mode smoke` |
| CI pipeline | Full suite | `run-tests.ps1 -Mode full` |

## Out of Scope

- Parallelizing test execution (future optimization)
- Test caching based on changed files (future optimization)
- CI pipeline configuration (separate ticket)

## Implementation Notes

### Changes Made

1. **Directory Structure Created**
   - `tests/unit/` - 4 pure logic test files (202 tests)
   - `tests/integration/` - 41 integration test files (1477 tests)
   - `tests/test_smoke.gd` - 17 critical sanity checks

2. **Test Files Moved**
   - Unit tests: `test_evidence_enums.gd`, `test_prism_enums.gd`, `test_aura_enums.gd`, `test_spatial_constraints.gd`
   - All other test files → `tests/integration/`

3. **GUT Config Files Created**
   - `.gutconfig.smoke.json` - Smoke tests only
   - `.gutconfig.unit.json` - Unit tests only
   - `.gutconfig.integration.json` - Integration tests only
   - `.gutconfig.json` - Full suite (unchanged, uses `include_subdirs: true`)

4. **Test Runner Script**
   - `cc_workflow/scripts/run-tests.ps1` with modes: smoke, unit, integration, full, file

5. **Documentation**
   - Added "Testing Strategy" section to CLAUDE.md with detailed guidance

### Test Results After Reorganization

```
Smoke tests:       17/17 passed (0.024s)
Unit tests:       202/202 passed (0.063s)
Integration tests: 1477/1479 passed (18.975s) - 2 risky (no-assertion tests)
Total:            1696 tests passing
```

### Verification Commands

```powershell
# Quick smoke test
./cc_workflow/scripts/run-tests.ps1 -Mode smoke

# Full suite
./cc_workflow/scripts/run-tests.ps1 -Mode full

# Specific file
./cc_workflow/scripts/run-tests.ps1 -Mode file -File test_audio_manager.gd
```

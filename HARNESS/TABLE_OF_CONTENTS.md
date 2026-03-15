# HARNESS — Table of Contents

Directory map and purpose of each area under `HARNESS/`.

---

## Top level

| Item | Type | Description |
|------|------|-------------|
| `TABLE_OF_CONTENTS.md` | File | This document: directory map of HARNESS. |
| `SETTINGS.json` | File | Harness limits and config (max_attempts_per_task, max_total_attempts, max_tasks, max_task_duration, max_spend, delay_between_tasks). |
| `SETUP_CHECKLIST.md` | File | Checklist for adapting the harness to this project (unit tests, E2E tests, linting scripts). |

### HUMANS_ONLY/

| File | Description |
|------|-------------|
| `index.html` | Lightweight frontend: tasks + progress view with last-checked timestamp. |
| `serve.py` | Minimal HTTP server; run so the frontend can fetch ARTIFACTS. |
| `START_MONITOR.ps1` | Script to start the monitor/frontend (e.g. server + browser). |
| `README.md` | How to run the frontend (e.g. `python HARNESS/HUMANS_ONLY/serve.py` → open http://localhost:8765/HUMANS_ONLY/). |

---

## ARTIFACTS/

Structured data and schemas used by the harness (tasks, guardrails, progress, snapshot).

### ARTIFACTS/GUARDRAILS/

| File | Description |
|------|-------------|
| `GUARDRAILS.jsonl` | Guardrail definitions (one JSON object per line). |
| `GUARDRAILS.SCHEMA.json` | JSON schema for guardrail entries. |

### ARTIFACTS/TASKS/

| File | Description |
|------|-------------|
| `TASKS.jsonl` | Task list (one task per line; id, title, status, etc.). |
| `TASKS.SCHEMA.json` | JSON schema for task entries. |

### ARTIFACTS/SNAPSHOT/

| File | Description |
|------|-------------|
| `SNAPSHOT.json` | Current pipeline snapshot state for the harness (single JSON document). |
| `SNAPSHOT.SCHEMA.json` | JSON schema for the snapshot document. |

### ARTIFACTS/PROGRESS/

| File | Description |
|------|-------------|
| `PROGRESS.jsonl` | Append-only progress log: one JSON object per line (timestamp, agent, event, message). Subagents append events (started, milestone, completed, failed) as they run. |
| `PROGRESS.SCHEMA.json` | JSON schema for one progress event line (optional). |

---

## KNOWLEDGE/

Project and domain knowledge for agents and tooling.

| Item | Description |
|------|-------------|
| `TABLE_OF_CONTENTS.md` | Index of knowledge docs in this folder. |
| `INDEX.md` | Entry point for knowledge (links to TABLE_OF_CONTENTS and PROJECT_OVERVIEW). |
| `PROJECT-OVERVIEW/` | Folder containing project overview. |
| `PROJECT-OVERVIEW/PROJECT_OVERVIEW.md` | High-level project overview (what the project does, main components, entry points). |

---

## LOGS/

Structured logs produced by the harness.

| File | Description |
|------|-------------|
| `LOGS.jsonl` | Log events (one JSON object per line). |
| `LOGS.SCHEMA.json` | JSON schema for log entries. |

---

## UTILITIES/

Scripts and helpers for validation and harness operations.

### UTILITIES/SCRIPTS/VALIDATION/

| File | Description |
|------|-------------|
| `ASSERT_UNIT_TESTS_PASS.ps1` | Run unit tests (pytest via `scripts/Run-Tests.ps1` or `pytest tests/`); exit non-zero if any fail. |
| `ASSERT_E2E_TESTS_PASS.ps1` | Run E2E tests (Playwright in `electron/`: `npm run test:e2e`); exit non-zero if any fail. |
| `ASSERT_LINTING.ps1` | Run linting (ruff if available, else Python compileall on statesim); exit non-zero if lint fails. |
| `ASSERT_ARTIFACTS.ps1` | (Optional) Validate HARNESS artifacts (TASKS.jsonl, GUARDRAILS.jsonl, schemas) are present and schema-compliant. |

---

## Onboarding

Use **SETUP_CHECKLIST.md** when adding HARNESS to a new repo or bringing a new contributor up to speed. It covers layout, AGENTS.md, KNOWLEDGE, validation scripts, guardrails, SETTINGS.json, and the human-facing monitor.

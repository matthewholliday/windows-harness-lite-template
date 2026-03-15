# HARNESS — Table of Contents

Directory map and purpose of each area under `HARNESS/`.

---

## Top level

| Item | Type | Description |
|------|------|-------------|
| `TABLE_OF_CONTENTS.md` | File | This document: directory map of HARNESS. |
| `progress.json` | File | Progress tracking (root-level). |

---

## ARTIFACTS/

Structured data and schemas used by the harness (tasks, guardrails, progress).

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

### ARTIFACTS/PROGRESS/

| File | Description |
|------|-------------|
| `PROGRESS.json` | Progress state for the harness. |

---

## KNOWLEDGE/

Project and domain knowledge for agents and tooling.

| File | Description |
|------|-------------|
| `INDEX.md` | Index or entry point for knowledge docs. |
| `PROJECT_OVERVIEW.md` | High-level project overview. |

---

## LOGS/

Structured logs produced by the harness.

| File | Description |
|------|-------------|
| `LOGS.jsonl` | Log events (one JSON object per line). |
| `LOGS.SCHEMA.json` | JSON schema for log entries. |

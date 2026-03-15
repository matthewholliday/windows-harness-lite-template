# HARNESS setup checklist — onboarding a new project

These steps help you (or an agent) adapt the **generic** HARNESS structure to the specific project. Use this when adding HARNESS to a new repo or when bringing a new contributor up to speed.

---

## 1. Understand the layout

- [ ] Confirm `HARNESS/` exists at the repo root and matches the layout in **TABLE_OF_CONTENTS.md** (ARTIFACTS, KNOWLEDGE, LOGS, UTILITIES, HUMANS_ONLY).
- [ ] If anything is missing (e.g. `SETTINGS.json`, schema files), create or copy from the template.

---

## 2. Integrate with project docs

- [ ] **AGENTS.md** (or equivalent at repo root):
  - [ ] Update the **project map** so package/module names and paths match this repo (e.g. `statesim/`, `electron/`, `tests/`, `scripts/`).
  - [ ] Add or update the **HARNESS** section: ARTIFACTS paths, KNOWLEDGE location, LOGS, and root files (TABLE_OF_CONTENTS, SETTINGS).
  - [ ] If you use Cursor commands (**tasks.add**, **task.decompose**, **kb.import**), ensure they’re listed and point to the right command/agent docs.
  - [ ] If you use subagents (task.decomposer, task.writer, kb.importer), list them with when to use each.

---

## 3. Knowledge base (for agents and humans)

- [ ] **HARNESS/KNOWLEDGE/**:
  - [ ] Populate or link **PROJECT_OVERVIEW** (e.g. `PROJECT-OVERVIEW/PROJECT_OVERVIEW.md`) with a short, high-level description of the project (what it does, main components, entry points).
  - [ ] Update **KNOWLEDGE/TABLE_OF_CONTENTS.md** to index knowledge docs (and create an **INDEX.md** in KNOWLEDGE if your process uses it).
- [ ] Optionally run **kb.import** (or your import flow) to seed the knowledge base from existing docs or URLs.

---

## 4. Validation scripts

Place all of these under **HARNESS/UTILITIES/SCRIPTS/VALIDATION/**.

- [ ] **ASSERT_UNIT_TESTS_PASS.ps1**  
  - Create or wire to the project’s unit test runner (e.g. `pytest`, `npm test`, `dotnet test`).  
  - Script should exit with a non-zero code if any test fails.

- [ ] **ASSERT_E2E_TESTS_PASS.ps1**  
  - Create or wire to the project’s E2E test runner (e.g. Playwright, Cypress, custom).  
  - Script should exit with a non-zero code if any E2E test fails.

- [ ] **ASSERT_LINTING.ps1**  
  - Create or wire to the project’s linter(s) (e.g. ESLint, Pylint, Ruff, shellcheck).  
  - Script should exit with a non-zero code if lint fails.

- [ ] (Optional) **ASSERT_ARTIFACTS.ps1**  
  - Validate HARNESS artifacts (e.g. TASKS.jsonl and schemas, GUARDRAILS.jsonl) if you use automated checks.

Ensure the project has the right dependencies (test frameworks, linters) installed; add them to the repo’s dependency files (e.g. `requirements.txt`, `package.json`) if missing.

---

## 5. Artifacts and configuration

- [ ] **HARNESS/ARTIFACTS/GUARDRAILS/GUARDRAILS.jsonl**  
  - Add initial guardrails (one JSON object per line).  
  - Each line must conform to **GUARDRAILS.SCHEMA.json** (required: `id`, `title`, `description`; optional: `category`, `priority`).  
  - Examples: “No eval in production”, “Prefer immutable data”, “Run tests before merging”.

- [ ] **HARNESS/SETTINGS.json**  
  - Review limits and delays (e.g. `max_attempts_per_task`, `max_total_attempts`, `max_tasks`, `max_task_duration`, `max_spend`, `delay_between_tasks`) and set values appropriate for this project.

- [ ] **HARNESS/ARTIFACTS/TASKS/TASKS.jsonl**  
  - Can start empty. Each line is one task (see **TASKS.SCHEMA.json**: required `id`, `title`, `status`).

---

## 6. Optional: human-facing monitor and commands

- [ ] **HARNESS/HUMANS_ONLY/**  
  - If you use the monitor: run `serve.py` (e.g. `python HARNESS/HUMANS_ONLY/serve.py`) and open the frontend (see **HUMANS_ONLY/README.md**).  
  - Use **START_MONITOR.ps1** if you have a script that starts the server and opens the browser.

- [ ] **Cursor commands and agents**  
  - If the repo uses **tasks.add** / **task.decompose** / **kb.import**, ensure `.cursor/commands/` and `.cursor/agents/` (or your equivalent) exist and reference the correct paths (e.g. `HARNESS/ARTIFACTS/TASKS/TASKS.jsonl`).

---

## 7. Verify

- [ ] Run **ASSERT_UNIT_TESTS_PASS.ps1**, **ASSERT_E2E_TESTS_PASS.ps1**, and **ASSERT_LINTING.ps1**; fix any failures or path issues.
- [ ] Optionally add one task via **tasks.add** (or by appending a line to TASKS.jsonl) and confirm it appears in the monitor or in TASKS.jsonl.
- [ ] Confirm AGENTS.md and KNOWLEDGE are sufficient for a new agent or human to understand where HARNESS lives and how to use it.

---

## Quick reference

| Item | Location |
|------|----------|
| Full HARNESS map | `HARNESS/TABLE_OF_CONTENTS.md` |
| Task list | `HARNESS/ARTIFACTS/TASKS/TASKS.jsonl` |
| Guardrails | `HARNESS/ARTIFACTS/GUARDRAILS/GUARDRAILS.jsonl` |
| Validation scripts | `HARNESS/UTILITIES/SCRIPTS/VALIDATION/` |
| Project overview | `HARNESS/KNOWLEDGE/` (e.g. PROJECT-OVERVIEW) |
| Limits and config | `HARNESS/SETTINGS.json` |

# HARNESS engineering template

This repo is a **generic template** for the HARNESS dev pipeline: Cursor agents, tasks, guardrails, and validation scripts. Copy or clone it into your project and follow the project setup checklist below to adapt it to your repo.

For full onboarding detail, see [HARNESS/SETUP_CHECKLIST.md](HARNESS/SETUP_CHECKLIST.md).

---

## Project setup checklist

Use these steps to adapt the template to a specific project:

1. **Copy this template** into your repo (or clone and remove template-specific git history if desired).

2. **Agent definitions** — Ensure `.cursor/agents/` paths and any Cursor command references point at your repo’s `HARNESS/` (if you moved it).

3. **RUN-HARNESS.ps1** — Leave as-is unless your HARNESS lives outside the repo root; then set `-HarnessRoot` or adjust `$HarnessRoot`.

4. **HARNESS layout** — Confirm `HARNESS/` matches [HARNESS/TABLE_OF_CONTENTS.md](HARNESS/TABLE_OF_CONTENTS.md); create any missing files (e.g. SETTINGS.json) from the template.

5. **Knowledge** — Replace [HARNESS/KNOWLEDGE/PROJECT-OVERVIEW/PROJECT_OVERVIEW.md](HARNESS/KNOWLEDGE/PROJECT-OVERVIEW/PROJECT_OVERVIEW.md) with your project’s overview (what it does, main components, entry points).

6. **Validation scripts** — Wire [HARNESS/UTILITIES/SCRIPTS/VALIDATION/](HARNESS/UTILITIES/SCRIPTS/VALIDATION/) to your project: unit tests, E2E tests, linting. The scripts try common setups (e.g. `npm test`, `pytest`, ESLint, Playwright); if your project uses different commands or layout, edit the scripts or add a project-specific script (e.g. `scripts/Run-Tests.ps1`). See [HARNESS/SETUP_CHECKLIST.md](HARNESS/SETUP_CHECKLIST.md) for detailed steps.

7. **Artifacts** — Add initial guardrails in [HARNESS/ARTIFACTS/GUARDRAILS/GUARDRAILS.jsonl](HARNESS/ARTIFACTS/GUARDRAILS/GUARDRAILS.jsonl); add tasks to [HARNESS/ARTIFACTS/TASKS/TASKS.jsonl](HARNESS/ARTIFACTS/TASKS/TASKS.jsonl); tune [HARNESS/SETTINGS.json](HARNESS/SETTINGS.json) limits.

8. **AGENTS.md** (optional) — If your repo uses AGENTS.md, update the project map and HARNESS section to match your paths and commands.

9. **Verify** — Run the validation scripts and optionally run `RUN-HARNESS.ps1` with one task to confirm the pipeline works.

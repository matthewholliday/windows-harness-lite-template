# Agent instructions

## Commands

- **tasks.add** — Add the task described by the user to `HARNESS/ARTIFACTS/TASKS/TASKS.jsonl`. See `.cursor/rules/tasks-add.mdc` for full behavior (required fields, schema, no duplicate ids).
- **kb.import** — Import the information or information source given by the user into a hierarchical HTML knowledge base under `KB/`. See `.cursor/commands/kb.import.md` for full behavior (decompose by topic, ~100 lines per file, high-level description per article, linked hierarchy).

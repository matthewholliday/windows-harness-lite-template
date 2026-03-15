---
description: Command tasks.add — add the described task to TASKS.jsonl
globs: HARNESS/ARTIFACTS/TASKS/TASKS.jsonl
alwaysApply: false
---

# task.add

When the user invokes **tasks.add** (e.g. `/tasks.add` or "tasks.add" with a task description), add that task to `HARNESS/ARTIFACTS/TASKS/TASKS.jsonl`.

## Behavior

1. Read `HARNESS/ARTIFACTS/TASKS/TASKS.jsonl`. Each non-empty line is one task (parse each line as JSON). Empty file or missing file → treat as no tasks.
2. Parse the user's task description into a single task object conforming to `HARNESS/ARTIFACTS/TASKS/TASKS.SCHEMA.json`:
   - **id** (required): unique string (e.g. `task-` + short slug or timestamp, or UUID).
   - **title** (required): short summary from the user's description.
   - **status** (required): use `"pending"` unless the user says otherwise.
   - **description** (optional): detailed text if the user provided it.
   - **order** (optional): integer; set from existing max + 1 or omit.
3. Ensure no existing line has the same `id` as the new task (no duplicates by `id`).
4. Append the new task as a single line (JSON.stringify of the task object) to `HARNESS/ARTIFACTS/TASKS/TASKS.jsonl`.

Do not remove or alter existing tasks. Only add the one new task from the current command.

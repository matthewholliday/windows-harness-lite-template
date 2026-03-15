---
description: Command task.decompose — decompose a high-level task into subtasks via task.decomposer
globs: HARNESS/ARTIFACTS/TASKS/TASKS.jsonl
alwaysApply: false
---

# task.decompose

When the user invokes **task.decompose** (e.g. `/task.decompose` or "task.decompose" with task information), invoke the **task.decomposer** subagent with the required task information so it can break the task into subtasks and append them to `HARNESS/ARTIFACTS/TASKS/TASKS.jsonl`.

## Required information

Pass to the task.decomposer subagent:

- **Task information**: The goal, feature, or user request to decompose. The user may provide this in the same message as the command (e.g. "task.decompose: add user authentication") or in a follow-up. If the user runs `task.decompose` without any task description, ask them to provide the high-level task (goal, feature, or request) before invoking the subagent.

Optional context you may include when invoking the subagent:

- **Parent task id**: If the user is decomposing an existing task from TASKS.jsonl, pass its `id` so the decomposer can use a convention like `{parent-id}-1`, `{parent-id}-2` for new subtask ids.

## Behavior

1. **Gather**: If the user did not provide task information with the command, ask for the high-level task (goal, feature, or user request) to decompose.
2. **Invoke**: Call the **task.decomposer** subagent with a detailed task description that includes:
   - The task information (goal/feature/request) to decompose.
   - Any parent task id or other context the user supplied.
3. **Result**: The subagent will append new subtasks to `HARNESS/ARTIFACTS/TASKS/TASKS.jsonl`. After it completes, summarize for the user which subtasks were added and that they can run the harness to process pending tasks in order.

Do not re-implement decomposition logic in this command. Delegate all decomposition to the task.decomposer subagent. See `.cursor/agents/task.decomposer.md` for the subagent’s behavior and TASKS.jsonl schema.

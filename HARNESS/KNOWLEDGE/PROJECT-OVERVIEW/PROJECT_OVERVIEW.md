# Project overview

**simkernel2** is a US state simulation and desktop app project.

## What it does

- **Core simulation (statesim)** — Schema (LinkML, SQLAlchemy), jobs (SQL templates + metadata), CLI subcommands, analytics, repository and job execution. Entry: `statesim/__init__.py`.
- **Desktop app (electron)** — Electron + React UI; main process, renderer, tests (including Playwright E2E).
- **Tests** — Pytest for statesim (schema, jobs, CLI, analytics, etc.) under `tests/`.
- **Scripts** — Build and run (e.g. `Build.ps1`, `Run-Tests.ps1`, `Run-Us-State-Simulator.ps1`) in `scripts/`.

## Main components

| Area        | Purpose |
|------------|---------|
| `statesim/` | Core simulation package |
| `electron/` | Desktop app (Electron + React) |
| `tests/`    | Pytest test suite |
| `scripts/`  | Build and run scripts |
| `docs/`     | Project documentation |
| `examples/` | Example usage (e.g. `repository_usage.py`) |
| `geodata/`  | Geographic data assets |
| `workspace/`| Runtime/working data (game state, DBs) |
| `build/`    | Build outputs |

## Entry points

- **CLI:** `statesim` (via `statesim.cli:main`)
- **Unit tests:** `pytest tests/` or `scripts/Run-Tests.ps1`
- **E2E tests:** `npm run test:e2e` in `electron/` (Playwright)
- **Desktop app:** `npm run start` in `electron/`

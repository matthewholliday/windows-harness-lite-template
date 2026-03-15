# Harness — Humans Only

Lightweight frontend to view **tasks** and **progress** with a timestamp of the last refresh.

## Run the frontend

1. Start the server (from repo root or from `HARNESS`):

   ```bash
   python HARNESS/HUMANS_ONLY/serve.py
   ```

   Or from `HARNESS`:

   ```bash
   cd HARNESS && python HUMANS_ONLY/serve.py
   ```

2. Open in a browser:

   **http://localhost:8765/HUMANS_ONLY/**

3. Use **Refresh** to reload tasks and progress; the page shows *Last checked* with the time of that refresh.

No build step; static HTML, CSS, and JS only.

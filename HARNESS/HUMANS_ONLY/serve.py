#!/usr/bin/env python3
"""Minimal HTTP server so the HUMANS_ONLY frontend can fetch ARTIFACTS (TASKS, PROGRESS) via fetch()."""
import http.server
import os
import socketserver

def main():
    # Serve from HARNESS so /ARTIFACTS/... and /HUMANS_ONLY/... resolve
    harness_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(harness_dir)
    port = 8765
    handler = http.server.SimpleHTTPRequestHandler
    with socketserver.TCPServer(("", port), handler) as httpd:
        print("Harness frontend: http://localhost:{}/HUMANS_ONLY/".format(port))
        print("Serving from: {}".format(harness_dir))
        httpd.serve_forever()

if __name__ == "__main__":
    main()

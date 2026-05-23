#!/usr/bin/env python3
"""Local web server for the Godot HTML5 export.

Godot's WASM build requires SharedArrayBuffer, which browsers only enable when
the response includes specific cross-origin isolation headers. Python's stock
http.server doesn't send them, so this small wrapper adds them.

Usage:
    python tools/serve_web.py
    python tools/serve_web.py --dir builds/web --port 8000
"""
import argparse
import http.server
import os
import socketserver
import sys
import webbrowser


class GodotHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self) -> None:
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dir", default="builds/web", help="Directory to serve (default: builds/web)")
    parser.add_argument("--port", type=int, default=8000, help="Port to listen on (default: 8000)")
    parser.add_argument("--no-open", action="store_true", help="Don't open the browser automatically")
    args = parser.parse_args()

    if not os.path.isdir(args.dir):
        print(f"Directory not found: {args.dir}", file=sys.stderr)
        print("Run the Godot Web export first (Project > Export > Web > Export Project).", file=sys.stderr)
        sys.exit(1)

    os.chdir(args.dir)
    url = f"http://localhost:{args.port}/"
    with socketserver.TCPServer(("localhost", args.port), GodotHandler) as httpd:
        print(f"Serving {os.getcwd()} at {url}")
        print("Ctrl+C to stop.")
        if not args.no_open:
            webbrowser.open(url)
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nStopped.")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Tiny HTTP JSON emoji catalog for podman-edge (Skupper connector target)."""
from http.server import BaseHTTPRequestHandler, HTTPServer
import json

EMOJIS = [
    {"shortcode": ":grinning:", "unicode": "😀"},
    {"shortcode": ":rocket:", "unicode": "🚀"},
    {"shortcode": ":tada:", "unicode": "🎉"},
]


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        body = json.dumps({"service": "legacy-emoji", "emojis": EMOJIS}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *_args):
        pass


if __name__ == "__main__":
    HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()

#!/usr/bin/env python3
"""Servidor HTTP local que envia COOP/COEP (necessário p/ SharedArrayBuffer do WASM)."""
import http.server, os, sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "dist")
PORT = int(os.environ.get("PORT", "8080"))

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **kw):
        super().__init__(*a, directory=os.path.abspath(ROOT), **kw)
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

if __name__ == "__main__":
    if not os.path.isdir(ROOT):
        sys.exit("dist/ não existe — rode ./scripts/build.sh primeiro")
    print(f"Servindo {os.path.abspath(ROOT)} em http://localhost:{PORT}")
    http.server.HTTPServer(("127.0.0.1", PORT), Handler).serve_forever()

#!/usr/bin/env python3
"""Servidor HTTP local para servir dist/.

Por padrão NÃO envia COOP/COEP: o porte webxash3d-fwgs não usa threads
(SharedArrayBuffer) e, com cross-origin isolation ligado, alguns builds emscripten
entram num caminho com threads que quebra. Para forçar os headers (ex.: um build que
realmente precise de SharedArrayBuffer), rode com COEP=1.
"""
import http.server, os, sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "dist")
PORT = int(os.environ.get("PORT", "8080"))
COEP = os.environ.get("COEP", "0") == "1"

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **kw):
        super().__init__(*a, directory=os.path.abspath(ROOT), **kw)
    def end_headers(self):
        if COEP:
            self.send_header("Cross-Origin-Opener-Policy", "same-origin")
            self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

if __name__ == "__main__":
    if not os.path.isdir(ROOT):
        sys.exit("dist/ não existe — rode ./scripts/fetch-engine.sh e ./scripts/make-assets.sh primeiro")
    print(f"Servindo {os.path.abspath(ROOT)} em http://localhost:{PORT}  (COEP={'on' if COEP else 'off'})")
    http.server.HTTPServer(("127.0.0.1", PORT), Handler).serve_forever()

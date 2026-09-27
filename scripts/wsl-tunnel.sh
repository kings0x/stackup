#!/usr/bin/env bash
# CORS file server for one-shot transfer of the flattened source to the verify page.
cd /mnt/c/Users/Admin/Code/stackup/contracts
python3 - <<'EOF' > /tmp/cors-server.log 2>&1 &
from http.server import BaseHTTPRequestHandler, HTTPServer
class H(BaseHTTPRequestHandler):
    def do_GET(self):
        body = open('/mnt/c/Users/Admin/Code/stackup/contracts/StackUp.flat.sol','rb').read()
        self.send_response(200)
        self.send_header('Content-Type','text/plain')
        self.send_header('Access-Control-Allow-Origin','*')
        self.send_header('Content-Length',str(len(body)))
        self.end_headers()
        self.wfile.write(body)
    def log_message(self,*a): pass
HTTPServer(('127.0.0.1',8123),H).serve_forever()
EOF
echo "server_started"
sleep 1
curl -s -o /dev/null -w "%{http_code} %{size_download}\n" http://127.0.0.1:8123/StackUp.flat.sol
# cloudflared quick tunnel
if [ ! -x /tmp/cloudflared ]; then
  curl -sSL -o /tmp/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 --max-time 120
  chmod +x /tmp/cloudflared
fi
/tmp/cloudflared tunnel --url http://127.0.0.1:8123 --no-autoupdate > /tmp/cf-tunnel.log 2>&1 &
echo "tunnel_starting"
for i in $(seq 1 30); do
  URL=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' /tmp/cf-tunnel.log | head -1)
  if [ -n "$URL" ]; then echo "TUNNEL_URL:$URL"; break; fi
  sleep 2
done

#!/usr/bin/env bash
tail -5 /tmp/cf-tunnel.log
pkill -f "cloudflared tunnel" || true
sleep 2
curl -s -o /dev/null -w "local: %{http_code}\n" --max-time 10 http://127.0.0.1:8123/StackUp.flat.sol || (echo "local server dead, restarting"; cd /mnt/c/Users/Admin/Code/stackup/contracts && nohup python3 -c "
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
" > /tmp/cors-server.log 2>&1 & sleep 2; curl -s -o /dev/null -w "local2: %{http_code}\n" --max-time 10 http://127.0.0.1:8123/StackUp.flat.sol)
/tmp/cloudflared tunnel --url http://127.0.0.1:8123 --no-autoupdate > /tmp/cf-tunnel.log 2>&1 &
for i in $(seq 1 30); do
  URL=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' /tmp/cf-tunnel.log | head -1)
  if [ -n "$URL" ]; then echo "TUNNEL_URL:$URL"; break; fi
  sleep 2
done
sleep 3
curl -s -o /dev/null -w "public: %{http_code} %{size_download}\n" --max-time 30 "$URL/StackUp.flat.sol" || echo "public: CURL_FAIL"

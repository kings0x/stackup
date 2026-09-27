#!/usr/bin/env bash
sleep 20
curl -s --max-time 60 "https://sourcify.dev/server/verify-ui/jobs/f20621dd-dc71-4184-aa4a-4ca3da473937" | head -c 1500; echo
echo "--- contract check ---"
curl -s --max-time 60 "https://sourcify.dev/server/v2/contract/5042002/0xb823Dd1180dD8d31493614b86F19e0A7D282C28d" -o /dev/null -w "%{http_code}\n" || echo CHECK_FAIL

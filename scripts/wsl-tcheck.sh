#!/usr/bin/env bash
curl -s -o /dev/null -w "file: %{http_code} %{size_download}\n" --max-time 30 https://animation-lending-escape-andrea.trycloudflare.com/StackUp.flat.sol || echo "file: CURL_FAIL"
curl -s --max-time 20 https://animation-lending-escape-andrea.trycloudflare.com/ | head -c 300; echo
echo TUNNEL_CHECK_DONE

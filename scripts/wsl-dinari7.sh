#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
echo "writetest:"; echo ok > /tmp/wtest && cat /tmp/wtest
rm -rf /tmp/dshare; mkdir -p /tmp/dshare; cd /tmp/dshare
curl -sSL --max-time 180 https://codeload.github.com/dinaricrypto/sbt-contracts/tar.gz/refs/heads/main -o sbt.tar.gz
ls -la sbt.tar.gz
tar xzf sbt.tar.gz --strip-components=1
ls src/ | head

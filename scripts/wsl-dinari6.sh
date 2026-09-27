#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
rm -rf ~/.dinari-sbt 2>/dev/null || sudo rm -rf ~/.dinari-sbt 2>/dev/null || true
ls -la ~ | head -20
mkdir -p ~/dshare && cd ~/dshare
curl -sSL --max-time 120 https://codeload.github.com/dinaricrypto/sbt-contracts/tar.gz/refs/heads/main -o sbt.tar.gz
tar xzf sbt.tar.gz --strip-components=1
ls src/

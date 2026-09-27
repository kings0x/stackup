#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
if [ ! -d ~/.dinari-sbt ]; then
  git clone --depth 1 --branch main https://github.com/dinaricrypto/sbt-contracts.git ~/.dinari-sbt 2>&1 | tail -1
fi
cd ~/.dinari-sbt
git log --oneline -1
echo "--- foundry.toml ---"
cat foundry.toml | head -40
echo "--- remappings ---"
cat remappings.txt 2>/dev/null || true
echo "--- TransferRestrictor (first 100 lines) ---"
head -100 src/TransferRestrictor.sol

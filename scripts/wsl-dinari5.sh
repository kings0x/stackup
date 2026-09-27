#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
cd ~/.dinari-sbt
rm -rf lib
mkdir -p lib
for r in "forge-std:https://github.com/foundry-rs/forge-std" "solady:https://github.com/Vectorized/solady" "openzeppelin-contracts:https://github.com/OpenZeppelin/openzeppelin-contracts" "openzeppelin-contracts-upgradeable:https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable"; do
  n="${r%%:*}"; u="${r#*:}"
  if [ ! -d "lib/$n" ]; then git clone --depth 1 "$u" "lib/$n" 2>&1 | tail -1; fi
done
ls lib/
echo "--- build ---"
forge build 2>&1 | tail -8

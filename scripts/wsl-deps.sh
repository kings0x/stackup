#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
D=/mnt/c/Users/Admin/Code/stackup/extern/dshare
cd "$D"
dl() { mkdir -p "$3"; curl -sSL --max-time 180 "$1" -o "$2" && tar xzf "$2" --strip-components=1 -C "$3" && rm "$2"; }
dl https://codeload.github.com/Vectorized/solady/tar.gz/refs/heads/main solady.tgz lib/solady
dl https://codeload.github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/tar.gz/refs/heads/master ocu.tgz lib/openzeppelin-contracts-upgradeable
dl https://codeload.github.com/OpenZeppelin/openzeppelin-contracts/tar.gz/refs/heads/master oc.tgz lib/openzeppelin-contracts
dl https://codeload.github.com/foundry-rs/forge-std/tar.gz/refs/heads/master fs.tgz lib/forge-std
ls lib/ lib/solady/src/ 2>/dev/null | head -20
echo DEPS_DONE

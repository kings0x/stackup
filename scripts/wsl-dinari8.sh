#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
D=/mnt/c/Users/Admin/Code/stackup/extern/dshare
rm -rf "$D"; mkdir -p "$D/lib"; cd "$D"
dl() { curl -sSL --max-time 180 "$1" -o "$2" && tar xzf "$2" --strip-components=1 -C "$3"; }
echo "== sbt-contracts =="
curl -sSL --max-time 180 https://codeload.github.com/dinaricrypto/sbt-contracts/tar.gz/refs/heads/main -o sbt.tgz
mkdir -p sbt && tar xzf sbt.tgz --strip-components=1 -C sbt && rm sbt.tgz
ls sbt/src/
echo "== deps =="
dl https://codeload.github.com/Vectorized/solady/tar.gz/refs/heads/main solady.tgz lib/solady
dl https://codeload.github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/tar.gz/refs/heads/master ocu.tgz lib/openzeppelin-contracts-upgradeable
dl https://codeload.github.com/OpenZeppelin/openzeppelin-contracts/tar.gz/refs/heads/master oc.tgz lib/openzeppelin-contracts
dl https://codeload.github.com/foundry-rs/forge-std/tar.gz/refs/heads/master fs.tgz lib/forge-std
ls lib/

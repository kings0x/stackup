#!/usr/bin/env bash
set -e
export PATH="$HOME/.foundry/bin:$PATH"
D=/mnt/c/Users/Admin/Code/stackup/extern/dshare
ls $D/sbt/src/common/ $D/sbt/src/deployment/
grep -n "^import" $D/sbt/src/common/*.sol | head
echo "--- prune unneeded Dinari modules (keep: core token + restrictor + NumberUtils + ControlledUpgradeable) ---"
mkdir -p $D/sbt-keep && cp $D/sbt/src/deployment/ControlledUpgradeable.sol $D/sbt-keep/
rm -rf $D/sbt/src/orders $D/sbt/src/dividend $D/sbt/src/deployment $D/sbt/src/DShareFactory.sol $D/sbt/src/WrappedDShare.sol $D/sbt/src/IDShareFactory.sol
mkdir -p $D/sbt/src/deployment && cp $D/sbt-keep/ControlledUpgradeable.sol $D/sbt/src/deployment/
ls -R $D/sbt/src | head -20
echo "--- pin OZ v5.0.2 + solady v0.0.255 ---"
rm -rf $D/lib/openzeppelin-contracts $D/lib/openzeppelin-contracts-upgradeable $D/lib/solady
dl() { mkdir -p "$2"; curl -sSL --max-time 180 "$1" -o "$D/dl.tgz" && tar xzf "$D/dl.tgz" --strip-components=1 -C "$2" && rm "$D/dl.tgz"; }
dl https://codeload.github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/tar.gz/refs/tags/v5.0.2 $D/lib/openzeppelin-contracts-upgradeable
dl https://codeload.github.com/OpenZeppelin/openzeppelin-contracts/tar.gz/refs/tags/v5.0.2 $D/lib/openzeppelin-contracts
dl https://codeload.github.com/Vectorized/solady/tar.gz/refs/tags/v0.0.255 $D/lib/solady
cd $D
forge build 2>&1 | tail -6
echo PORT_BUILD3_DONE

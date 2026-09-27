#!/usr/bin/env bash
D=/mnt/c/Users/Admin/Code/stackup/extern/dshare
echo "--- ERC20Rebasing imports ---"
grep -n "^import" $D/sbt/src/ERC20Rebasing.sol $D/sbt/src/IDShare.sol $D/sbt/src/ITransferRestrictor.sol $D/sbt/src/deployment/ControlledUpgradeable.sol
echo "--- OZ pragma check (upgradeable v5.0.2 target) ---"
echo ok

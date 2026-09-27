#!/usr/bin/env bash
cd ~/.dinari-sbt
echo "--- package.json deps ---"
cat package.json 2>/dev/null | head -40
echo "--- ControlledUpgradeable ---"
head -80 src/deployment/ControlledUpgradeable.sol
echo "--- scripts ---"
ls script/ 2>/dev/null; ls releases/v1.0.0/ 2>/dev/null | head
echo "--- ERC20Rebasing key parts ---"
grep -n "balancePerShare\|_INITIAL\|function balanceOf\|function totalSupply\|decimals\|pause\|Paus" src/ERC20Rebasing.sol | head -30

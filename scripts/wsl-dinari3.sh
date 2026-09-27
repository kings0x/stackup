#!/usr/bin/env bash
cd ~/.dinari-sbt
echo "--- gitmodules ---"
cat .gitmodules 2>/dev/null || echo "no gitmodules"
echo "--- node_modules present? ---"
ls node_modules 2>/dev/null | head -5 || echo "no node_modules"
ls lib 2>/dev/null || echo "no lib dir"
echo "--- solady/oz references ---"
grep -rn "solady\|openzeppelin" foundry.toml remappings.txt package.json 2>/dev/null | head -10
echo "--- releases/v1.0.0 files ---"
ls releases/v1.0.0/ 2>/dev/null | head -20

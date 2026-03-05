#!/bin/bash
cd "$(dirname "$0")"

echo "=== 编译论文 ==="
latexmk -xelatex -g wangshuo_phdthesis.tex

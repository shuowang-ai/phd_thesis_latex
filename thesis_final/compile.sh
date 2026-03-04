#!/bin/bash
cd "$(dirname "$0")"

# 电子版（提交版）
echo "=== 编译电子版（提交版）==="
latexmk -xelatex -g wangshuo_phdthesis.tex

# 打印版（双面打印，插入空白页）
echo "=== 编译打印版 ==="
latexmk -xelatex -g -jobname="王硕.基于物理启发图神经网络的大气污染复杂系统建模研究.打印版" wangshuo_phdthesis_print.tex

#!/bin/bash
# 编译博士论文 PDF (xelatex + bibtex 4-pass).
# 用法:
#   bash compile.sh           # 完整 4-pass + 校验
#   bash compile.sh quick     # 单 pass (改文字小调时用, 不重建 bib/toc)
#   bash compile.sh clean     # 清掉中间产物 (保留 .tex/.bib/.pdf)
#   bash compile.sh distclean # 清干净所有产物, 包括 .pdf

set -u
cd "$(dirname "$0")"

JOB="wangshuo_phdthesis"
MAIN="${JOB}.tex"

# 中间产物 (clean 时删)
AUX_EXTS=(aux bbl blg log out toc lof lot loa fls fdb_latexmk synctex.gz xdv idx ind ilg nav snm vrb)
EXTRA_AUX=(bu.aux)

clean_aux() {
  for ext in "${AUX_EXTS[@]}"; do rm -f "${JOB}.${ext}"; done
  rm -f "${EXTRA_AUX[@]}"
  # 章节级 aux (data/chap*.aux 等, bnuthesis 模板会产生)
  rm -f data/*.aux
}

case "${1:-full}" in
  clean)
    echo "=== 清理中间产物 ==="
    clean_aux
    echo "done."
    exit 0
    ;;
  distclean)
    echo "=== 清理全部产物 (含 PDF) ==="
    clean_aux
    rm -f "${JOB}.pdf"
    echo "done."
    exit 0
    ;;
  quick)
    echo "=== 快速编译 (单 pass, 不重建 bib/toc) ==="
    xelatex -interaction=nonstopmode -halt-on-error "$MAIN"
    exit $?
    ;;
esac

# ===== 完整 4-pass =====
# 1. xelatex   生成 .aux (含 \bibdata + \citation)
# 2. bibtex    根据 .aux + ref/refs.bib 生成 .bbl
# 3. xelatex   嵌入 .bbl, 更新交叉引用编号
# 4. xelatex   解析全部 \ref / 页码 / TOC

run() {
  local label="$1"; shift
  echo "=== ${label} ==="
  if ! "$@"; then
    echo "!!! ${label} 失败 (exit=$?), 中止" >&2
    exit 1
  fi
}

run "Pass 1/4: xelatex (gen aux)"     xelatex -interaction=nonstopmode -halt-on-error "$MAIN"
run "Pass 2/4: bibtex"                bibtex "$JOB"
run "Pass 3/4: xelatex (embed bbl)"   xelatex -interaction=nonstopmode -halt-on-error "$MAIN"
run "Pass 4/4: xelatex (resolve refs)" xelatex -interaction=nonstopmode -halt-on-error "$MAIN"

# ===== 验证 =====
echo "=== 验证 ==="
UNDEF_CITE=$(grep -c "LaTeX Warning: Citation .* undefined" "${JOB}.log" || true)
UNDEF_REF=$(grep -c  "LaTeX Warning: Reference .* undefined" "${JOB}.log" || true)
MISSING_BIB=$(grep -c "Warning--I didn't find a database entry" "${JOB}.blg" || true)
PAGES=$(grep -oE "Output written on .*\.pdf \([0-9]+ pages" "${JOB}.log" | grep -oE "[0-9]+ pages" | head -1)

echo "  PDF: ${JOB}.pdf  (${PAGES:-未知页数})"
echo "  Undefined citations: ${UNDEF_CITE}"
echo "  Undefined references: ${UNDEF_REF}"
echo "  Missing bib entries: ${MISSING_BIB}"

if [[ "$UNDEF_CITE" != "0" || "$UNDEF_REF" != "0" || "$MISSING_BIB" != "0" ]]; then
  echo ""
  echo "⚠️  存在未解析的引用. 详见:"
  echo "    grep 'undefined' ${JOB}.log"
  echo "    grep 'didn'\\''t find' ${JOB}.blg"
  exit 2
fi

echo "✅ 编译完成, 0 未解析引用"

#!/usr/bin/env bash
#
# wuji-sync.sh — 将无极平台下载的代码同步到本 Git 仓库
#
# 用法:
#   ./wuji-sync.sh repos/my-project          # 同步并查看 diff
#   ./wuji-sync.sh repos/my-project --commit  # 同步并自动提交
#   ./wuji-sync.sh --help                     # 查看帮助

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SCRIPT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

usage() {
    cat <<EOF
${CYAN}wuji-sync.sh${NC} — 无极平台代码同步工具

${YELLOW}用法:${NC}
  $0 <无极下载目录>              同步代码，查看变更
  $0 <无极下载目录> --commit     同步代码并自动提交
  $0 <无极下载目录> --dry-run    仅预览将同步的文件，不实际操作
  $0 --help                     显示帮助

${YELLOW}示例:${NC}
  $0 repos/my-app-0919
  $0 repos/my-app-0919 --commit
  $0 repos/my-app-0919 --dry-run
EOF
}

log_info()  { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[!!]${NC} $*"; }
log_error() { echo -e "${RED}[ERR]${NC} $*"; }

main() {
    if [[ $# -lt 1 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        usage
        exit 0
    fi

    local source_dir="$1"
    local auto_commit=false
    local dry_run=false

    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --commit)  auto_commit=true ;;
            --dry-run) dry_run=true ;;
            *) log_error "未知参数: $1"; usage; exit 1 ;;
        esac
        shift
    done

    if [[ ! -d "$source_dir" ]]; then
        log_error "目录不存在: $source_dir"
        exit 1
    fi

    source_dir="$(cd "$source_dir" && pwd)"

    if [[ ! -d "$REPO_DIR/.git" ]]; then
        log_error "本目录不是 Git 仓库: $REPO_DIR"
        exit 1
    fi

    log_info "源目录 (无极下载): $source_dir"
    log_info "目标仓库:          $REPO_DIR"
    echo ""

    if $dry_run; then
        log_info "预览模式 — 以下是源目录中的内容:"
        echo ""
        find "$source_dir" -type f \
            -not -path "*/node_modules/*" \
            -not -path "*/.git/*" \
            -not -name ".DS_Store" \
            -not -name "Thumbs.db" \
            | sed "s|^$source_dir/||" \
            | head -50
        local total
        total="$(find "$source_dir" -type f \
            -not -path "*/node_modules/*" \
            -not -path "*/.git/*" \
            | wc -l | tr -d ' ')"
        echo ""
        log_info "共 $total 个文件。（仅显示前 50 个）"
        exit 0
    fi

    log_info "正在同步文件..."

    local items=0
    for item in "$source_dir"/*; do
        [[ ! -e "$item" ]] && continue
        local name
        name="$(basename "$item")"

        [[ "$name" == "node_modules" ]] && continue
        [[ "$name" == ".git" ]] && continue
        [[ "$name" == ".DS_Store" ]] && continue

        cp -r "$item" "$REPO_DIR/"
        items=$((items + 1))
    done

    for item in "$source_dir"/.[!.]*; do
        [[ ! -e "$item" ]] && continue
        local name
        name="$(basename "$item")"

        [[ "$name" == ".git" ]] && continue
        [[ "$name" == ".DS_Store" ]] && continue

        cp -r "$item" "$REPO_DIR/"
        items=$((items + 1))
    done

    log_info "已同步 $items 个顶级文件/目录"

    echo ""
    log_info "同步完成！以下是变更摘要:"
    echo "---"

    cd "$REPO_DIR"
    git add -A

    local stat_output
    stat_output="$(git diff --cached --stat 2>/dev/null || true)"

    if [[ -z "$stat_output" ]]; then
        log_info "没有检测到变更，代码与仓库一致。"
        exit 0
    fi

    echo "$stat_output"
    echo "---"
    echo ""

    if $auto_commit; then
        local today
        today="$(date '+%Y-%m-%d %H:%M')"
        local msg="sync: 从无极平台同步代码 ($today)"
        git commit -m "$msg"
        log_info "已提交: $msg"
        log_info "提交完成，所有历史已保存在本地 Git 仓库中。"
    else
        log_warn "变更已暂存但未提交。你可以:"
        echo "  git diff --cached     # 查看详细变更"
        echo "  git commit -m '...'   # 提交变更"
        echo "  git reset HEAD        # 撤销暂存"
    fi
}

main "$@"

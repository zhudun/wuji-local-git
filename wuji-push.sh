#!/usr/bin/env bash
#
# wuji-push.sh — 将 project/ 目录的代码推送回无极链接的文件夹
#
# 用法:
#   ./wuji-push.sh repos/my-project            # 全量同步
#   ./wuji-push.sh repos/my-project --changed   # 只推最近一次提交修改的文件
#   ./wuji-push.sh repos/my-project --dry-run   # 预览不操作

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SCRIPT_DIR"
PROJECT_DIR="$SCRIPT_DIR/project"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

usage() {
    cat <<EOF
${CYAN}wuji-push.sh${NC} — 将代码推送回无极链接的文件夹

${YELLOW}用法:${NC}
  $0 <无极链接目录>              全量推送 project/ 的内容
  $0 <无极链接目录> --changed    只推送最近一次提交修改的文件
  $0 <无极链接目录> --dry-run    仅预览，不实际操作
  $0 --help                     显示帮助

${YELLOW}示例:${NC}
  $0 repos/my-app-0919
  $0 repos/my-app-0919 --changed
  $0 repos/my-app-0919 --dry-run

${YELLOW}同步方向:${NC}
  project/  ──→  repos/<临时项目>
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

    local target_dir="$1"
    local changed_only=false
    local dry_run=false

    shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --changed)  changed_only=true ;;
            --dry-run)  dry_run=true ;;
            *) log_error "未知参数: $1"; usage; exit 1 ;;
        esac
        shift
    done

    if [[ ! -d "$target_dir" ]]; then
        log_error "目录不存在: $target_dir"
        exit 1
    fi

    if [[ ! -d "$PROJECT_DIR" ]]; then
        log_error "project/ 目录不存在，请先运行 wuji-sync.sh 同步代码"
        exit 1
    fi

    target_dir="$(cd "$target_dir" && pwd)"
    cd "$REPO_DIR"

    log_info "源目录 (project/):  $PROJECT_DIR"
    log_info "目标 (无极文件夹):   $target_dir"
    echo ""

    if $changed_only; then
        local files
        files="$(git diff --name-only HEAD~1 2>/dev/null || true)"

        if [[ -z "$files" ]]; then
            log_info "最近一次提交没有文件变更。"
            exit 0
        fi

        log_info "最近一次提交修改的文件:"
        echo "$files" | while IFS= read -r f; do
            [[ "$f" != project/* ]] && continue
            local rel="${f#project/}"
            echo "  $rel"
        done
        echo ""

        if $dry_run; then
            log_info "预览模式，不实际复制。"
            exit 0
        fi

        echo "$files" | while IFS= read -r f; do
            [[ "$f" != project/* ]] && continue
            local rel="${f#project/}"

            if [[ -f "$REPO_DIR/$f" ]]; then
                local dir
                dir="$(dirname "$target_dir/$rel")"
                mkdir -p "$dir"
                cp "$REPO_DIR/$f" "$target_dir/$rel"
                log_info "已复制: $rel"
            else
                log_warn "文件已删除（跳过）: $rel"
            fi
        done
    else
        local items=0

        for item in "$PROJECT_DIR"/*; do
            [[ ! -e "$item" ]] && continue
            local name
            name="$(basename "$item")"
            [[ "$name" == "node_modules" ]] && continue
            [[ "$name" == ".git" ]] && continue
            [[ "$name" == ".DS_Store" ]] && continue
            [[ "$name" == ".gitkeep" ]] && continue

            if $dry_run; then
                echo "  $name"
            else
                cp -r "$item" "$target_dir/"
            fi
            items=$((items + 1))
        done

        for item in "$PROJECT_DIR"/.[!.]*; do
            [[ ! -e "$item" ]] && continue
            local name
            name="$(basename "$item")"
            [[ "$name" == ".git" ]] && continue
            [[ "$name" == ".DS_Store" ]] && continue
            [[ "$name" == ".gitkeep" ]] && continue

            if $dry_run; then
                echo "  $name"
            else
                cp -r "$item" "$target_dir/"
            fi
            items=$((items + 1))
        done

        if $dry_run; then
            echo ""
            log_info "预览完成，共 $items 个顶级文件/目录。"
            exit 0
        fi

        log_info "已复制 $items 个顶级文件/目录"
    fi

    echo ""
    log_info "推送完成！无极文件夹已更新。"
}

main "$@"

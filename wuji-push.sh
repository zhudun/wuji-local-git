#!/usr/bin/env bash
#
# wuji-push.sh — 将本 Git 仓库的代码推送回无极链接的文件夹
#
# 用法:
#   ./wuji-push.sh repos/my-project            # 全量同步
#   ./wuji-push.sh repos/my-project --changed   # 只推最近一次提交修改的文件
#   ./wuji-push.sh repos/my-project --dry-run   # 预览不操作

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SCRIPT_DIR"

SKIP_FILES="wuji-sync.sh wuji-sync.cmd wuji-push.sh wuji-push.cmd
.wuji-sync-ignore .cursorrules .gitignore
AI-GUIDE.md QUICKSTART.md README.md"

SKIP_DIRS="repos .git node_modules"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

usage() {
    cat <<EOF
${CYAN}wuji-push.sh${NC} — 将代码推送回无极链接的文件夹

${YELLOW}用法:${NC}
  $0 <无极链接目录>              全量同步（排除工具文件和 .git）
  $0 <无极链接目录> --changed    只推送最近一次提交修改的文件
  $0 <无极链接目录> --dry-run    仅预览，不实际操作
  $0 --help                     显示帮助

${YELLOW}示例:${NC}
  $0 repos/my-app-0919
  $0 repos/my-app-0919 --changed
  $0 repos/my-app-0919 --dry-run
EOF
}

log_info()  { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[!!]${NC} $*"; }
log_error() { echo -e "${RED}[ERR]${NC} $*"; }

should_skip() {
    local rel="$1"

    for f in $SKIP_FILES; do
        [[ "$rel" == "$f" ]] && return 0
    done

    for d in $SKIP_DIRS; do
        [[ "$rel" == "$d" || "$rel" == "$d"/* ]] && return 0
    done

    local base
    base="$(basename "$rel")"
    [[ "$base" == ".DS_Store" || "$base" == "Thumbs.db" ]] && return 0

    return 1
}

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

    target_dir="$(cd "$target_dir" && pwd)"
    cd "$REPO_DIR"

    log_info "源仓库:            $REPO_DIR"
    log_info "目标 (无极文件夹):  $target_dir"
    echo ""

    if $changed_only; then
        local files
        files="$(git diff --name-only HEAD~1 2>/dev/null || true)"

        if [[ -z "$files" ]]; then
            log_info "最近一次提交没有文件变更。"
            exit 0
        fi

        log_info "最近一次提交修改的文件:"
        local count=0

        echo "$files" | while IFS= read -r f; do
            should_skip "$f" && continue
            echo "  $f"
        done

        echo ""

        if $dry_run; then
            log_info "预览模式，不实际复制。"
            exit 0
        fi

        echo "$files" | while IFS= read -r f; do
            should_skip "$f" && continue

            if [[ -f "$REPO_DIR/$f" ]]; then
                local dir
                dir="$(dirname "$target_dir/$f")"
                mkdir -p "$dir"
                cp "$REPO_DIR/$f" "$target_dir/$f"
                log_info "已复制: $f"
            else
                log_warn "文件已删除（跳过）: $f"
            fi
        done
    else
        local count=0

        while IFS= read -r -d '' file; do
            local rel="${file#$REPO_DIR/}"
            should_skip "$rel" && continue

            if $dry_run; then
                echo "  $rel"
            else
                local dir
                dir="$(dirname "$target_dir/$rel")"
                mkdir -p "$dir"
                cp "$file" "$target_dir/$rel"
            fi
            count=$((count + 1))
        done < <(find "$REPO_DIR" -type f -not -path "$REPO_DIR/.git/*" -print0 2>/dev/null)

        if $dry_run; then
            echo ""
            log_info "预览完成，共 $count 个文件。"
            exit 0
        fi

        log_info "已复制 $count 个文件"
    fi

    echo ""
    log_info "推送完成！无极文件夹已更新。"
}

main "$@"

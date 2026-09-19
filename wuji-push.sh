#!/usr/bin/env bash
#
# wuji-push.sh — 将本 Git 仓库的代码推送回无极链接的文件夹
#
# 用法:
#   ./wuji-push.sh /path/to/wuji-linked-folder            # 全量同步
#   ./wuji-push.sh /path/to/wuji-linked-folder --changed   # 只推最近一次提交修改的文件
#   ./wuji-push.sh /path/to/wuji-linked-folder --dry-run   # 预览不操作

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SCRIPT_DIR"

TOOL_FILES=(
    "wuji-sync.sh"
    "wuji-push.sh"
    ".wuji-sync-ignore"
    ".cursorrules"
    "AI-GUIDE.md"
    "QUICKSTART.md"
)

TOOL_DIRS=(
    "repos"
)

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
  $0 /c/wuji-workspace-0919
  $0 ~/wuji-linked/my-app --changed
  $0 ~/wuji-linked/my-app --dry-run
EOF
}

log_info()  { echo -e "${GREEN}[✓]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
log_error() { echo -e "${RED}[✗]${NC} $*"; }

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
        echo "$files" | while IFS= read -r f; do
            echo "  $f"
        done
        echo ""

        if $dry_run; then
            log_info "预览模式，不实际复制。"
            exit 0
        fi

        echo "$files" | while IFS= read -r f; do
            local skip=false
            for tool in "${TOOL_FILES[@]}"; do
                [[ "$f" == "$tool" ]] && skip=true && break
            done
            $skip && continue

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
        local exclude_args=(
            --exclude ".git"
            --exclude "node_modules"
            --exclude ".DS_Store"
        )
        for tool in "${TOOL_FILES[@]}"; do
            exclude_args+=(--exclude "$tool")
        done
        for dir in "${TOOL_DIRS[@]}"; do
            exclude_args+=(--exclude "$dir")
        done
        exclude_args+=(--exclude "README.md" --exclude ".gitignore")

        if $dry_run; then
            log_info "预览模式:"
            echo ""
            rsync -avn "${exclude_args[@]}" "$REPO_DIR/" "$target_dir/"
            exit 0
        fi

        rsync -av "${exclude_args[@]}" "$REPO_DIR/" "$target_dir/"
    fi

    echo ""
    log_info "推送完成！无极文件夹已更新。"
}

main "$@"

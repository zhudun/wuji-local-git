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

SKIP_NAMES=".git node_modules .DS_Store Thumbs.db"

SKIP_FILES="wuji-sync.sh wuji-sync.cmd wuji-push.sh wuji-push.cmd
.wuji-sync-ignore .cursorrules .gitignore
AI-GUIDE.md QUICKSTART.md README.md"

SKIP_DIRS="repos"

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

should_skip_name() {
    local name="$1"
    for skip in $SKIP_NAMES; do
        [[ "$name" == "$skip" ]] && return 0
    done
    return 1
}

should_skip_path() {
    local rel="$1"

    for f in $SKIP_FILES; do
        [[ "$rel" == "$f" ]] && return 0
    done

    for d in $SKIP_DIRS; do
        [[ "$rel" == "$d" || "$rel" == "$d"/* ]] && return 0
    done

    local ignore_file="$REPO_DIR/.wuji-sync-ignore"
    if [[ -f "$ignore_file" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            line="$(echo "$line" | sed 's/#.*//' | xargs)"
            [[ -z "$line" ]] && continue
            # shellcheck disable=SC2254
            case "$rel" in
                $line|$line/*) return 0 ;;
            esac
            local base
            base="$(basename "$rel")"
            # shellcheck disable=SC2254
            case "$base" in
                $line) return 0 ;;
            esac
        done < "$ignore_file"
    fi

    return 1
}

copy_tree() {
    local src="$1"
    local dst="$2"
    local mode="$3"
    local count=0

    while IFS= read -r -d '' file; do
        local rel="${file#$src/}"

        should_skip_name "$(basename "$rel")" && continue
        should_skip_path "$rel" && continue

        if [[ "$mode" == "dry" ]]; then
            echo "  $rel"
            count=$((count + 1))
        else
            local target_dir
            target_dir="$(dirname "$dst/$rel")"
            mkdir -p "$target_dir"
            cp "$file" "$dst/$rel"
            count=$((count + 1))
        fi
    done < <(find "$src" -type f -print0 2>/dev/null)

    echo "$count"
}

detect_deleted_files() {
    local source_dir="$1"
    local deleted=()

    while IFS= read -r -d '' file; do
        local rel="${file#$REPO_DIR/}"

        should_skip_name "$(basename "$rel")" && continue
        should_skip_path "$rel" && continue

        if [[ ! -e "$source_dir/$rel" ]]; then
            deleted+=("$rel")
        fi
    done < <(find "$REPO_DIR" -type f -not -path "$REPO_DIR/.git/*" -print0 2>/dev/null)

    if [[ ${#deleted[@]} -gt 0 ]]; then
        echo ""
        log_warn "以下文件在无极下载中不存在（可能已被删除）:"
        for f in "${deleted[@]}"; do
            echo -e "  ${RED}-${NC} $f"
        done
        echo ""
        read -rp "是否删除这些文件？[y/N] " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            for f in "${deleted[@]}"; do
                rm -f "$REPO_DIR/$f"
                log_info "已删除: $f"
            done
        else
            log_info "保留了这些文件"
        fi
    fi
}

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
        log_info "预览模式 (不实际修改文件):"
        echo ""
        copy_tree "$source_dir" "$REPO_DIR" "dry" > /dev/null
        echo ""
        log_info "预览完成。"
        exit 0
    fi

    log_info "正在同步文件..."
    local copied
    copied="$(copy_tree "$source_dir" "$REPO_DIR" "copy")"
    log_info "已复制 $copied 个文件"

    detect_deleted_files "$source_dir"

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

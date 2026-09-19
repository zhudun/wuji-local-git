#!/usr/bin/env bash
#
# wuji-sync.sh — 将无极平台下载的代码同步到本 Git 仓库
#
# 用法:
#   ./wuji-sync.sh /path/to/wuji-download          # 同步并查看 diff
#   ./wuji-sync.sh /path/to/wuji-download --commit  # 同步并自动提交
#   ./wuji-sync.sh --help                            # 查看帮助
#
# 原理:
#   用 rsync 将无极下载目录的文件覆盖到本仓库（排除 .git 和自定义忽略项），
#   然后用 git diff 展示变更。加 --commit 可自动生成一次提交。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SCRIPT_DIR"

EXCLUDE_PATTERNS=(
    ".git"
    "node_modules"
    ".DS_Store"
    "Thumbs.db"
    "*.log"
)

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

${YELLOW}工作流程:${NC}
  1. 从无极平台下载代码到本地（每次可能是不同文件夹）
  2. 运行本脚本，指定下载目录
  3. 脚本将文件同步到本 Git 仓库，保留完整 Git 历史
  4. 查看 diff，确认无误后提交

${YELLOW}示例:${NC}
  $0 ~/Downloads/wuji-project-0919
  $0 ~/Downloads/wuji-project-0919 --commit
  $0 ~/Desktop/新建文件夹/my-app --dry-run

${YELLOW}注意:${NC}
  - 同步会覆盖本仓库中的同名文件
  - .git 目录、node_modules 等会被自动排除
  - 如需自定义排除规则，编辑 .wuji-sync-ignore 文件
EOF
}

log_info()  { echo -e "${GREEN}[✓]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
log_error() { echo -e "${RED}[✗]${NC} $*"; }

build_exclude_args() {
    local args=()
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        args+=(--exclude "$pattern")
    done

    local ignore_file="$REPO_DIR/.wuji-sync-ignore"
    if [[ -f "$ignore_file" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            line="$(echo "$line" | sed 's/#.*//' | xargs)"
            [[ -z "$line" ]] && continue
            args+=(--exclude "$line")
        done < "$ignore_file"
    fi

    echo "${args[@]}"
}

detect_deleted_files() {
    local source_dir="$1"
    local deleted=()

    while IFS= read -r file; do
        local rel_path="${file#$REPO_DIR/}"

        [[ "$rel_path" == .git/* ]] && continue
        [[ "$rel_path" == repos/* ]] && continue
        [[ "$rel_path" == node_modules/* ]] && continue
        [[ "$rel_path" == "wuji-sync.sh" ]] && continue
        [[ "$rel_path" == "wuji-push.sh" ]] && continue
        [[ "$rel_path" == ".wuji-sync-ignore" ]] && continue
        [[ "$rel_path" == ".cursorrules" ]] && continue
        [[ "$rel_path" == "AI-GUIDE.md" ]] && continue
        [[ "$rel_path" == "QUICKSTART.md" ]] && continue
        [[ "$rel_path" == "README.md" ]] && continue
        [[ "$rel_path" == ".gitignore" ]] && continue

        if [[ ! -e "$source_dir/$rel_path" ]]; then
            deleted+=("$rel_path")
        fi
    done < <(find "$REPO_DIR" -type f -not -path "$REPO_DIR/.git/*")

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

    local exclude_args
    exclude_args="$(build_exclude_args)"

    log_info "源目录 (无极下载): $source_dir"
    log_info "目标仓库:          $REPO_DIR"
    echo ""

    if $dry_run; then
        log_info "预览模式 (不实际修改文件):"
        echo ""
        eval rsync -avn --delete "$exclude_args" \
            --exclude "repos" \
            --exclude "wuji-sync.sh" \
            --exclude "wuji-push.sh" \
            --exclude ".wuji-sync-ignore" \
            --exclude ".cursorrules" \
            --exclude "AI-GUIDE.md" \
            --exclude "QUICKSTART.md" \
            --exclude "README.md" \
            --exclude ".gitignore" \
            "\"$source_dir/\"" "\"$REPO_DIR/\""
        exit 0
    fi

    log_info "正在同步文件..."
    eval rsync -av "$exclude_args" \
        --exclude "repos" \
        --exclude "wuji-sync.sh" \
        --exclude "wuji-push.sh" \
        --exclude ".wuji-sync-ignore" \
        --exclude ".cursorrules" \
        --exclude "AI-GUIDE.md" \
        --exclude "QUICKSTART.md" \
        --exclude "README.md" \
        --exclude ".gitignore" \
        "\"$source_dir/\"" "\"$REPO_DIR/\""

    detect_deleted_files "$source_dir"

    echo ""
    log_info "同步完成！以下是变更摘要:"
    echo "─────────────────────────────────────"

    cd "$REPO_DIR"
    git add -A

    local stat_output
    stat_output="$(git diff --cached --stat 2>/dev/null || true)"

    if [[ -z "$stat_output" ]]; then
        log_info "没有检测到变更，代码与仓库一致。"
        exit 0
    fi

    echo "$stat_output"
    echo "─────────────────────────────────────"
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

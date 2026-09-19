# 无极平台本地 Git 管理方案

## 问题背景

腾讯无极平台没有 Git 管理，只有粗糙的历史提交功能。虽然可以下载代码到本地开发，但存在以下痛点：

- 每次断开连接后，重新连接需要新建文件夹
- 无法在同一个文件夹中持续使用 Git 跟踪历史
- 多次下载散落在不同目录，无法统一管理

## 解决方案

**核心思路：维护一个永久的 Git 仓库，每次从无极下载的代码都"同步"进来。**

```
你的电脑
├── wuji-git-repo/          ← 永久 Git 仓库（本仓库）
│   ├── .git/               ← 完整的 Git 历史
│   ├── wuji-sync.sh        ← 同步脚本
│   ├── src/
│   └── ...
│
├── wuji-download-0919/     ← 第 1 次从无极下载（临时）
├── wuji-download-0920/     ← 第 2 次从无极下载（临时）
└── wuji-download-0925/     ← 第 N 次从无极下载（临时）
```

每次从无极下载新代码后，运行同步脚本，代码就会合入 Git 仓库并保留历史。

## 日常工作流

### 初次设置

```bash
# 1. 克隆本仓库到本地（或者直接用本目录）
git clone <仓库地址> wuji-git-repo
cd wuji-git-repo

# 2. 第一次从无极下载代码到某个文件夹
#    假设下载到了 ~/Downloads/wuji-project

# 3. 运行同步
./wuji-sync.sh ~/Downloads/wuji-project --commit
```

### 每日开发流程

```
┌─────────────────────────────────────────────────────────────┐
│  1. 从无极下载代码 → ~/Downloads/wuji-0920/                  │
│                         │                                    │
│  2. 同步到 Git 仓库     │                                    │
│     ./wuji-sync.sh ~/Downloads/wuji-0920                    │
│                         │                                    │
│  3. 在 Git 仓库中开发   │                                    │
│     (正常 git add/commit/push)                               │
│                         │                                    │
│  4. 开发完成，把代码复制回无极                                  │
│     或直接在无极中同步修改                                      │
│                         │                                    │
│  5. 下次再从无极下载 → 新文件夹 → 回到步骤 2                    │
└─────────────────────────────────────────────────────────────┘
```

### 具体命令

```bash
# ============ 场景 1: 从无极下载后同步 ============

# 预览将同步哪些文件（不实际操作）
./wuji-sync.sh ~/Downloads/wuji-project-0919 --dry-run

# 同步并查看变更
./wuji-sync.sh ~/Downloads/wuji-project-0919

# 同步并自动提交
./wuji-sync.sh ~/Downloads/wuji-project-0919 --commit


# ============ 场景 2: 本地开发后提交 ============

# 正常的 Git 工作流
git add -A
git commit -m "feat: 新增XX功能"
git push


# ============ 场景 3: 把本地修改同步回无极 ============

# 方法 A: 直接复制整个项目（排除 .git）
rsync -av --exclude '.git' --exclude 'node_modules' \
  ./ ~/path-to-wuji-linked-folder/

# 方法 B: 只复制修改过的文件
git diff --name-only HEAD~1 | while read f; do
  cp "$f" ~/path-to-wuji-linked-folder/"$f"
done
```

## 脚本说明

### `wuji-sync.sh`

主同步脚本，将无极下载目录的文件同步到本 Git 仓库。

| 参数 | 说明 |
|------|------|
| `<目录>` | 无极下载的代码目录（必填） |
| `--commit` | 同步后自动提交 |
| `--dry-run` | 仅预览，不实际同步 |
| `--help` | 显示帮助 |

功能特性：
- 使用 `rsync` 高效同步，只传输变更的文件
- 自动排除 `.git`、`node_modules` 等目录
- 检测在无极端被删除的文件并询问是否同步删除
- 同步完成后显示变更摘要（git diff）

### `.wuji-sync-ignore`

自定义排除规则文件，语法类似 `.gitignore`，每行一个 pattern。
如果你的项目有特殊的构建产物或临时文件，在这里添加排除规则。

## 进阶技巧

### 1. 用分支管理不同版本

```bash
# 无极上有多个版本/环境？用分支区分
git checkout -b feature/new-page
# ... 开发 ...
git checkout main
```

### 2. 设置别名简化操作

在 `~/.bashrc` 或 `~/.zshrc` 中添加：

```bash
alias wsync='/path/to/wuji-git-repo/wuji-sync.sh'

# 然后就可以在任何地方运行
wsync ~/Downloads/wuji-latest --commit
```

### 3. 配合 VS Code 使用

推荐始终在 Git 仓库目录中打开 VS Code 进行开发：

```bash
code /path/to/wuji-git-repo
```

这样可以利用 VS Code 的 Git 面板查看变更、提交代码、解决冲突。

### 4. 自动备份到远程

```bash
# 推送到 GitHub/Gitee 作为备份
git remote add origin https://github.com/yourname/wuji-project.git
git push -u origin main
```

### 5. 处理冲突的情况

如果你在本地 Git 仓库中做了修改，同时无极端也有别人的修改：

```bash
# 先提交本地修改
git add -A && git commit -m "本地修改"

# 创建临时分支保存无极端的状态
git checkout -b wuji-sync-0920

# 同步无极代码
./wuji-sync.sh ~/Downloads/wuji-0920 --commit

# 回到主分支，合并
git checkout main
git merge wuji-sync-0920

# 解决冲突（如果有）后提交
```

## 目录结构说明

```
.
├── wuji-sync.sh          # 同步脚本
├── .wuji-sync-ignore     # 同步排除规则
├── .gitignore            # Git 忽略规则
├── README.md             # 本文件
└── (你的无极项目文件)      # 同步进来的代码
```

## FAQ

**Q: 同步会覆盖我本地的修改吗？**
A: 会。同步操作是以无极下载的版本为准覆盖本仓库。建议同步前先提交本地修改（`git commit`），这样即使覆盖了也能通过 `git diff` 或 `git revert` 找回。

**Q: 我可以删除无极下载的临时文件夹吗？**
A: 同步完成后可以安全删除。所有代码和历史都保存在 Git 仓库中了。

**Q: 多人协作怎么办？**
A: 每个人维护自己的 Git 仓库，推送到同一个远程仓库（GitHub/Gitee），用 Git 的标准协作流程（pull/merge/rebase）管理。

**Q: 无极平台的配置文件需要同步吗？**
A: 看情况。平台特有的配置文件（如部署配置）如果对开发没用，可以加到 `.wuji-sync-ignore` 中排除。

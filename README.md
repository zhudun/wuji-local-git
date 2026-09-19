# 无极平台本地 Git 管理方案（纯本地，不上传）

## 问题背景

腾讯无极平台没有 Git 管理，只有粗糙的历史提交功能。虽然可以下载代码到本地开发，但存在以下痛点：

- 每次断开连接后，重新连接需要新建文件夹
- 无法在同一个文件夹中持续使用 Git 跟踪历史
- 多次下载散落在不同目录，无法统一管理

**约束：企业项目，代码不能上传到任何外部仓库。所有管理纯本地完成。**

## 解决方案

**核心思路：在本地维护一个永久的 Git 仓库，每次从无极下载的代码都"同步"进来。**

```
你的电脑
├── D:\projects\wuji-git-repo\    ← 永久 Git 仓库（不变的，永远在这）
│   ├── .git\                     ← 所有版本历史都在这
│   ├── wuji-sync.sh              ← 同步脚本
│   ├── src\
│   └── ...
│
├── C:\wuji-workspace-0919\       ← 第 1 次无极下载（临时，用完可删）
├── C:\wuji-workspace-0920\       ← 第 2 次无极下载（临时，用完可删）
└── ...
```

Git 仓库只在你本机上，不连接任何远程服务器。`.git` 目录就是你的"版本数据库"。

## 初次设置

```bash
# 1. 在本地选一个固定位置创建 Git 仓库
mkdir D:\projects\wuji-git-repo
cd D:\projects\wuji-git-repo
git init

# 2. 把本仓库的工具文件复制进去
#    (wuji-sync.sh, .wuji-sync-ignore, .gitignore)

# 3. 第一次从无极下载代码到某个文件夹（比如 C:\wuji-workspace-0919）

# 4. 运行同步，把代码纳入 Git 管理
./wuji-sync.sh C:\wuji-workspace-0919 --commit
# 或 Windows Git Bash 下:
# bash wuji-sync.sh /c/wuji-workspace-0919 --commit

# 完成！你的第一个版本已经被 Git 记录了
```

## 每日工作流

```
 ┌──────────────────────────────────────────────────────────────┐
 │                                                              │
 │  早上：从无极下载代码 → C:\wuji-workspace-0920\              │
 │           │                                                  │
 │           ▼                                                  │
 │  同步到 Git 仓库                                             │
 │     bash wuji-sync.sh /c/wuji-workspace-0920                │
 │           │                                                  │
 │           ▼                                                  │
 │  在 Git 仓库目录中开发（用 VS Code 打开这个目录）             │
 │     git add -A && git commit -m "feat: 新增XX"               │
 │           │                                                  │
 │           ▼                                                  │
 │  开发完成，把修改的文件复制回无极链接的文件夹                   │
 │     （或在无极平台上手动同步修改）                              │
 │           │                                                  │
 │           ▼                                                  │
 │  下班收工。下次连接无极 → 新文件夹 → 回到第一步                │
 │                                                              │
 └──────────────────────────────────────────────────────────────┘
```

### 具体命令

```bash
# ============ 场景 1: 从无极下载后同步到 Git 仓库 ============

# 预览将同步哪些文件（不实际操作，先看看）
./wuji-sync.sh ~/Downloads/wuji-project-0919 --dry-run

# 同步并查看变更
./wuji-sync.sh ~/Downloads/wuji-project-0919

# 同步并自动提交
./wuji-sync.sh ~/Downloads/wuji-project-0919 --commit


# ============ 场景 2: 在 Git 仓库中开发后提交 ============

git add -A
git commit -m "feat: 新增XX功能"


# ============ 场景 3: 把本地修改同步回无极 ============

# 方法 A: 直接复制整个项目（排除 .git 和 node_modules）
rsync -av --exclude '.git' --exclude 'node_modules' \
  ./ ~/path-to-wuji-linked-folder/

# 方法 B: 只复制最近一次提交修改过的文件
git diff --name-only HEAD~1 | while read f; do
  cp "$f" ~/path-to-wuji-linked-folder/"$f"
done


# ============ 场景 4: 查看历史 ============

git log --oneline            # 查看提交历史
git diff HEAD~1              # 对比最近一次变更
git diff HEAD~3 HEAD         # 对比最近 3 次变更的累积差异
git show HEAD:src/App.vue    # 查看某个文件的某个历史版本
git checkout HEAD~2 -- src/  # 恢复某个目录到 2 次提交前的状态
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
- **纯本地操作，不涉及任何网络传输**

### `.wuji-sync-ignore`

自定义排除规则文件，语法类似 `.gitignore`，每行一个 pattern。
如果你的项目有特殊的构建产物或临时文件，在这里添加排除规则。

## 进阶技巧

### 1. 用分支管理不同功能

```bash
# 开发新功能时创建分支
git checkout -b feature/new-page
# ... 开发 ...
git add -A && git commit -m "feat: 新页面"

# 切回主分支
git checkout main

# 合并功能分支
git merge feature/new-page
```

### 2. 设置别名简化操作

在 `~/.bashrc` 或 `~/.zshrc` 中添加：

```bash
alias wsync='bash /d/projects/wuji-git-repo/wuji-sync.sh'

# 然后就可以在任何地方运行
wsync ~/Downloads/wuji-latest --commit
```

### 3. 配合 VS Code 使用

**始终在 Git 仓库目录中打开 VS Code**，而不是在无极下载的临时目录中打开：

```bash
code D:\projects\wuji-git-repo
```

好处：
- 左侧源代码管理面板可以看到所有变更
- 可以逐行查看 diff
- 可以可视化地回退、对比历史版本
- Timeline 面板可以看到每个文件的修改时间线

### 4. 本地备份策略

代码不能上传，但本地也要防丢失：

```bash
# 方法 A: 定期复制整个仓库到另一个磁盘/U盘
# （.git 目录包含完整历史，复制它就等于备份了一切）
xcopy /E /I D:\projects\wuji-git-repo E:\backup\wuji-git-repo
# 或 Linux/Mac:
cp -r /path/to/wuji-git-repo /media/usb-drive/backup/

# 方法 B: 用 git bundle 打包成单文件（更紧凑，方便存档）
cd D:\projects\wuji-git-repo
git bundle create ../wuji-backup-$(date +%Y%m%d).bundle --all
# 生成的 .bundle 文件包含完整仓库，可以存到加密U盘等安全位置

# 从 bundle 恢复：
git clone wuji-backup-20260919.bundle wuji-git-repo-restored
```

### 5. 处理冲突的情况

如果你在本地做了修改，同时无极端（或同事）也有修改：

```bash
# 先提交本地修改
git add -A && git commit -m "本地修改"

# 创建临时分支来接收无极端的版本
git checkout -b wuji-sync-0920

# 同步无极代码
./wuji-sync.sh ~/Downloads/wuji-0920 --commit

# 回到主分支，合并
git checkout main
git merge wuji-sync-0920

# 如果有冲突，VS Code 会高亮显示，手动解决后提交
git add -A && git commit -m "merge: 合并无极端和本地修改"

# 可以删除临时分支
git branch -d wuji-sync-0920
```

### 6. 用 tag 标记重要版本

```bash
# 发版、上线、里程碑时打标签
git tag -a v1.0.0 -m "第一次上线版本"
git tag -a v1.1.0 -m "新增XX功能后的版本"

# 查看所有标签
git tag -l

# 回到某个标记的版本
git checkout v1.0.0
```

## Windows 用户注意事项

如果你在 Windows 上使用：

1. **安装 Git for Windows**：https://git-scm.com/download/win ，安装时自带 Git Bash
2. **在 Git Bash 中运行脚本**：`bash wuji-sync.sh /c/path/to/download`
3. **路径格式**：Git Bash 中用 `/c/Users/xxx` 代替 `C:\Users\xxx`
4. **rsync**：Git Bash 自带 rsync；如果没有，可以用 MSYS2 安装

或者如果你习惯用 PowerShell，可以直接用文件复制命令代替 rsync：

```powershell
# PowerShell 版本的简易同步（不需要 rsync）
$source = "C:\wuji-workspace-0920"
$dest = "D:\projects\wuji-git-repo"

# 复制文件（排除 node_modules 等）
robocopy $source $dest /E /XD node_modules .git /XF *.log .DS_Store
```

## 目录结构说明

```
.
├── repos/                # 无极临时下载区（gitignore 忽略，不入 Git）
│   ├── my-app-0919/      #   每次下载放一个子目录
│   └── my-app-0920/      #   旧的用完可删
├── project/              # 同步目标（Git 跟踪，业务代码在这里）
│   ├── src/
│   ├── package.json
│   └── ...
├── wuji-sync.sh          # 从 repos/ 同步到 project/
├── wuji-push.sh          # 从 project/ 推回 repos/
├── .wuji-sync-ignore     # 同步排除规则
├── .cursorrules          # Cursor AI 规则
├── AI-GUIDE.md           # 通用 AI 助手指引
├── QUICKSTART.md         # 快速操作手册
├── .gitignore            # Git 忽略规则
└── README.md             # 本文件
```

## FAQ

**Q: 同步会覆盖我本地的修改吗？**

会。同步操作以无极下载的版本为准覆盖本仓库。所以建议：**同步前先 `git commit` 提交本地修改**。即使被覆盖，也能通过 `git diff` 或 `git checkout` 找回任何历史版本。

**Q: 我可以删除无极下载的临时文件夹吗？**

同步完成后可以放心删除。Git 仓库里已经有完整记录了。这些临时文件夹只是"中转站"。

**Q: .git 目录有多大？会不会太占空间？**

一般前端项目的 .git 目录不会超过几百 MB（即使有很长的历史）。Git 内部有高效的压缩算法。如果觉得太大，可以定期运行 `git gc` 压缩。

**Q: 电脑坏了/重装系统怎么办？**

定期用 `git bundle` 备份到U盘或公司内网存储（参见"本地备份策略"一节）。一个 `.bundle` 文件就包含了完整的仓库和所有历史。

**Q: 多人协作怎么办？**

纯本地的方案下，可以用 `git bundle` 文件通过公司内网共享盘交换：
```bash
# 同事 A 导出
git bundle create changes.bundle main

# 同事 B 导入
git fetch changes.bundle main:from-colleague-a
git merge from-colleague-a
```

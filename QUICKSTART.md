# 快速操作手册

## 目录结构

```
wuji-local-git/                       ← 整个项目根目录，Git 管理
│
├── repos/                            ← 【临时区】无极下载的项目放这里（gitignore 忽略）
│   ├── my-app-0919/                  ←   第 1 次从无极下载
│   ├── my-app-0920/                  ←   第 2 次从无极下载
│   └── another-project-0921/         ←   另一个项目也可以放这里
│
├── （你的业务代码文件）                ← 【正式区】同步过来的代码，Git 跟踪
│   ├── src/
│   ├── package.json
│   └── ...
│
├── wuji-sync.sh                      ← 从 repos/ 拉代码到正式区
├── wuji-push.sh                      ← 从正式区推代码回 repos/
├── QUICKSTART.md                     ← 本文件
├── README.md
├── .cursorrules
├── AI-GUIDE.md
├── .gitignore                        ← 已配置忽略 repos/*
└── .wuji-sync-ignore
```

**两个区域：**
- `repos/` = 临时区，放无极下载的原始代码，Git 不跟踪
- 根目录其余部分 = 正式区，同步过来的业务代码，Git 跟踪

---

## 操作流程

### 第一步：从无极下载代码到 repos/

从无极平台下载（或链接）代码时，把目标文件夹放在 `repos/` 下面：

```
repos/my-app-0919/
├── src/
├── package.json
└── ...
```

### 第二步：同步到正式区

```bash
# 同步并自动提交（指定 repos 下的具体项目）
bash wuji-sync.sh repos/my-app-0919 --commit

# 或者先预览再决定
bash wuji-sync.sh repos/my-app-0919 --dry-run
```

### 第三步：在正式区开发

用 VS Code 打开项目根目录，直接编辑同步过来的业务代码：

```bash
code .

# 改完提交
git add -A
git commit -m "feat: 新增XX功能"
```

### 第四步：推回无极

```bash
# 只推最近改过的文件（推荐）
bash wuji-push.sh repos/my-app-0919 --changed

# 或全量同步
bash wuji-push.sh repos/my-app-0919
```

---

## 下次连接无极（新文件夹）

无极断开后重新连接，会生成新文件夹，放进 repos 就行：

```bash
# 昨天是 repos/my-app-0919
# 今天变成 repos/my-app-0920，没关系

bash wuji-sync.sh repos/my-app-0920 --commit
# Git 仓库自动对比差异，记录变更
```

旧的临时文件夹可以随时删：

```bash
rm -rf repos/my-app-0919
```

---

## 一天的完整示例

```bash
# 1. 从无极下载代码到 repos/
#    （无极链接到 repos/dashboard-0919/）

# 2. 同步到 Git 仓库
bash wuji-sync.sh repos/dashboard-0919 --commit

# 3. 开发...
git add -A && git commit -m "feat: 新增报表页面"
git add -A && git commit -m "fix: 修复筛选条件bug"

# 4. 推回无极
bash wuji-push.sh repos/dashboard-0919 --changed

# 5. 清理旧的临时文件夹（可选）
rm -rf repos/dashboard-0918

# 6. 备份（可选）
git bundle create backup-$(date +%Y%m%d).bundle --all
```

---

## 提交信息建议

```bash
git commit -m "sync: 从无极同步代码"          # 同步时（--commit 自动生成）
git commit -m "feat: 新增XX功能"              # 新增功能
git commit -m "fix: 修复XX问题"               # 修 bug
git commit -m "style: 调整XX页面样式"          # 改样式
git commit -m "refactor: 重构XX模块"           # 重构
```

---

## 常见问题

### Q: repos/ 里可以放多个项目吗？

可以，但同步到正式区时一次只同步一个。根目录的正式区是一个项目的代码。如果你有多个无极项目需要管理，建议 clone 多份本仓库，每份管理一个项目。

### Q: repos/ 会越来越大吗？

会，因为每次下载是一个新文件夹。旧的用完随时删就行，反正代码已经同步到 Git 里了。

### Q: 可以自动同步吗？

不建议。手动更安全——避免编辑中的文件被覆盖，也能控制每次提交的粒度。

### Q: Git Bash 路径怎么写？

```
Windows 路径              Git Bash 路径
C:\Users\xxx\folder   →  /c/Users/xxx/folder
D:\projects\repo      →  /d/projects/repo
repos\my-app-0919     →  repos/my-app-0919（相对路径直接用）
```

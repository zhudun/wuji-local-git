# 快速操作手册

## 目录结构

```
wuji-local-git/
│
├── repos/                     ← 【临时区】无极下载的项目放这里（Git 忽略）
│   ├── my-app-0919/
│   ├── my-app-0920/
│   └── ...
│
├── project/                   ← 【正式区】同步目标，业务代码在这里（Git 跟踪）
│   ├── src/
│   ├── package.json
│   └── ...
│
├── wuji-sync.sh / .cmd        ← 拉：repos/xxx → project/
├── wuji-push.sh / .cmd        ← 推：project/ → repos/xxx
├── README.md
├── QUICKSTART.md
├── .cursorrules
├── AI-GUIDE.md
├── .gitignore
└── .wuji-sync-ignore
```

**根目录很清爽：** 只有 `repos/`、`project/` 两个子目录 + 工具文件，不会混杂。

---

## 日常操作（只需记住两条命令）

### 从无极拉代码

```bash
./wuji-sync.sh repos/20260919001 --commit
```

效果：`repos/20260919001/` 的内容 → 复制到 `project/` → 自动 git commit

### 推代码回无极

```bash
./wuji-push.sh repos/20260919001 --changed
```

效果：最近提交修改的文件从 `project/` → 复制回 `repos/20260919001/`

---

## 完整流程示例

```bash
# 1. 无极下载代码到 repos/ 下
#    （把无极链接目标设为 repos/20260919001）

# 2. 同步到 project/
./wuji-sync.sh repos/20260919001 --commit

# 3. 在 project/ 里开发（VS Code 打开根目录即可）
#    改完后提交
git add -A
git commit -m "feat: 新增XX功能"

# 4. 推回无极
./wuji-push.sh repos/20260919001 --changed

# 5. 下次无极生成新文件夹，放到 repos/ 下，换个名字就行
./wuji-sync.sh repos/20260920001 --commit
```

---

## 预览模式

不确定会做什么？加 `--dry-run`：

```bash
./wuji-sync.sh repos/20260919001 --dry-run
./wuji-push.sh repos/20260919001 --dry-run
```

---

## Windows 用户

在 **Git Bash** 中运行脚本，或者用 `.cmd` 包装在 PowerShell / cmd 中运行：

```
# Git Bash
./wuji-sync.sh repos/20260919001 --commit

# PowerShell / cmd
wuji-sync.cmd repos\20260919001 --commit
```

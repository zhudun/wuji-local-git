# 快速操作手册

## 目录结构应该怎么放

```
你的电脑
│
├── D:\projects\wuji-git-repo\        ← 【永久】Git 仓库，始终在这，不要动
│   ├── .git\
│   ├── wuji-sync.sh                  ← 从无极拉代码到这里
│   ├── wuji-push.sh                  ← 从这里推代码回无极
│   ├── src\                          ← 业务代码（同步进来的）
│   ├── package.json
│   └── ...
│
├── C:\Users\你\wuji-workspace-abc\   ← 【临时】无极链接的文件夹（平台自动生成）
│   ├── src\                          ← 无极平台的项目文件
│   ├── package.json
│   └── ...
│
└── （下次连接无极会生成另一个临时文件夹，路径不同，没关系）
```

**关键理解：**
- Git 仓库 = 你的"主基地"，路径固定，永远不变
- 无极链接文件夹 = "临时中转站"，每次路径不同，用完就不管了
- 两者之间通过脚本同步，临时文件夹放在哪里都行，不需要特定层级

---

## 怎样同步（手动触发，两条命令搞定）

同步是**手动触发**的，不是自动的。原因：自动同步有覆盖代码的风险，手动操作更安全可控。

### 操作 1：从无极拉代码到 Git 仓库

**时机：** 每天开始工作时，从无极下载代码到本地后执行一次

```bash
# 进入你的 Git 仓库
cd D:\projects\wuji-git-repo

# 同步（把无极下载的代码拉进来，自动生成一个提交）
bash wuji-sync.sh "C:\Users\你\wuji-workspace-abc" --commit
```

执行后会：
1. 把无极文件夹里的代码复制到 Git 仓库（覆盖同名文件）
2. 显示有哪些文件变了
3. 自动 `git commit`，记录这次同步

### 操作 2：从 Git 仓库推代码回无极

**时机：** 在 Git 仓库里开发完成后，要把修改同步回无极时

```bash
# 方式 A：只推最近一次提交改过的文件（推荐，精确快速）
bash wuji-push.sh "C:\Users\你\wuji-workspace-abc" --changed

# 方式 B：全量同步（安全，但慢一点）
bash wuji-push.sh "C:\Users\你\wuji-workspace-abc"
```

### 两个操作的预览模式

不确定会改什么？先加 `--dry-run` 预览一下：

```bash
bash wuji-sync.sh "C:\Users\你\wuji-workspace-abc" --dry-run
bash wuji-push.sh "C:\Users\你\wuji-workspace-abc" --dry-run
```

---

## 怎样提交代码（标准 Git 操作）

### 情况 A：从无极同步时自动提交

```bash
bash wuji-sync.sh "C:\Users\你\wuji-workspace-abc" --commit
# 会自动生成提交信息: "sync: 从无极平台同步代码 (2026-09-19 10:30)"
```

### 情况 B：自己开发后手动提交

```bash
# 查看改了什么
git status
git diff

# 提交
git add -A
git commit -m "feat: 新增用户管理页面"
```

### 提交信息的建议格式

```bash
git commit -m "sync: 从无极同步代码"          # 从无极拉代码时
git commit -m "feat: 新增XX功能"              # 新增功能
git commit -m "fix: 修复XX问题"               # 修 bug
git commit -m "style: 调整XX页面样式"          # 改样式
git commit -m "refactor: 重构XX模块"           # 重构代码
```

---

## 一天的完整流程示例

```bash
# ========== 早上 ==========

# 1. 打开无极平台，连接项目，代码下载到 C:\Users\你\wuji-workspace-xyz
# 2. 打开 Git Bash，同步到 Git 仓库
cd /d/projects/wuji-git-repo
bash wuji-sync.sh /c/Users/你/wuji-workspace-xyz --commit

# 3. 用 VS Code 打开 Git 仓库目录进行开发
code .


# ========== 开发中 ==========

# 4. 写代码... 改完一个功能就提交一次
git add -A
git commit -m "feat: 新增数据导出功能"

# 5. 又改了一些东西
git add -A
git commit -m "fix: 修复表格分页bug"


# ========== 要同步回无极时 ==========

# 6. 把修改推回无极链接的文件夹
bash wuji-push.sh /c/Users/你/wuji-workspace-xyz --changed

# 7. 回到无极平台提交/发布


# ========== 下班前（可选）==========

# 8. 备份
git bundle create /e/backup/wuji-$(date +%Y%m%d).bundle --all
```

---

## 常见问题

### Q: 无极链接断了，新建文件夹后路径变了怎么办？

没关系。脚本的参数就是无极文件夹的路径，每次指定新路径就行：

```bash
# 昨天的路径
bash wuji-sync.sh /c/Users/你/wuji-workspace-aaa --commit

# 今天路径变了，换一下就行
bash wuji-sync.sh /c/Users/你/wuji-workspace-bbb --commit
```

Git 仓库不变，变的只是临时文件夹的路径。

### Q: 可以改成自动同步吗？

技术上可以（用文件监听工具），但**不建议**：
- 自动同步可能在你编辑代码时覆盖正在改的文件
- 无法控制提交粒度（你希望一个功能一个提交，而不是每次保存都提交）
- 同步方向不明确（是从无极到 Git，还是 Git 到无极？）

手动两条命令（sync + push）更安全、更可控。

### Q: 我在 Git 仓库里直接开发，不通过无极行吗？

完全可以。推荐的开发方式就是：
1. 用 VS Code 打开 Git 仓库目录
2. 直接在里面写代码、调试
3. 开发完用 `wuji-push.sh` 推回无极发布

### Q: Git Bash 里路径怎么写？

```
Windows 路径             Git Bash 路径
C:\Users\xxx\folder  →  /c/Users/xxx/folder
D:\projects\repo     →  /d/projects/repo
```

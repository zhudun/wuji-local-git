# AI 助手处理指引

> **给 AI 看的文档**：在处理本项目代码之前，请通读本文件。
> 本文件适用于 Cursor、Copilot、ChatGPT、通义灵码等任何 AI 编码助手。

---

## 一、这是什么项目

这是一个 **腾讯无极（Wuji）低代码平台** 的前端项目，通过本地 Git 仓库进行版本管理。

### 关键事实

| 事项 | 说明 |
|------|------|
| 代码来源 | 腾讯无极平台，代码通过下载方式获取到本地 |
| 版本管理 | 纯本地 Git，没有远程仓库 |
| 保密级别 | 企业项目，代码不能以任何形式上传到外部 |
| 开发方式 | 在本地 Git 仓库中开发，完成后手动同步回无极平台 |
| 平台限制 | 每次连接无极会生成新的本地文件夹，用 `wuji-sync.sh` 同步到本仓库 |

### 代码流转路径

```
无极平台
  │
  ├──(下载)──→ 临时文件夹（每次不同）
  │                │
  │          wuji-sync.sh
  │                │
  │                ▼
  │           本 Git 仓库（永久，有完整历史）
  │                │
  │           本地开发、修改
  │                │
  └──(上传)──← 手动复制回无极
```

---

## 二、绝对禁止事项

以下操作在任何情况下都 **不允许** AI 建议或执行：

| 禁止操作 | 原因 |
|----------|------|
| `git push` / `git remote add` | 代码不能离开本机 |
| 建议使用 GitHub / GitLab / Gitee | 没有权限，且违反保密要求 |
| 调用外部 API 上传代码片段 | 企业保密 |
| 在注释或文档中写入公司敏感信息 | 企业保密 |
| 删除或修改 `.cursorrules` | 这是 AI 规则文件 |
| 删除 `wuji-sync.sh` 等工具文件 | 这些是工作流工具 |

---

## 三、仓库文件分类

在处理文件之前，先判断它属于哪一类：

### A 类：工作流工具（谨慎修改）

这些文件是管理工具，不是业务代码：

```
wuji-sync.sh          ← 无极代码同步脚本
.wuji-sync-ignore     ← 同步排除规则
.cursorrules          ← Cursor AI 规则
.gitignore            ← Git 忽略规则
AI-GUIDE.md           ← 本文件
README.md             ← 项目说明
```

修改规则：只有用户明确要求时才修改。不要在修复业务 bug 时顺手改这些文件。

### B 类：业务代码（`project/` 目录下，主要操作对象）

位于 `project/` 目录下，通过 `wuji-sync.sh` 从无极平台同步进来。这些文件有以下特点：

- **可能包含平台生成的代码**：结构、命名不一定符合常规前端规范，这是正常的
- **可能有平台特有的标记**：如 `<!-- wuji -->` 或 `/* wuji: xxx */` 等注释，不要删除
- **可能依赖平台运行时**：有些 API 或组件只在无极平台环境中可用
- **文件组织方式由平台决定**：不要擅自重构目录结构

---

## 四、处理代码的原则

### 4.1 修改业务代码

```
✓ 做：修复 bug、添加功能、优化逻辑
✓ 做：保持现有代码风格一致
✓ 做：用中文写注释
✗ 不做：大规模重构目录结构
✗ 不做：替换平台特有的写法为"通用最佳实践"
✗ 不做：添加无极平台可能不支持的新依赖
```

### 4.2 判断"这是不是平台特有代码"

如果看到以下特征，这段代码很可能是无极平台生成或平台特有的：

- 文件名或变量名包含 `wuji`、`wj`、`tencent`、`uc` 等关键词
- 代码中引用了 `@cloudbase`、`@tencent`、`wx.` 等 SDK
- 看起来像是自动生成的、格式高度统一的代码块
- 配置文件中有平台特定的字段

对这类代码：**保持原样，除非用户明确要求修改**。

### 4.3 生成新代码

- 确保与现有技术栈一致（看 `package.json` 确定框架和版本）
- 不引入外部网络请求（除非是项目本身需要的业务 API）
- 注释用中文
- 文件放在符合现有项目结构的位置

### 4.4 建议 Git 操作

只建议这些本地命令：

```bash
# ✓ 允许的
git add / git commit / git status / git log / git diff
git branch / git checkout / git merge / git rebase
git stash / git tag / git show / git reset
git bundle create ...    # 本地备份

# ✗ 禁止的
git push / git pull / git fetch
git remote add / git remote set-url
git clone <远程地址>
```

---

## 五、常见场景的标准处理方式

### 场景 1：用户说"帮我看看改了什么"

指的是无极同步后的变更，或本地开发的变更：

```bash
git status                   # 查看改了哪些文件
git diff                     # 查看未暂存的修改
git diff --cached            # 查看已暂存的修改
git diff --cached --stat     # 简要统计
```

### 场景 2：用户说"帮我回退"

```bash
git log --oneline -20                  # 查看最近 20 条提交
git checkout <commit> -- <file>        # 恢复单个文件
git revert <commit>                    # 安全地撤销某次提交
```

### 场景 3：用户说"帮我备份"

```bash
git bundle create backup-$(date +%Y%m%d).bundle --all
# 然后告诉用户：把这个 .bundle 文件复制到 U盘 或其他磁盘
```

### 场景 4：用户说"帮我同步无极的代码"

```bash
./wuji-sync.sh /path/to/wuji-download           # 同步并查看
./wuji-sync.sh /path/to/wuji-download --commit   # 同步并提交
./wuji-sync.sh /path/to/wuji-download --dry-run  # 只预览
```

### 场景 5：用户说"帮我把修改同步回无极"

```bash
# 方法 A：全量复制
rsync -av --exclude '.git' --exclude 'node_modules' \
  ./ /path/to/wuji-linked-folder/

# 方法 B：只复制最近修改的文件
git diff --name-only HEAD~1 | xargs -I{} cp {} /path/to/wuji-linked-folder/{}
```

### 场景 6：用户提到"冲突"

本地修改和无极端修改冲突时：

```bash
git stash                                          # 暂存本地修改
./wuji-sync.sh /path/to/wuji-download --commit     # 同步无极代码
git stash pop                                       # 恢复本地修改
# 如果有冲突，手动解决后 git add && git commit
```

---

## 六、回答用户问题时的注意事项

1. **用中文回答**（除非用户用英文提问）
2. **不要说"你可以推送到 GitHub"**——用户没有权限也不允许
3. **不要建议"让运维搭建 GitLab"**——不在用户的权限范围内
4. **理解"同步"的含义**——在本项目中，"同步"指的是用 `wuji-sync.sh` 将无极下载目录的文件复制到 Git 仓库，不是 `git pull/push`
5. **备份建议只限本地方式**——`git bundle`、复制到其他磁盘、U盘

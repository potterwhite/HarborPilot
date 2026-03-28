# AI 优先文档系统 — 可移植模板

> **目的：** 将结构化的、AI 优化的文档系统注入任何项目，
> 使编码 Agent（Claude Code、Cursor、Copilot 等）能够立即定向
> **无需扫描源代码**。
>
> 已在 SynapseERP 和 HarborPilot 中实战验证。复制结构；适配内容。
> **Related:** [English Version →](../../en/1-for-ai/ai_docs_system_template.md)

---

## 为什么这套系统存在

当 AI Agent 开始一次会话时，通常会做以下两件事之一：

| 没有本系统 | 有了本系统 |
|---|---|
| 读取 50–200 个源文件来理解项目 | 读取 3–4 个文档文件，然后写代码 |
| 花费 40–60% 的 token 预算仅用于*理解* | 花费 > 90% 的 token 在实际任务上 |
| 发明与现有模式冲突的模式 | 遵循项目自身的模式 |
| 跨会话忘记约定 | 每次会话在几秒内重新阅读相同文档 |

**关键洞察：AI 不需要阅读代码来理解结构 —
它需要维护良好的、人类可读的地图。**

启动成本：~2,000–4,000 tokens。
每次会话节省：20,000–80,000 tokens（消除源码扫描）。
ROI 在第一个任务后即为正值。

---

## 完整文件集

```
<仓库根目录>/
├── CLAUDE.md                             ← 每轮自动注入；会话入口
└── docs/
    └── architecture/
        ├── 00_INDEX.md                   ← 人类 + AI 导航中心（一个表格看所有文档）
        ├── 1-for-ai/
        │   ├── guide.md                  ← 规则 · 提交格式 · 工作流 · 架构事实
        │   ├── codebase_map.md           ← 文件级参考（替代源码扫描）
        │   └── <domain>.md              ← 深度参考文档（API 规范、解析规则等）
        ├── 2-progress/
        │   ├── progress.md              ← 阶段状态 · 已完成步骤 · 路线图
        │   └── NEED_TO_DO.md           ← 活跃 Bug/任务积压（checkbox 格式）
        └── 3-highlights/
            ├── architecture_vision.md   ← 战略定位 · 设计决策
            └── archived/               ← 已被取代的决策 — 保留以备参考，永不删除
```

**阅读频率：**

| 文件 | 何时阅读 | 用途 |
|---|---|---|
| `CLAUDE.md` | 每轮（自动注入） | 入口 — 必须保持 60 行以下 |
| `guide.md` | 每次会话一次 | 规则 + 事实 |
| `codebase_map.md` | 每次会话一次 | 结构 + 文件参考 |
| `progress.md` | 每次会话一次 | 当前阶段上下文 |
| `NEED_TO_DO.md` | 处理 Bug/任务时 | 活跃积压 |
| `00_INDEX.md` | 导航时 | 所有文档的主目录 |
| 深度参考文档 | 仅任务需要时 | API 规范、领域规则等 |

---

## 文件 0：`CLAUDE.md` — 会话入口

**由 Claude Code 在每个提示词中自动注入。** 保持 60 行以下 — 所有细节放入它指向的文档文件中。

文件包含四个章节：

1. **会话开始协议** — 有序阅读列表，明确写明"不要扫描 src/"
2. **要求** — 语言、沟通风格
3. **命令** — 项目的关键 CLI 命令（从 README 复制）
4. **文档地图** — 将"需求 → 文件"映射的一行表格

### 模板

```markdown
# CLAUDE.md

本文件为 Claude Code 在此仓库工作时提供基本指引。
**获取完整上下文，请先阅读文档**（见下方）。

## ⚠️ 会话开始协议

**在编写任何代码之前**，按顺序阅读：

1. `docs/architecture/1-for-ai/guide.md` — 工作规则、提交格式、关键架构事实
2. `docs/architecture/1-for-ai/codebase_map.md` — 完整代码库地图（不要扫描文件代替）

然后检查 `docs/architecture/2-progress/progress.md` 了解当前阶段状态。

在阅读以上内容之前，**不要**扫描 `<主要源码目录>/`。

---

## 要求

- 所有源码和注释必须使用**英文**
- 与我沟通使用**<首选语言>**
- 不要随意结束会话 — 始终提示用户下一步

---

## 命令

<在此粘贴项目的关键 CLI 命令>

---

## 文档地图

| 需求 | 文件 |
|---|---|
| 工作规则 + 提交格式 | `docs/architecture/1-for-ai/guide.md` |
| 代码库结构 | `docs/architecture/1-for-ai/codebase_map.md` |
| 阶段进度 + 路线图 | `docs/architecture/2-progress/progress.md` |
| 活跃任务积压 | `docs/architecture/2-progress/NEED_TO_DO.md` |
| 架构愿景 | `docs/architecture/3-highlights/architecture_vision.md` |
```

> **为什么要指名具体的源码目录？** "不要扫描 src/" 太笼统。
> 写明真实路径：`不要扫描 backend/src/ 或 frontend/src/`。Agent 对具体指令的
> 遵从比模糊指令更可靠。

---

## 文件 1：`docs/architecture/00_INDEX.md` — 导航中心

一个轻量级索引，让任何读者（人类或 AI）一眼找到任何文档。
它**不是**内容文件 — 它只包含指向其他地方的表格。

```markdown
# <项目名> — 文档索引

> 最后更新：<日期> · 状态：<当前阶段摘要>

---

## 1 · 面向 AI Agent 与开发者（`1-for-ai/`）

每次会话从此开始。在接触任何代码之前按顺序阅读。

| 文档 | 用途 |
|---|---|
| [`1-for-ai/guide.md`](1-for-ai/guide.md) | ⭐ 工作规则、提交格式、工作流、关键架构事实 |
| [`1-for-ai/codebase_map.md`](1-for-ai/codebase_map.md) | ⭐ 完整代码库结构 — 用此文件替代扫描 |
| [`1-for-ai/<domain>.md`](1-for-ai/<domain>.md) | <用途> |

---

## 2 · 项目进度（`2-progress/`）

| 文档 | 用途 |
|---|---|
| [`2-progress/progress.md`](2-progress/progress.md) | 所有阶段步骤详情、当前状态、未来路线图 |
| [`2-progress/NEED_TO_DO.md`](2-progress/NEED_TO_DO.md) | 活跃 Bug/任务积压（工作笔记） |

---

## 3 · 架构与亮点（`3-highlights/`）

| 文档 | 用途 |
|---|---|
| [`3-highlights/architecture_vision.md`](3-highlights/architecture_vision.md) | 战略定位与架构哲学 |
| [`3-highlights/archived/`](3-highlights/archived/) | 历史决策 — 保留以备参考，不再活跃 |
```

---

## 文件 2：`1-for-ai/guide.md` — 工作规则

每次会话在 codebase_map 之前阅读。包含：

1. **阅读顺序** — 本文件之后去哪里
2. **不可违反的规则** — 语言、提交、文档
3. **提交信息格式** — 带示例的精确格式
4. **如何处理请求类型** — 新功能 / Bug / 重构
5. **常见陷阱** — 项目特定的错误模式
6. **关键架构事实** — Agent 绝不能违反的 5–10 个事实
7. **开发命令** — 镜像 CLAUDE.md 中的命令（冗余是刻意为之）

---

## 文件 3：`1-for-ai/codebase_map.md` — 最重要的文件

这替代了源码扫描。一份写得好的地图能让 Agent 在不打开文件的情况下操作任何文件。

### 必需章节

1. **警告头部** + 维护规则 + 最后更新（附原因）
2. **仓库根目录布局**（ASCII 树形图）
3. **每个非琐碎模块的文件级参考**
4. **关键架构模式**（编号，每条 1–2 句）

### 优与劣的条目示例

**差**（太模糊 — 迫使 Agent 还是要打开文件）：
```
### `scripts/port_calc.sh`
端口计算脚本。
```

**好**（足够的细节，无需打开文件即可操作）：
```
### `scripts/port_calc.sh`
在每个配置加载器中 Layer 3 之后 source。两种互斥模式：
- MODE A（推荐）：在平台 .env 中设置 `PORT_SLOT` → 所有端口自动派生
  - 公式：CLIENT_SSH_PORT = 2109 + PORT_SLOT × 10，GDB_PORT = 2345 + PORT_SLOT × 10
- MODE B（遗留）：显式设置 `CLIENT_SSH_PORT` 和 `GDB_PORT`（无 PORT_SLOT）
- 混用两种模式 → 致命错误，含修复说明
- 计算后清除内部 `_*` 变量
```

---

## 文件 4：`2-progress/progress.md` — 阶段状态

防止 Agent 提议已完成的功能或与已完成的架构决策相矛盾。

---

## 文件 5：`2-progress/NEED_TO_DO.md` — 活跃积压

简单的 checkbox 列表。Agent 读取它，处理未勾选的条目，勾选完成的。

### 格式规则

```markdown
- **改完就把下面的 checkbox 勾上**   ← 始终保留这行提醒在顶部

<月><日>.<年> <时间>
- [x] <已完成条目>
    ```bash
    <如有相关则附上错误输出>
    ```
- [ ] <待处理条目>
- [ ] <待处理条目>


<更早的日期组在下方>
<月><日>.<年> <时间>
- [x] <更早的已完成条目>
```

**约定：**
- 最新日期组在**顶部**
- 已勾选 `[x]` = 已完成 — 永不删除，它们是历史记录
- Bug 输出使用内联代码块，让 Agent 立即理解上下文
- 每个工作会话一个日期组（如果一天有多个会话则不按天划分）

---

## 可选：深度参考文档（`1-for-ai/<domain>.md`）

对于拥有复杂领域规则且会让 codebase_map 显得臃肿的项目，添加单独的参考文件。
只有当你有超过 ~30 行 Agent 需要定期查阅的领域特定规则时，才创建一个。

| 示例文件 | 何时创建 |
|---|---|
| `api_spec.md` | REST API 有 > 10 个端点且请求/响应形状不明显 |
| `obsidian_parsing_rules.md` | 自定义文件格式解析，有许多边缘情况 |
| `frontend_config.md` | 非标准构建配置、环境变量约定、代理规则 |
| `config_schema.md` | 有许多字段、类型和交互规则的配置系统 |

---

## `3-highlights/archived/` 约定

当一个架构决策被取代时，**永不删除它**。将其移动到
`3-highlights/archived/`，保留原始文件名。在顶部添加一行注释：

```markdown
> **已归档** — 被 Phase 5.2 DB-Primary 决策取代（2026-03-25）。
> 仅保留以备参考。
```

这为 Agent（和新团队成员）提供了当前架构形成原因的完整历史。

---

## 注入新项目 — 检查清单

```
[ ] 仓库根目录的 CLAUDE.md
      - 指向 guide + codebase_map 的会话开始协议
      - 明确写出 "不要扫描 <源码目录>/"
      - 关键 CLI 命令
      - 文档地图表格
      - 保持 60 行以下

[ ] docs/architecture/00_INDEX.md
      - 三个表格：1-for-ai / 2-progress / 3-highlights
      - 每个文件一行，含相对链接和一行说明

[ ] docs/architecture/1-for-ai/guide.md
      - 阅读顺序章节（深度参考文档加"仅在需要时"）
      - 不可违反规则（语言 + 提交 + 文档维护）
      - 带本项目真实示例的提交格式
      - 请求处理：功能 / Bug / 重构
      - 常见陷阱（至少 5 个，项目特定）
      - 关键架构事实（5–10 个，Agent 最常出错的事情）
      - 开发命令（CLAUDE.md 的副本 — 刻意冗余）

[ ] docs/architecture/1-for-ai/codebase_map.md
      - 顶部嵌入维护规则的警告头部
      - "最后更新：<日期>（<原因>）" 行
      - 仓库根目录完整 ASCII 树形图
      - 每个非琐碎文件：路径 + 功能 + 关键变量/模式
      - 末尾的架构模式章节

[ ] docs/architecture/2-progress/progress.md
      - 总体状态表（所有阶段，emoji 状态）
      - "当前活跃：Phase X.Y" 行
      - 每个已完成和进行中阶段的详情

[ ] docs/architecture/2-progress/NEED_TO_DO.md
      - 顶部提醒行
      - 至少一个日期组
      - Checkbox 格式；最新在顶部

[ ] docs/architecture/3-highlights/architecture_vision.md
      - 为什么项目这样构建
      - 带理由的关键设计决策

[ ] 在 CLAUDE.md、guide.md 和 codebase_map 头部都添加维护规则：
      "任何修改 codebase_map 中文件的 Agent 必须在同一次提交中更新 codebase_map。"
```

---

## 设置本系统时的常见错误

| ❌ 错误 | ✅ 正确做法 |
|---|---|
| CLAUDE.md 超过 100 行 | 保持 60 行以下；所有细节移到 guide.md |
| codebase_map 条目只有一句话："包含 API 视图" | 包含函数名、关键参数、认证要求 |
| `最后更新` 日期没有原因 | 始终加原因：`（新增 X，将 Y 更新为 Z）` |
| 删除已被取代的设计文档 | 移动到 `3-highlights/archived/` |
| 直接在 codebase_map 中放领域规则 | 超过 30 行时创建单独的 `1-for-ai/<domain>.md` |
| 只在 guide.md 中添加维护规则 | 也嵌入到 codebase_map 头部 — 那是 Agent 编码前最后读到的地方 |
| 告诉 Agent "不要扫描 src/" | 告诉 Agent 确切路径："不要扫描 `backend/src/` 或 `scripts/`" |
| progress.md 只列出未来阶段 | 包含带提交哈希的已完成阶段 — 历史防止重复 |

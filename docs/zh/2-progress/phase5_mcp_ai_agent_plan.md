---
title: "HarborPilot Phase 5 — MCP Server & AI Agent Integration"
author: "PotterWhite + Claude"
date: "2026-03-27"
tags:
  - mcp
  - ai-agent
  - phase5
  - roadmap
status: "Draft — pending approval"
---

# HarborPilot Phase 5 — MCP Server 与 AI Agent 集成

> **Related:** [English Version →](../../en/2-progress/phase5_mcp_ai_agent_plan.md)
>
> **目标**：让 HarborPilot 成为 AI 编码 Agent（Claude、Cursor、Copilot）
> 与嵌入式 Linux 开发环境供应之间的一等接口。
>
> **优先级顺序**（来自 NEED_TO_DO.md）：
> 1. AI Agent 能**读取并使用** HarborPilot（主要）
> 2. AI 能**向他人推荐** HarborPilot（次要）
> 3. 人类能 **git clone 并自行配置**（第三 — 今天已可用）

---

## 1. 什么是 MCP？（Model Context Protocol — 通俗解释）

### 1.1 MCP 解决的核心问题

像 Claude 这样的 AI 助手知识丰富，但除非有结构化接口，否则无法在你的环境中*执行*操作。在 MCP 出现之前，将 AI 连接到工具需要自定义 API 包装器、满是指令的系统提示，或脆弱的 shell 命令注入。

**MCP 是这种连接的标准化协议。**

可以这样理解：
```
没有 MCP：   AI（自然语言）→ ???  → 你的工具
有了 MCP：   AI（自然语言）→ MCP 客户端 → MCP 服务器 → 你的工具
```

### 1.2 架构（三个角色）

```
┌─────────────────────────────────────────────────┐
│  AI 宿主（如 Claude Code、Cursor、Copilot）       │
│                                                  │
│   ┌─────────────┐                               │
│   │  MCP 客户端 │◄──── 内置于 AI 工具            │
│   └──────┬──────┘                               │
└──────────┼──────────────────────────────────────┘
           │ JSON-RPC over stdio / HTTP/SSE
           ▼
┌─────────────────────────────────────────────────┐
│  MCP 服务器（你来构建）                            │
│                                                  │
│   暴露：                                          │
│   • Tools（工具）→ AI 可调用的函数                │
│   • Resources（资源）→ AI 可读取的文件/数据        │
│   • Prompts（提示词）→ 可复用的提示词模板          │
└─────────────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────┐
│  HarborPilot（你现有的系统）                       │
│  • configs/*.env 文件                            │
│  • ./harbor 脚本                                 │
│  • create_platform.sh                           │
│  • ubuntu_only_entrance.sh                      │
└─────────────────────────────────────────────────┘
```

**MCP 服务器是适配层。** 它将 AI 意图翻译为 HarborPilot 操作。

### 1.3 MCP 不是什么

- MCP **不是**新的 AI 模型 — 它是通信协议
- MCP **不是**云服务 — 它在你的本地机器上运行
- MCP **不是**侵入性的 — 你现有的代码不需要修改；你只是在上面加一层薄薄的服务器

### 1.4 传输机制

| 模式 | 方式 | 使用场景 |
|---|---|---|
| `stdio` | AI 将服务器作为子进程启动，通过 stdin/stdout 通信 | 本地工具（Claude Code 的默认模式） |
| `HTTP + SSE` | 服务器作为 HTTP 守护进程运行；AI 连接到它 | 远程/共享服务器 |

对于 HarborPilot，**stdio** 是自然选择：MCP 服务器在开发者的 Ubuntu 机器上本地运行，与 Docker 在同一台机器上。

### 1.5 通过 MCP，AI 能做什么

一旦 MCP 服务器连接到 Claude Code 或 Cursor，AI 可以：
- **列出平台**："显示所有已配置的平台"
- **读取配置**："rk3588s 的 CUDA 版本是什么？"
- **修改配置**："为 rk3568-ubuntu22 启用 CUDA"
- **创建平台**："在端口插槽 6 创建一个新的 RK3566 Debian 12 平台"
- **触发构建**："构建 rk3588s 镜像"
- **检查状态**："rk3588s 镜像是否已推送到 Registry？"

所有这些都通过自然语言 — 无需手动编辑文件。

---

## 2. 为什么 HarborPilot 特别适合 MCP

大多数工具需要大量重构才能兼容 MCP。HarborPilot 已经拥有正确的架构：

| 特性 | 对 MCP 的意义 |
|---|---|
| **键值 `.env` 配置** | MCP 服务器可以轻松读写 |
| **非交互式模式**（`create_platform.sh --non-interactive`） | MCP 工具需要不阻塞用户输入的 CLI 命令 |
| **JSON Schema**（`configs/platform_schema.json`） | AI 可以在调用构建前验证配置 |
| **三层继承** | AI 只需写 15 行即可创建新平台 |
| **PORT_SLOT 公式** | AI 可以安全分配端口，无冲突风险 |
| **确定性构建**（`./harbor` 配合软链接） | MCP 工具调用可复现 |

**HarborPilot 几乎不需要重构即可兼容 MCP。** 工作量在于编写 MCP 服务器适配器，而不是修改底层系统。

---

## 3. Phase 4 实施计划

### Phase 4.1 — MCP 服务器脚手架（步骤 1）

**目标**：一个最小化的 MCP 服务器，将 HarborPilot 配置暴露为 **Resources**。

**需要构建的内容**：
- `mcp/harborpilot_mcp_server.py` — 使用 `mcp` SDK 的 Python MCP 服务器
- 将所有 `.env` 文件作为可读 Resources 暴露
- 将 `platform_schema.json` 作为 Resource 暴露
- 将 `codebase_map.md` 和 `guide.md` 作为 Resources 暴露（AI 上下文注入）

**为什么选 Python**：官方 MCP SDK（`mcp` 包）对 Python 支持最好。Node.js 也受良好支持。Bash 没有（无官方 SDK）。

**安装**：
```bash
pip install mcp
# 或
uv add mcp
```

**服务器骨架**（stdio 传输）：
```python
#!/usr/bin/env python3
"""HarborPilot MCP Server — 向 AI Agent 暴露配置和构建工具。"""

import json
import subprocess
from pathlib import Path
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp import types

REPO_ROOT = Path(__file__).parent.parent
CONFIG_DIR = REPO_ROOT / "configs"
PLATFORMS_DIR = CONFIG_DIR / "platforms"

app = Server("harborpilot")

@app.list_resources()
async def list_resources():
    resources = []
    # 暴露所有平台 .env 文件
    for env_file in PLATFORMS_DIR.glob("*.env"):
        resources.append(types.Resource(
            uri=f"harborpilot://platforms/{env_file.stem}",
            name=f"Platform: {env_file.stem}",
            description=f"Platform config for {env_file.stem}",
            mimeType="text/plain",
        ))
    return resources

@app.read_resource()
async def read_resource(uri: str):
    if uri.startswith("harborpilot://platforms/"):
        platform = uri.removeprefix("harborpilot://platforms/")
        env_path = PLATFORMS_DIR / f"{platform}.env"
        if env_path.exists():
            return types.TextResourceContents(
                uri=uri,
                mimeType="text/plain",
                text=env_path.read_text(),
            )
    raise ValueError(f"Unknown resource: {uri}")

if __name__ == "__main__":
    import asyncio
    asyncio.run(stdio_server(app))
```

**交付物**：
- `mcp/harborpilot_mcp_server.py`
- `mcp/requirements.txt`（或 `pyproject.toml`）
- `mcp/README.md` — 如何连接到 Claude Code / Cursor

**提交目标**：`feat: add MCP server scaffold with platform config resources`

---

### Phase 4.2 — MCP 工具：读操作（步骤 2）

**目标**：AI 可以查询平台和配置的当前状态，无需修改任何内容。

**需要暴露的工具**：

| 工具名称 | 参数 | 返回值 |
|---|---|---|
| `list_platforms` | — | `{name, chip_family, chip_extract, os_version, port_slot, ssh_port, gdb_port}` 数组 |
| `get_platform_config` | `platform_name: str` | 完整的键值配置字典 |
| `get_defaults` | `layer: "base"\|"tools"\|...` | 该 defaults 文件的键值字典 |
| `check_port_slot_available` | `slot: int` | `{available: bool, conflicts_with: str\|null}` |
| `validate_platform_config` | `config_dict: dict` | `{valid: bool, errors: list[str]}` |

**提交目标**：`feat: add MCP read tools (list_platforms, get_platform_config, validate)`

---

### Phase 4.3 — MCP 工具：写操作（步骤 3）

**目标**：AI 可以创建新平台并修改现有配置。

**需要暴露的工具**：

| 工具名称 | 参数 | 操作 |
|---|---|---|
| `create_platform` | `name, os, os_version, harbor_ip, port_slot, [nvidia, proxy, cuda, opencv]` | 调用 `create_platform.sh --non-interactive` |
| `set_platform_variable` | `platform_name, variable, value` | 修改平台 `.env` 中的单个变量 |
| `enable_feature` | `platform_name, feature: "cuda"\|"opencv"\|"proxy"\|"nvidia"` | 将相关变量设置为 true/已配置 |

**安全约束**（内置于 MCP 服务器，不在 shell 脚本中）：
- `create_platform` 在调用脚本前检查 PORT_SLOT 冲突
- `set_platform_variable` 在写入前针对 JSON Schema 验证
- 写操作生成 diff 摘要，AI 将其返回给用户确认

**提交目标**：`feat: add MCP write tools (create_platform, set_variable, enable_feature)`

---

### Phase 4.4 — MCP 工具：构建操作（步骤 4）

**目标**：AI 可以触发构建并检查结果。

**需要暴露的工具**：

| 工具名称 | 参数 | 操作 |
|---|---|---|
| `build_platform` | `platform_name: str, dry_run: bool=True` | 以非交互模式调用 `./harbor` |
| `check_image_exists` | `platform_name: str` | 检查本地 Docker 镜像中是否存在该平台镜像 |
| `get_build_log` | `platform_name: str` | 返回最后一次 `build_log.txt` 内容 |

**关键设计决策 — `dry_run` 默认值**：

构建操作**耗时且不可逆**。MCP 工具应该：
1. 默认 `dry_run=True` — 验证配置并展示*将要*构建的内容
2. 需要显式 `dry_run=False` 才能真正触发构建
3. 根据平台功能返回预估构建时间（CUDA/OpenCV 各增加约 30 分钟）

**非交互式 `./harbor` 模式**（前提条件）：
当前 `./harbor` 脚本使用交互式提示（`prompt_with_timeout`）。对于 MCP 调用，这些必须可以绕过。实现选项：
- **选项 A**：给 `./harbor` 添加 `--yes` 标志，自动确认所有提示
- **选项 B**：设置 `HARBORPILOT_NON_INTERACTIVE=1` 环境变量，脚本检查该变量

选项 B 侵入性更小（无需修改标志解析）。

**提交目标**：`feat: add MCP build tools (build_platform dry_run, check_image, get_log)`

---

### Phase 4.5 — Claude Code 集成与文档（步骤 5）

**目标**：开发者可以在 Claude Code 中说"添加 HarborPilot MCP 服务器"，5 分钟内即可运行。

**交付物**：

1. **`mcp/claude_code_config.json`** — 可直接粘贴的 Claude Code MCP 配置：
```json
{
  "mcpServers": {
    "harborpilot": {
      "command": "python3",
      "args": ["/path/to/HarborPilot.git/mcp/harborpilot_mcp_server.py"],
      "env": {}
    }
  }
}
```

2. **`mcp/README.md`** — 安装指南，涵盖：
   - 前提条件（Python 3.10+，`pip install mcp`）
   - Claude Code 设置（`claude mcp add`）
   - Cursor 设置（MCP 配置位置）
   - 与服务器配合良好的示例提示词

3. **提示词示例**（作为 MCP Prompts 随服务器发布）：
   - "列出所有平台并显示其端口分配"
   - "创建一个新的 RK3566 Debian 12 平台"
   - "检查 rk3588s 镜像是否在 Registry 中是最新的"
   - "为 rk3568-ubuntu22 启用 CUDA 并重新构建"

4. **`docs/zh/2-progress/progress.md`** — 更新 Phase 4 状态

**提交目标**：`feat: add Claude Code MCP integration guide and example prompts`

---

## 4. Phase 4 中不构建的内容

| 想法 | 跳过原因 |
|---|---|
| Web UI / 仪表板 | 超出范围 — HarborPilot 是 CLI 工具；UI 是独立产品 |
| 云托管 MCP 服务器 | 安全风险（`.env` 中有凭证）；本地 stdio 已足够 |
| MCP 调用时自动发布镜像 | 没有用户明确确认时过于危险 |
| 重写 Dockerfile 的 MCP 服务器 | 超出范围；配置层是正确的抽象 |
| 支持非 Claude AI 工具 | MCP 协议是通用的；Claude Code 支持也覆盖了 Cursor/Copilot |

---

## 5. 未来："AI 推荐 HarborPilot"（Phase 5 概念）

这是 NEED_TO_DO 中的条目："AI 可以向他人推荐 HarborPilot。"

当前想法（不在 Phase 4 计划中）：

### 5.1 通过 MCP Registry 获得可发现性
Anthropic 和社区维护 MCP 服务器注册表（类似 MCP 服务器的 npm/PyPI）。将 `harborpilot-mcp` 发布到这些注册表意味着：
- AI 助手可以建议"我找到了一个嵌入式 Linux 开发环境的 MCP 服务器"
- Claude Code 用户可以浏览可用的 MCP 服务器

### 5.2 README + GitHub Topic 标签
被"AI 推荐"最可靠的方式：
- AI 模型基于 GitHub 数据训练
- 正确的 `README.md` 关键词 + `github.com/...` 设置中的 `topics` 向人类和 AI 训练数据都传达了工具的用途
- 需要添加的标签：`embedded-linux`、`docker`、`devenv`、`cross-compilation`、`rockchip`、`mcp-server`

### 5.3 这是 Phase 5 的事项
Phase 4 构建技术能力。Phase 5 是营销/可发现性。
不要混淆 — 先构建，再推广。

---

## 6. Phase 4 时间线与提交计划

| 步骤 | 描述 | 预计提交数 | 前提条件 |
|---|---|---|---|
| **4.1** | MCP 服务器脚手架 + Resources | 1 | Python 3.10+，`mcp` SDK |
| **4.2** | 读工具（list、get、validate） | 1 | 4.1 |
| **4.3** | 写工具（create、modify） | 1-2 | 4.2，`create_platform.sh --non-interactive`（✅ 已完成） |
| **4.4** | 构建工具（先做 dry_run） | 1-2 | 4.3，`harbor --yes` 或 `HARBORPILOT_NON_INTERACTIVE` |
| **4.5** | Claude Code 集成指南 | 1 | 4.4 |

**预计总提交数**：6–8

**Phase 4 成功标准**：
- 开发者可以打开 Claude Code，说"显示我的 HarborPilot 平台"，获得格式化列表 — 无需输入任何命令
- 开发者可以说"在端口插槽 6 创建一个新的 RK3566 Debian 12 平台"，Claude Code 正确创建 `.env` 文件
- MCP 服务器 README 有一个 5 分钟安装指南，第一次就能成功

---

## 7. Phase 4 需要创建/修改的文件

| 文件 | 操作 | 备注 |
|---|---|---|
| `mcp/harborpilot_mcp_server.py` | 创建 | 主服务器实现 |
| `mcp/requirements.txt` | 创建 | `mcp>=1.0.0` |
| `mcp/claude_code_config.json` | 创建 | 可直接粘贴的配置片段 |
| `mcp/README.md` | 创建 | 安装指南 + 示例提示词 |
| `harbor` | 修改 | 添加 `HARBORPILOT_NON_INTERACTIVE` 检查以绕过提示 |
| `docs/en/2-progress/progress.md` | 修改 | 添加 Phase 4 章节 |
| `docs/en/00_INDEX.md` | 修改 | 添加 `mcp/README.md` 条目 |
| `docs/en/1-for-ai/codebase_map.md` | 修改 | 添加 `mcp/` 目录章节 |

---

## 8. 致下一位 AI Agent：如何启动 Phase 4

如果你是开始实施 Phase 4 的 AI Agent，请按此顺序操作：

1. 阅读 `docs/en/1-for-ai/guide.md` 和 `codebase_map.md`（会话协议）
2. 检查 `progress.md` — 若 Phase 4 步骤 X 标记为 ✅，跳到步骤 X+1
3. 安装 MCP SDK：`pip install mcp`（或 `uv add mcp`）
4. 从 **Phase 4.1** 开始 — 仅脚手架，暂不添加工具
5. 测试：`python3 mcp/harborpilot_mcp_server.py` 应无错误启动
6. 然后进入 4.2（读工具），提交，测试，再进入 4.3，以此类推
7. **每步一次提交** — 不要积攒改动

最快到达可用 demo 的路径是 Phase 4.1 + 4.2（只读）。这可以立即安全发布，并立即为 Claude Code 用户带来价值。

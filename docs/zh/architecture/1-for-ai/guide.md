# HarborPilot — AI Agent 工作指南

> **目标读者：** AI 编码 Agent（Claude Code、Cursor 等）
> **在接触任何代码之前，请先阅读本文。**
> **Related:** [English Version →](../../../../en/architecture/1-for-ai/guide.md)

---

## 1. 阅读顺序（每次会话）

1. **本文件** — 了解如何在本仓库工作
2. **[`codebase_map.md`](codebase_map.md)** — 完整代码库结构（替代扫描源码，节省 50%+ token）
3. **[`../2-progress/progress.md`](../2-progress/progress.md)** — 当前阶段状态与活跃任务
4. **相关参考文档** — 仅在任务需要时查阅（`../4-reference/config_layers.md` 等）

---

## 2. 不可违反的规则

### 代码
- 所有源码和注释必须使用**英文**
- 与人类沟通使用**中文**
- **不要**结束会话 — 始终提示用户下一步操作

### 提交
- **每步一次提交** — 不要积攒改动后一次性提交
- 严格遵循下方的提交信息格式
- 绝不提交有 Bug 或未测试的代码

### 文档
- 修改 `codebase_map.md` 中列出的任何文件后，必须在同一次提交中更新该文件
- 完成一个阶段步骤后，在 `progress.md` 中更新状态

---

## 3. 提交信息格式

```
<类型>: <主题>

<正文>

<尾部>
```

**类型**（必填）：`feat` · `fix` · `docs` · `refactor` · `perf` · `test` · `build` · `chore`

**主题**（必填）：英文，≤70 字符，现在时，不大写首字母
- ✅ `fix: handle pre-existing UID/GID in func_create_user for Ubuntu 24.04`
- ✅ `feat: add --non-interactive mode to create_platform.sh`
- ✅ `refactor: replace sed template rendering with envsubst in all 3 stages`
- ❌ `Fixed bugs and updated stuff`

**正文**（推荐）：用列表说明做了什么、为什么这么做

**尾部**（推荐）：`Phase X.Y Step Z complete.`

---

## 4. 如何处理人类请求

### "新增功能"
1. 提问澄清（受影响的脚本、配置变更、平台影响）
2. 在 `docs/architecture/` 中写计划 — **尚不写代码**
3. 等待批准
4. 分步实现，每步一次提交

### "有 Bug"
1. 复现并理解根本原因
2. 修复 — 跨受影响平台测试（检查 OS_VERSION 条件语句）
3. 用 `fix:` 前缀提交

### "重构 / 优化某事"
1. 在 `docs/architecture/` 中写重构计划
2. 等待批准
3. 分步执行

### "添加新平台"
1. 使用 `create_platform.sh --non-interactive` 或向导
2. 验证 PORT_SLOT 与现有平台不冲突
3. 用 `./harbor` 测试构建（至少验证配置可以干净加载）

---

## 5. 常见陷阱

| ❌ 错误做法 | ✅ 正确做法 |
|---|---|
| 改 10 个文件再做一次大提交 | 每个逻辑步骤后提交 |
| 不读 codebase_map 就开始写代码 | 先读 codebase_map |
| 改代码后忘记更新 codebase_map | 始终在同一次提交中同步 codebase_map |
| 提交信息笼统如"fix bugs" | 具体说明：`fix: handle pre-existing UID/GID in func_create_user` |
| 在脚本中硬编码端口号 | 使用 PORT_SLOT 和 port_calc.sh 派生所有端口 |
| 在 defaults/ 中硬编码平台特定值 | 覆盖值只放在 `configs/platforms/<name>.env` |
| 新增配置变量只加到某一平台 | 先在 `configs/defaults/` 中加默认值，再按平台覆盖 |
| 修改 `*_template` 文件后未测试 envsubst | 始终验证渲染结果是否符合预期 |
| 忘记 OS_VERSION 条件分支 | Ubuntu 20.04 / 22.04 / 24.04 包和 apt 格式不同 |
| 使用 `sed` 做模板渲染 | 使用 `envsubst` — sed 方案已移除 |

---

## 6. 关键架构事实

1. **三层配置继承**：`configs/defaults/*.env`（Layer 1，全局）→ `configs/platform-independent/common.env`（Layer 2，项目常量）→ `configs/platforms/<platform>.env`（Layer 3，覆盖）。最后一层优先。平台文件只包含**与默认值不同**的内容。

2. **PORT_SLOT 是端口的唯一来源**：`CLIENT_SSH_PORT = 2109 + PORT_SLOT × 10`，`GDB_PORT = 2345 + PORT_SLOT × 10`。由 `scripts/port_calc.sh` 计算。绝不硬编码端口 — 始终设置 PORT_SLOT。

3. **模板渲染使用 `envsubst`**：stage 3/4/5 中所有 `*_template` 文件均通过 `envsubst`（来自 `gettext-base`）渲染。`sed` 方案已移除。

4. **5 阶段 Dockerfile**：`stage_1st_base`（OS + 包 + 用户）→ `stage_2nd_tools`（CUDA、OpenCV、开发工具）→ `stage_3rd_sdk`（SDK 初始化 + 辅助脚本）→ `stage_4th_config`（环境变量 + 代理）→ `stage_5th_final`（工作区 + 入口点 + 标签）。

5. **`harbor` 是顶层编排器**：加载全部 3 层配置，运行 `port_calc.sh`，然后调用 `build.sh` → 打 tag → 推送 → 清理。它是构建的唯一入口。

6. **`ubuntu_only_entrance.sh` 是客户端入口**：加载同样的 3 层配置，从环境变量动态生成 `docker-compose.yaml`（含条件 NVIDIA GPU），管理容器生命周期（`start`/`stop`/`restart`/`recreate`/`remove`）。

7. **平台配置使用 `${VAR}` 自引用**：如 `IMAGE_NAME="${PRODUCT_NAME}-dev-env"`。这是 bash 变量展开，在 `source` 时求值，不是模板占位符。

8. **版本管理自动化**：`release-please` 通过 `x-release-please-version` 标记自动更新 `configs/platform-independent/common.env` 中的 `VERSION` 并维护 `CHANGELOG.md`。

9. **OS 特定条件判断至关重要**：Ubuntu 24.04 使用 DEB822 apt 格式。Ubuntu 20.04 需要 `libncurses5-dev` 而非 `libncurses-dev`。`bsdextrautils` 在 20.04 上不可用。24.04 上 UID 1000 已被占用。任何涉及包的代码都必须检查 OS_VERSION。

10. **`docker/libs/` 已删除**：该目录包含已废弃的代码（旧版 `setup_base.sh`、sed 模板处理器、未使用的 `.df` Dockerfile 模块）。所有功能现在位于 `docker/dev-env-clientside/` 下各 stage 专属脚本中。

---

## 7. 开发命令

```bash
# 构建平台镜像（交互式选择）
./harbor

# 在客户端 Ubuntu 宿主机上启动开发容器
./project_handover/clientside/ubuntu/ubuntu_only_entrance.sh start

# 容器生命周期：stop / restart / recreate / remove
./project_handover/clientside/ubuntu/ubuntu_only_entrance.sh <command>

# 创建新平台（交互式向导）
./scripts/create_platform.sh

# 创建新平台（非交互式，适合 AI/CI）
./scripts/create_platform.sh --non-interactive \
    --name rk3566-debian12 --os debian --os-version 12 \
    --harbor-ip 192.168.3.68 --port-slot 6

# 调试模式（详细输出）
V=1 ./harbor

# 验证平台配置 Schema
# （使用 platform_schema.json 配合任意 JSON Schema 验证器）
```

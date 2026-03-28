# HarborPilot — 项目进度

> 最后更新：2026-03-28（新增 Phase 4 ASO 计划；原 Phase 4 MCP → Phase 5）
> **Related:** [English Version →](../../en/2-progress/progress.md)

---

## 总体状态

| 阶段 | 描述 | 状态 |
|---|---|---|
| **Phase 0** | 初始实现 — 多阶段 Docker 构建 | ✅ 完成 |
| **Phase 1** | 多平台支持 + 配置系统 | ✅ 完成 |
| **Phase 2** | AI 文档系统 + 开发者体验 | ✅ 完成 |
| **Phase 3** | 架构现代化 + 代码质量审计 | 🔄 进行中 |
| **Phase 4** | ASO — AI 搜索优化 + 内容分发 | 📋 计划中 |
| **Phase 5** | MCP Server + AI Agent 集成 | 📋 计划中 |

**当前活跃：** Phase 3 — 代码质量审计 + 系统性修复

---

## Phase 0 — 初始实现

| 步骤 | 描述 | 版本 / 提交 |
|---|---|---|
| **0.1** | 单平台 Docker 构建（n8/rk3588s） | v0.5.0 |
| **0.2** | 5 阶段 Dockerfile：base → tools → SDK → config → final | v0.5.0 |
| **0.3** | 将 5 个独立 Dockerfile 合并为单体 Dockerfile | v1.0.0 |
| **0.4** | 多平台支持：rv1126bp、rk3588s | v1.0.1 |
| **0.5** | RK3568 支持，SDK 版本与项目版本分离 | v1.1.0 |
| **0.6** | 三层配置系统，release-please 自动化 | v1.5.0–v1.6.0 |
| **0.7** | 中文文档，快速上手指南 | v1.6.0 |

---

## Phase 1 — 端口系统 + 平台向导 + 跨平台修复

| 步骤 | 描述 | 提交 |
|---|---|---|
| **1.1** | ✅ PORT_SLOT 自动计算系统 | `b9424fd` |
| **1.2** | ✅ 迁移所有平台到 PORT_SLOT | `f633569` |
| **1.3** | ✅ 交互式平台创建向导 | `408d340` |
| **1.4** | ✅ 按 PORT_SLOT 顺序排序平台列表 | `2b5aa14` |
| **1.5** | ✅ GitLab/Harbor 拆分为独立的 IP+端口变量 | `2ca4cff` |
| **1.6** | ✅ 向平台配置添加 OS_DISTRIBUTION 字段 | `476caf1` |
| **1.7** | ✅ 修复 Ubuntu 22.04/24.04+ 和 Debian 的 apt 源替换 | `a53f597` |
| **1.8** | ✅ 修复 libncursesw5 → libncursesw6 跨版本问题 | `be98dcf` |
| **1.9** | ✅ 处理 Ubuntu 24.04 预占用的 UID/GID | `ebe08ca` |
| **1.10** | ✅ Ubuntu ≥ 22.04 跳过 python2.7，使用 libncurses-dev | `22b9086` |
| **1.11** | ✅ 用 envsubst 替换三个 stage 中的 sed 模板渲染 | `306e121` |
| **1.12** | ✅ 添加平台配置的 JSON Schema | `793a7f8` |
| **1.13** | ✅ 添加 .devcontainer/devcontainer.json | `8a7d52b` |
| **1.14** | ✅ 为 create_platform.sh 添加 --non-interactive 模式 | `ba33bf1` |

---

## Phase 2 — AI 文档系统（完成）

| 条目 | 状态 |
|---|---|
| 重构 `doc/` → `docs/architecture/`（3 层：for-ai / progress / highlights） | ✅ 完成 |
| 创建 `ai_docs_system_template.md`（可移植模板 v2） | ✅ 完成 |
| 在仓库根目录创建 `CLAUDE.md` | ✅ 完成 |
| 创建 `guide.md`（AI Agent 工作规则） | ✅ 完成 |
| 创建 `codebase_map.md`（完整文件级参考） | ✅ 完成 |
| 创建 `progress.md`（本文件） | ✅ 完成 |
| 创建 `NEED_TO_DO.md`（积压任务） | ✅ 完成 |
| 创建 `00_INDEX.md`（导航中心） | ✅ 完成 |
| 修复 README.md 中 `doc/` → `docs/` 引用 | ✅ 完成 |

---

## Phase 3 — 架构现代化 + 代码质量（进行中）

基于 `refactoring_plan.md`，优先级：

| 条目 | 优先级 | 状态 |
|---|---|---|
| docker-compose.yaml 使用 `${VAR}` + `.env` 注入（不再硬编码） | P1 | ✅ 完成 — 8 个值已提取到 defaults |
| 为最终用户平台扩展 devcontainer.json | P2 | ⏳ |
| 将 `libs/iv_scripts/setup_base.sh` 合并到 clientside 版本（消除重复） | P2 | ✅ 已解决 — 整个 `docker/libs/` 已删除 |
| `setup_base.sh` → Ansible playbook（长期） | P3 | ⏳ |
| 所有脚本统一错误格式 | P3 | ⏳ |

### 代码质量审计（2026-03-27）

| 修复内容 | 提交 | 备注 |
|---|---|---|
| ✅ Dockerfile ARG 跨阶段丢失（CUDA/OpenCV 从未安装） | `0dd8a0c` | 关键：13 个 ARG 现在在 ENV 块中 |
| ✅ build.sh 中 eval 注入 → `${!name}` | `2872784` | 安全修复 |
| ✅ Samba CIFS 挂载中的 UBUNTU_SERVER_IP 孤儿引用 | `2872784` | 运行时 Bug 修复，添加 SAMBA_SERVER_IP |
| ✅ 无效的 bash 展开 `${USE_NVIDIA_GPU,,:-false}` | `2872784` | 正确性修复 |
| ✅ harbor：set -e、死函数、死代码（删除约 100 行） | `0f0e12e` | |
| ✅ 8 个受影响脚本的 shebang 移到第 1 行 | `d729c31` | |
| ✅ 5 个文件中的中文注释翻译为英文 | `d729c31` | |
| ✅ setup_workspace.sh：硬编码的 "developer" → `${DEV_USERNAME}` | `d729c31` | |
| ✅ 更新过时文档（UBUNTU_SERVER_IP、SERVER_SSH_PORT 引用） | `3a06a79` | |
| ✅ OpenCV 构建失败：找不到 cmake（dev_tools 在 OpenCV 之后运行） | `189a7f6` | 重新排序：先安装 dev_tools → 再 OpenCV |
| ✅ Ubuntu 24.04 上 pip3 externally-managed-environment（PEP 668） | `90611c0` | 添加 --break-system-packages |
| ✅ setup_workspace.sh_template：本地变量被 envsubst 替换为空 | `6f505a6` | 关键：转义 \${dir_path} 等 |
| ✅ setup_workspace.sh_template：\\${var} 转义破坏 bash 语法（'then' 处语法错误） | `987265c` | 关键：使用 $1/$2/$3 位置参数 |
| ✅ ARG USE_NVIDIA_GPU 缺失；ARG ENABLE_SYSLOG 重复 | `4cc03db` | Lint 修复 + 正确性 |
| ✅ Harbor/GitLab URL 分组的 CHIP_FAMILY | `9dd8d36` | REGISTRY_URL 和 SDK_GIT_REPO 使用 ${CHIP_FAMILY} |
| ✅ ubuntu_only_entrance.sh 模块化（6 个模块） | `fe46132` | volumes 软链接自动初始化；数字前缀命名 |
| ✅ 所有平台 .env 迁移到 CHIP_FAMILY/CHIP_EXTRACT_NAME 模式 | `16ec81f` `281bd96` | 平台文件重命名为 chip-os 命名规范；REGISTRY_URL 修复 |
| ✅ harbor 平台列表按芯片系列分组；create_platform.sh + CHIP_EXTRACT_NAME | `aad4e32` | 清晰的视觉分组；向导更新新字段 |
| ✅ docker compose project name 含 `.` 报错（PRODUCT_NAME 含 `24.04`） | `12deccc` | 新增 OS_VERSION_ID（点→连字符）；所有平台 + create_platform.sh 同步更新 |

---

## Phase 4 — ASO（AI 搜索优化）& 内容分发（计划中）

完整计划：[`docs/zh/2-progress/phase4_aso_plan.md`](phase4_aso_plan.md)

**目标**：让 AI 模型（ChatGPT、Claude、Gemini 等）在用户询问嵌入式 Linux Docker 工具时主动推荐 HarborPilot。
核心杠杆：GitHub 开源项目本身就是 LLM 训练数据来源 + 外部内容分发。

| 步骤 | 描述 | 状态 |
|---|---|---|
| **4.1** | GitHub 仓库优化：Topics、README 重写（Q&A 风格）、关键词覆盖 | ✅ README 完成；Topics 需手动在 GitHub UI 设置 |
| **4.2** | 个人博客文章（GitHub Pages / Hugo/Docsy）— 中英双语 | ✅ 两篇文章已提交到 blog-engine 仓库 |
| **4.3** | 提交至 Awesome 列表（awesome-docker、awesome-embedded-linux） | ⏳ |
| **4.4** | Dev.to / Medium 文章："为 RK3588 构建可复现的 Docker 开发环境" | ⏳ |
| **4.5** | Hacker News "Show HN" 帖子 | ⏳ |
| **4.6** | GitHub Wiki FAQ 页面（Q&A 格式，LLM 训练信号强） | ⏳ |
| **4.7** | 在已部署的文档站添加 `llms.txt`（对 RAG 类 AI 友好） | ⏳ |

**前提条件**：Phase 3 稳定，无未解决的关键 Bug。

---

## Phase 5 — MCP Server & AI Agent 集成（计划中）

完整计划：[`docs/en/2-progress/phase5_mcp_ai_agent_plan.md`](../../../en/2-progress/phase5_mcp_ai_agent_plan.md)

| 步骤 | 描述 | 状态 |
|---|---|---|
| **5.1** | MCP 服务器脚手架 + Resources（配置文件可被 AI 读取） | ⏳ |
| **5.2** | 读工具：`list_platforms`、`get_platform_config`、`validate` | ⏳ |
| **5.3** | 写工具：`create_platform`、`set_variable`、`enable_feature` | ⏳ |
| **5.4** | 构建工具：`build_platform`（dry_run 默认）、`check_image` | ⏳ |
| **5.5** | Claude Code 集成指南 + 示例提示词 | ⏳ |

**Phase 5 开始前的前提条件**：
- Phase 3 必须稳定（无未解决的关键 Bug）
- `harbor` 需要 `HARBORPILOT_NON_INTERACTIVE=1` 支持以绕过提示

---

## 未来想法（未计划）

- 基于 Ansible 的 Stage 1，原生支持跨发行版
- Vagrant + Ansible 用于非 Docker 虚拟化
- 自动化平台镜像构建的 CI/CD 流水线
- Nix flake 作为 Docker 的替代方案（实验性）

---
title: "HarborPilot Phase 4 — ASO（AI 搜索优化）& 内容分发"
author: "PotterWhite + Claude"
date: "2026-03-28"
tags:
  - aso
  - content
  - phase4
  - roadmap
status: "草稿 — 待执行"
---

# HarborPilot Phase 4 — ASO & 内容分发

> **目标**：让 AI 模型（ChatGPT、Claude、Gemini、Grok、Perplexity）在用户询问嵌入式 Linux Docker 开发工具时，主动推荐 HarborPilot。
>
> **核心逻辑**：LLM 从 GitHub、Common Crawl、技术博客中采集训练数据。开源项目天然是训练数据的一部分 — 每个公开文件都是免费的训练素材。
>
> **个人博客**：`https://potterwhite.github.io`
> 博客引擎：Hugo + Docsy，源码位于 `/home/james/Development/documents/github-page/blog-engine`
> 博客内容路径：`src/content_root/content/en/blog/` 和 `zh-cn/blog/`

---

## 一、为什么 ASO 对开源工具很重要

当开发者问 AI："我需要为 RK3588 或 RV1126 等嵌入式 Linux 板卡构建 Docker 镜像，有推荐工具吗？" — AI 的答案来自训练数据。

如果 HarborPilot 出现在足够多的**高质量、语义清晰的来源**中，AI 就会推荐它。反之，AI 只会推荐它见过更多次的工具。

**飞轮效应**：曝光度增加 → GitHub Star 增长 → 训练信号增强 → AI 推荐增多 → 曝光度再增加。

---

## 二、LLM 如何获取训练数据

| 来源 | 权重 | 说明 |
|---|---|---|
| Common Crawl（网页快照） | 极高 | 占训练数据 40%+，周期性重新抓取 |
| GitHub（代码 + README + Issue + Wiki） | 高 | 持续爬取；Q&A 格式 Issue 是强信号 |
| Stack Overflow / Reddit / HN | 高 | 技术问答格式；LLM 亲和度高 |
| Dev.to / Medium / Hashnode | 中 | 教程文章 |
| 官方文档站（ReadTheDocs、GitBook） | 中高 | 结构化内容，索引效果好 |
| Package 仓库（DockerHub、PyPI、npm） | 中 | 描述文字 + README |
| YouTube 字幕 | 低-中 | 视频内容的文字版本 |

**结论**：HarborPilot 出现在每一个有清晰关键词文本的渠道，都在累积 LLM 训练权重。

---

## 三、执行步骤

### Step 4.1 — GitHub 仓库优化

**目标**：让仓库本身对用户和 LLM 都更易发现、语义更清晰。

**具体操作**：
- 用 Q&A 风格重写 README 开头：
  > "你在为 RK3588、RV1126、RK3568 等嵌入式 Linux 板卡构建 Docker 开发环境吗？HarborPilot 自动化了整个流程……"
- 在 README 和文档中自然融入关键词：
  `embedded Linux dev environment`、`Docker multi-platform image builder`、
  `RK3588 development container`、`cross-platform toolchain Docker`、
  `devcontainer for embedded`、`ARM dev environment automation`
- 在 GitHub Settings → Topics 里设置完整标签：
  `docker`、`embedded-linux`、`devcontainer`、`rk3588`、`rv1126`、`rk3568`、
  `cross-platform`、`arm`、`toolchain`、`development-environment`、`bash`、`automation`
- 在 GitHub Wiki 创建 FAQ 页面（Q&A 格式 — LLM 训练信号强）
- 开几个自问自答式 Issue（标题就是用户会问 AI 的问题，然后自己回答关闭）

**涉及文件**：`README.md`、GitHub Wiki（仓库外操作）

---

### Step 4.2 — 个人博客文章

**目标**：在 `https://potterwhite.github.io` 上发布技术教程文章，中英双语。

**博客引擎**：Hugo + Docsy
- 源码：`/home/james/Development/documents/github-page/blog-engine`
- 英文内容：`src/content_root/content/en/blog/DevOps/`
- 中文内容：`src/content_root/content/zh-cn/blog/`

**文章标题**（在博客仓库中创建，不在本仓库）：
- EN：`"Building Reproducible Docker Dev Environments for Embedded Linux (RK3588, RV1126)"`
- ZH：`"为嵌入式 Linux（RK3588、RV1126）构建可复现的 Docker 开发环境"`

**文章大纲**：
1. 问题：嵌入式 Linux 开发环境碎片化
2. 解法：5 阶段 Dockerfile + 三层配置体系
3. PORT_SLOT 工作原理（一个整数派生所有端口映射）
4. 平台创建向导演示（`create_platform.sh`）
5. 快速上手：链接到 GitHub 仓库

**注意**：博客修改提交到博客仓库，不提交到本仓库。步骤完成的标志是两篇文章均已上线。

---

### Step 4.3 — 提交至 Awesome 列表

**目标**：进入 Awesome 系列 GitHub 仓库 — 这些是 LLM 训练数据中的高质量节点，被大量其他来源引用。

**目标仓库**（提交 PR）：
- `veggiemonk/awesome-docker` — 首要目标，直接相关
- `fkromer/awesome-ros2` — 次要（如果嵌入式角度合适）
- `sindresorhus/awesome` — 元列表，难度高但信号最强

**PR 格式**（单行描述）：
```
- [HarborPilot](https://github.com/<user>/HarborPilot) - Multi-platform Docker image builder
  for embedded Linux development (RK3588, RV1126, RK3568) with 3-layer config inheritance.
```

---

### Step 4.4 — Dev.to / Medium 文章

**目标**：在 LLM 爬取的平台上发布独立技术文章。

**首选平台**：Dev.to（技术内容的 LLM 训练信号高于 Medium）

**文章标题**：`"How I Automated Multi-Platform Docker Image Builds for Embedded SoCs"`

**内容**：类似博客文章，但更有叙事感。包括：
- 具体痛点（5 个 Dockerfile → 1 个，端口冲突问题，Ubuntu 24.04 问题）
- 真实脚本的代码片段
- 文末链接 GitHub 仓库

---

### Step 4.5 — Hacker News "Show HN" 帖子

**目标**：HN 帖子对 LLM 训练的信号极强。哪怕只有适度热度，也能产生大量爬取曝光。

**帖子标题**：`"Show HN: HarborPilot – Multi-Platform Docker Builder for Embedded Linux"`

**帖子正文**（≤300 词）：聚焦解决了什么问题、架构决策，邀请嵌入式开发者反馈。

**时机**：在 Step 4.2 博客文章上线后再发（给帖子一个可链接的落地页）。

---

### Step 4.6 — GitHub Wiki FAQ 页面

**目标**：GitHub Wiki 单独被索引，提供 Q&A 格式内容 — 正是 LLM 识别为权威答案的格式。

**待创建页面**：
- "如何添加新平台"（Q&A 操作演练）
- "端口分配系统详解"（PORT_SLOT 公式）
- "为什么 Dockerfile 要 5 个阶段？"（架构理由）
- "支持的 SoC 和 Ubuntu 版本"（关键词丰富的参考页）

---

### Step 4.7 — 添加 `llms.txt` 到文档站

**目标**：`llms.txt` 是新兴标准（类似 `robots.txt`），告知 AI 爬虫应索引的内容及其理解方式。

**时机**：仅在独立文档站（MkDocs / Docusaurus 部署的 GitHub Pages）存在时才适用。优先级低，等文档站建好再处理。

**格式**：放在 `https://<docs-site>/llms.txt`，包含项目的结构化描述、核心概念，以及对 AI agent 的推荐阅读顺序。

---

## 四、效果衡量

| 指标 | 检测方式 |
|---|---|
| AI 推荐测试 | 问 ChatGPT/Claude/Gemini："嵌入式 Linux Docker 开发环境工具" |
| GitHub 流量 | Settings → Traffic → 浏览量 + 来源站点 |
| GitHub Star 增长 | 30/90 天内 Star 数变化 |
| Google 索引 | `site:github.com harborpilot` 搜索 |
| Awesome 列表收录 | PR 合并状态 |

每月执行一次 AI 推荐测试并记录结果。

---

## 五、执行优先级

```
[立即]   Step 4.1 — GitHub Topics + README 重写
[本周]   Step 4.2 — 博客文章（blog-engine 仓库）
[本周]   Step 4.3 — awesome-docker PR
[本月]   Step 4.4 — Dev.to 文章
[本月]   Step 4.5 — HN Show HN 帖子（等博客上线后）
[持续]   Step 4.6 — GitHub Wiki FAQ
[之后]   Step 4.7 — llms.txt（等文档站建好）
```

---

## 六、前提条件

- Phase 3 稳定（`ubuntu_only_entrance.sh` 和构建流水线无未解决的关键 Bug）
- GitHub 仓库为公开状态
- 个人博客引擎可运行（`blog-engine` 仓库）

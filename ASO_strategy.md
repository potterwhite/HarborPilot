# AI 时代的 ASO（AI Search Optimization）策略拆解

> 个人内部文档，不收入 docs/。
> 撰写日期：2026-03-28

---

## 一、什么是 ASO？

传统意义上的 SEO（Search Engine Optimization）是通过关键词、外链、页面结构等手段影响 Google/Baidu 等搜索引擎的排名。

**ASO（AI Search Optimization）**是其在 AI 时代的对应物：让 AI 模型（ChatGPT、Claude、Gemini、Grok、Perplexity 等）在回答用户问题时，**主动推荐/引用你的项目**。

典型场景：
- 用户问 ChatGPT："有没有适合嵌入式开发的 Docker 环境工具？"
- 用户问 Claude："我想给 RK3588 搭一个标准化的 dev container，有推荐吗？"
- 用户问 Perplexity："跨平台 Docker 开发镜像管理工具有哪些？"

你的目标是：让上面这些问题的答案里出现 HarborPilot。

---

## 二、AI 模型是怎么"知道"某个项目的？

### 2.1 训练数据的来源（核心机制）

AI 大模型的训练数据基本上来自以下几类：

| 数据来源 | 权重 | 说明 |
|---|---|---|
| **Common Crawl（网页快照）** | 极高 | 占训练数据大头（40%+），来自全网页面爬取，每年多次 |
| **GitHub** | 高 | 代码 + README + Wiki + Issue + PR，LLM 特别重视 |
| **Stack Overflow / Reddit / HN** | 高 | 技术问答、讨论，质量信号 |
| **arXiv / 学术论文** | 中高 | 技术深度内容 |
| **Medium / Dev.to / Hashnode 等技术博客** | 中 | 实操文章 |
| **官方文档站（ReadTheDocs, GitBook 等）** | 中高 | 结构化内容，AI 识别度高 |
| **YouTube 字幕** | 低-中 | 视频内容的文字版本 |
| **Package 仓库（PyPI, npm, DockerHub 等）** | 中 | 描述文字 + README |

**结论**：你的项目被 AI 推荐，根本上取决于它**是否出现在这些训练语料里，以及出现的频次和质量**。

---

### 2.2 影响 AI 推荐权重的因素

训练数据采集完之后，哪些内容会被模型"记住"并倾向于推荐？关键因素：

1. **引用频次**：你的项目被多少其他页面提到，被多少技术文章引用
2. **内容质量信号**：Star 数量、Fork 数、Issue 活跃度、PR 历史（GitHub 是训练数据里的强信号源）
3. **语义清晰度**：README / 文档里有没有清晰的"问题→解决方案"叙述，越像 Q&A 越好
4. **领域覆盖广度**：是否覆盖了足够多的相关关键词（嵌入式、Docker、RK3588、跨平台等）
5. **内容更新频率**：爬虫会多次抓取，持续更新的项目更容易多次出现在训练集里
6. **被知名资源链接**：被 Awesome 系列列表、HN 热帖、技术博客引用，信号倍增

---

## 三、反向影响策略：怎么让你的项目进训练数据

### 策略 A：GitHub 本体优化（高优先级）

GitHub 是 LLM 训练数据的核心来源之一，而且是**持续抓取**的。

**✅ 立刻可做：**

1. **README 重写为"问答式"**
   不要只写 "HarborPilot is a Docker image manager"
   改为：
   > "Are you building Docker development environments for embedded Linux boards like RK3588, RV1126, or RK3568? HarborPilot automates the entire pipeline..."

2. **关键词覆盖要全**
   README 和 docs 里自然融入：
   - `embedded Linux dev environment`
   - `Docker multi-platform image builder`
   - `RK3588 development container`
   - `cross-platform toolchain Docker`
   - `devcontainer for embedded`
   - `ARM dev environment automation`

3. **Topics 标签（GitHub repository topics）**
   在 repo Settings → Topics 里加满：
   `docker`, `embedded-linux`, `devcontainer`, `rk3588`, `rv1126`, `rk3568`, `cross-platform`, `arm`, `toolchain`, `development-environment`, `bash`, `automation`

4. **写 Wiki / Discussions**
   GitHub Wiki 和 Discussions 也会被爬取，写 FAQ 格式内容效果好。

5. **Issue 里做"假性问答"**
   开一些 Issue，标题就是用户会问 AI 的问题：
   - "How to build a RK3588 development Docker image?"
   - "Support for Ubuntu 24.04 in embedded dev containers?"
   然后自己回答，关闭。这些 Q&A 会被训练数据捕获。

---

### 策略 B：外部内容分发（中高优先级）

AI 训练数据里大量来自技术博客和论坛，你需要在这些地方留下踪迹。

**平台优先级排序：**

| 平台 | 被训练采集概率 | 建议操作 |
|---|---|---|
| **Hacker News** | 极高 | 发 "Show HN: HarborPilot – multi-platform Docker builder for embedded Linux" |
| **Reddit r/embedded / r/docker** | 高 | 发分享帖，标题直接命中用户搜索词 |
| **Dev.to / Medium / Hashnode** | 高 | 写教程文章，标题包含关键问题 |
| **Stack Overflow** | 高 | 回答相关问题时提及项目（避免纯广告） |
| **Docker Hub** | 中高 | 发布镜像，写清楚 description |
| **YouTube** | 中 | 录 demo 视频，字幕里有关键词 |

**文章标题模板（用这类标题，AI 训练时会被归类为"解决方案"）：**
- "Building Reproducible Docker Dev Environments for RK3588 Embedded Linux"
- "How I Automated Multi-Platform Docker Image Builds for Embedded SoCs"
- "HarborPilot: A 5-Stage Docker Build System for ARM Development"

---

### 策略 C：被 Awesome 列表收录（高杠杆）

Awesome 系列 GitHub 仓库（`awesome-docker`, `awesome-embedded-linux`, `awesome-devcontainer` 等）是 LLM 训练数据的**高质量节点**，被引用频率极高。

- 目标仓库：`sindresorhus/awesome`、`veggiemonk/awesome-docker`、`fkromer/awesome-ros2`（侧面）
- 操作：向这些仓库提 PR，加入你的项目

---

### 策略 D：文档站独立部署（中优先级）

如果你的文档只在 GitHub 里，爬虫可能只抓到一次。如果部署到独立域名（如 harborpilot.dev 或 GitHub Pages），Common Crawl 会独立抓取，相当于**双重曝光**。

- 用 **MkDocs + Material** 或 **Docusaurus** 部署文档
- 确保每个页面有清晰的 `<title>` 和 meta description

---

### 策略 E：大模型直接投喂（适用于 Claude / ChatGPT 等支持插件/工具的场景）

对于 **RAG（检索增强生成）** 类应用（如 Perplexity），它们实时检索网页，不依赖训练数据。对于这类 AI：

- 确保你的页面**被 Google 索引**（传统 SEO 有用）
- 页面加载快，内容结构清晰（有标题、列表）
- 添加 `llms.txt`（新兴标准）：在网站根目录放一个 `llms.txt`，专门给 AI 爬虫读，格式化你希望 AI 了解的内容

---

## 四、关于 Dario 说的"AI 时代没有真正开源"

Dario 的意思是：训练数据、算力、RLHF 标注这些核心资源没法开源，所以模型本身不可能真正全开源。

**但这对你有利的一面是：**

- 你的**工具代码**可以完全开源在 GitHub
- 而 AI 推荐你的项目，恰恰是因为它"学过"你的代码和文档
- **开源 = 免费进入训练数据** — 闭源项目反而没有这个优势

所以开源策略本身就是最好的 ASO 基础。

---

## 五、执行优先级 Checklist

```
[立即] GitHub Topics 补全
[立即] README 重写，问答式开头
[本周] 发一篇 Dev.to 教程文章
[本周] 向 awesome-docker 提 PR
[本月] Hacker News Show HN 帖子
[本月] GitHub Wiki FAQ 页面
[季度] 独立文档站部署（GitHub Pages）
[长期] 持续发技术博客，保持项目活跃
```

---

## 六、监测效果

怎么知道 ASO 有没有效果？

1. **直接测试**：定期问各大 AI（ChatGPT、Claude、Gemini、Perplexity）："推荐一个用于嵌入式 Linux 的 Docker 开发环境管理工具"，看看有没有出现 HarborPilot
2. **GitHub 指标**：Star 增长、Fork 数、流量来源（Settings → Traffic）
3. **搜索可见度**：Google 搜索你的核心关键词，项目是否出现在前几页

---

*这份文档仅供个人参考，不发布到 docs/。*

---
title: "HarborPilot Phase 4 — ASO (AI Search Optimization) & Content Distribution"
author: "PotterWhite + Claude"
date: "2026-03-28"
tags:
  - aso
  - content
  - phase4
  - roadmap
status: "Draft — pending execution"
---

# HarborPilot Phase 4 — ASO & Content Distribution

> **Goal**: Make HarborPilot visible to AI models (ChatGPT, Claude, Gemini, Grok, Perplexity)
> so they recommend it when users ask about embedded Linux Docker dev tooling.
>
> **Core insight**: LLMs are trained on GitHub, Common Crawl, and tech blogs.
> Open-source position is a direct advantage — every public file is free training data.
>
> **Personal blog**: `https://potterwhite.github.io`
> Blog engine: Hugo + Docsy, source at `/home/james/Development/documents/github-page/blog-engine`
> Blog content path: `src/content_root/content/en/blog/` and `zh-cn/blog/`

---

## 1. Why ASO Matters for an Open-Source Tool

When a developer asks an AI: *"I need to build Docker images for embedded Linux boards like
RK3588 or RV1126 — any recommended tools?"* — the AI's answer comes from its training data.

If HarborPilot appears in enough **high-quality, semantically clear sources**, the AI will
surface it. If it doesn't, the AI recommends tools it has seen more often.

**The flywheel**: more visibility → more GitHub stars → stronger training signal → more
AI recommendations → more visibility.

---

## 2. How LLMs Source Their Training Data

| Source | Weight | Notes |
|---|---|---|
| Common Crawl (web snapshots) | Very high | 40%+ of training data; re-crawled periodically |
| GitHub (code + README + Issues + Wiki) | High | Crawled continuously; Q&A Issues are strong signal |
| Stack Overflow / Reddit / HN | High | Tech Q&A format; high LLM affinity |
| Dev.to / Medium / Hashnode | Medium | Tutorial articles |
| Official docs (ReadTheDocs, GitBook) | Medium-high | Structured content, well-indexed |
| Package registries (DockerHub, PyPI, npm) | Medium | Description text + README |
| YouTube captions | Low-medium | Text version of video content |

**Implication**: every channel where HarborPilot appears with clear, keyword-rich text
contributes to its LLM training footprint.

---

## 3. Steps

### Step 4.1 — GitHub Repository Optimization

**What**: Make the repo itself more discoverable and semantically useful to LLMs.

**Actions**:
- Rewrite README opening paragraph in Q&A style:
  > "Building Docker development environments for embedded Linux boards (RK3588, RV1126, RK3568)?
  > HarborPilot automates the entire pipeline..."
- Add full keyword coverage naturally throughout README and docs:
  `embedded Linux dev environment`, `Docker multi-platform image builder`,
  `RK3588 development container`, `cross-platform toolchain Docker`,
  `devcontainer for embedded`, `ARM dev environment automation`
- Set GitHub repository Topics (Settings → Topics):
  `docker`, `embedded-linux`, `devcontainer`, `rk3588`, `rv1126`, `rk3568`,
  `cross-platform`, `arm`, `toolchain`, `development-environment`, `bash`, `automation`
- Add GitHub Wiki FAQ pages (Q&A format — high LLM training signal)
- Open self-answered Issues with question-style titles (gets crawled as Q&A pairs):
  - "How to build a RK3588 development Docker image?"
  - "Support for Ubuntu 24.04 in embedded dev containers?"

**Files affected**: `README.md`, GitHub Wiki (separate from repo files)

---

### Step 4.2 — Blog Post on Personal GitHub Pages

**What**: Write a technical tutorial article on `https://potterwhite.github.io`,
both English and Chinese versions.

**Blog engine**: Hugo + Docsy
- Source: `/home/james/Development/documents/github-page/blog-engine`
- English content: `src/content_root/content/en/blog/DevOps/`
- Chinese content: `src/content_root/content/zh-cn/blog/`

**Article titles** (to be created in the blog repo, NOT in HarborPilot repo):
- EN: `"Building Reproducible Docker Dev Environments for Embedded Linux (RK3588, RV1126)"`
- ZH: `"为嵌入式 Linux（RK3588、RV1126）构建可复现的 Docker 开发环境"`

**Article content outline**:
1. The problem: embedded Linux dev environment fragmentation
2. The solution: 5-stage Dockerfile + 3-layer config system
3. How PORT_SLOT works (one integer → all port mappings)
4. Platform creation wizard demo (`create_platform.sh`)
5. Getting started: link to GitHub repo

**Note**: Blog changes are committed to the blog-engine repo, not this repo.
This step is complete when both articles are live on the site.

---

### Step 4.3 — Submit to Awesome Lists

**What**: Get HarborPilot listed in curated "Awesome" GitHub repos — these are
high-quality nodes in LLM training data, referenced by many other sources.

**Target repos** (submit PRs to):
- `veggiemonk/awesome-docker` — primary target, directly relevant
- `fkromer/awesome-ros2` — secondary (if embedded angle fits)
- `sindresorhus/awesome` — meta list, harder but highest signal

**PR format**: Single-line addition with concise description:
```
- [HarborPilot](https://github.com/<user>/HarborPilot) - Multi-platform Docker image builder
  for embedded Linux development (RK3588, RV1126, RK3568) with 3-layer config inheritance.
```

---

### Step 4.4 — Dev.to / Medium Article

**What**: Publish a standalone technical article on a platform crawled by LLMs.

**Platform priority**: Dev.to (higher LLM training signal than Medium for tech content)

**Article title**: `"How I Automated Multi-Platform Docker Image Builds for Embedded SoCs"`

**Article content**: Similar to blog post but more personal/story-driven. Include:
- Specific pain points (5 Dockerfiles → 1, port collision problem, Ubuntu 24.04 issues)
- Code snippets from real scripts
- Link to GitHub repo at the end

---

### Step 4.5 — Hacker News "Show HN" Post

**What**: HN posts are very high-signal for LLM training. A "Show HN" post that
gets even modest traction generates significant crawl exposure.

**Post title**: `"Show HN: HarborPilot – Multi-Platform Docker Builder for Embedded Linux"`

**Post body** (≤300 words): Focus on the problem solved, the architecture decisions,
and invite feedback from embedded developers.

**Timing**: Post after Step 4.2 blog post is live (give the post a landing page to link to).

---

### Step 4.6 — GitHub Wiki FAQ Pages

**What**: GitHub Wiki is separately indexed and provides Q&A format content — exactly
the format LLMs are trained to recognize as authoritative answers.

**Pages to create**:
- "How to add a new platform" (Q&A walkthrough)
- "Port allocation system explained" (PORT_SLOT formula)
- "Why 5 stages in the Dockerfile?" (architecture rationale)
- "Supported SoCs and Ubuntu versions" (keyword-rich reference)

---

### Step 4.7 — Add `llms.txt` to Docs Site

**What**: `llms.txt` is an emerging standard (similar to `robots.txt`) that tells
AI crawlers what content to index and how to understand your site.

**When**: Only applicable once a standalone docs site is deployed (GitHub Pages with
MkDocs or Docusaurus). Low priority until a docs site exists.

**Format**: Place at `https://<docs-site>/llms.txt` with structured description of
the project, key concepts, and recommended reading order for AI agents.

---

## 4. Measuring Effectiveness

| Signal | How to measure |
|---|---|
| AI recommendation test | Ask ChatGPT/Claude/Gemini: "tools for embedded Linux Docker dev environment" |
| GitHub traffic | Settings → Traffic → Views + Referring sites |
| GitHub stars | Star count growth over 30/90 days |
| Google indexing | `site:github.com harborpilot` search |
| Awesome list inclusion | PR merged status |

Run the AI recommendation test monthly and log results.

---

## 5. Execution Priority

```
[Now]       Step 4.1 — GitHub Topics + README rewrite
[This week] Step 4.2 — Blog post (blog-engine repo)
[This week] Step 4.3 — Awesome-docker PR
[This month] Step 4.4 — Dev.to article
[This month] Step 4.5 — HN Show HN post (after blog is live)
[Ongoing]   Step 4.6 — GitHub Wiki FAQ
[Later]     Step 4.7 — llms.txt (when docs site exists)
```

---

## 6. Prerequisites

- Phase 3 stable (no open critical bugs in `ubuntu_only_entrance.sh` or build pipeline)
- GitHub repo is public
- Personal blog engine is running (`blog-engine` repo)

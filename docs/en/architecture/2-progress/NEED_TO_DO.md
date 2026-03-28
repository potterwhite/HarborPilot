- **改完就把下面的checkbox checked**

Mar28.2026 09:30
- [x] context limit，请继续之前的工作
    ```bash
                                                                                                                                09:21 AM claude-sonnet-4.6
    ● 现在处理 progress.md 的 emoji ✅ check icon。读完整的 EN 版 progress 文件：

    ● Read(/mnt/2tb_wd_purpleSurveillance_hdd/system-redirection/Development/docker/HarborPilot.git/docs/en/architecture/2-progress/progress.md)
    ⎿  Read 135 lines

    ∴ Thinking…

    The user wants to:
    1. Add ✅ emoji check icons to items in progress.md that have commit hashes
    2. The "this commit" entry for OS_VERSION_ID fix needs to be updated with the actual commit hash (12deccc)

    Let me analyze what needs emoji check icons:
    - Phase 0: All items have version numbers (v0.5.0, v1.0.0, etc.) but NO commit hashes → no check needed per user's instruction
    - Phase 1: All items have commit hashes → ALL should get ✅
    - Phase 2: All items already have ✅ Done status → they're already done

    - Phase 3 top priorities table: items with ✅ Done already have it, ⏳ items don't have commits → no change needed
    - Code Quality Audit table: all items have commit hashes → ALL should get ✅, but the "this commit" entry needs to be updated with the actual hash 12deccc

    Wait, re-reading the user's request more carefully: they want me to add check marks to items that have commit hashes. So the rule is straightforward — if there's a commit hash, add ✅.

    Now I'm looking at how each phase is structured. Phase 0 has version numbers rather than commit hashes, so those don't qualify. Phase 1 has commit hashes in every row, so those all need
    ✅. Phase 2 already has a Status column. Phase 3's top table is mixed — some entries have ✅ already, others don't. The Code Quality Audit section has commit hashes across the board.

    The question is where exactly to place the ✅. Looking at the column layouts, I could either prepend it to the Description or Fix column text, or add a dedicated Status column. Let me
    check what Phase 2 does since it already has this pattern. Looking at the Code Quality Audit table, every row has a commit hash, so they all need the checkmark added to their Fix
    descriptions. I also need to replace that "this commit" placeholder with the actual hash 12deccc. Since Phase 1 items all have commits too, I'll prepend ✅ to their descriptions as well.

                                                                                                                                                                09:22 AM claude-sonnet-4.6
    ● 现在给所有有 commit hash 的条目加 ✅，同时把 (this commit) 替换成实际 hash 12deccc：

    ● Update(/mnt/2tb_wd_purpleSurveillance_hdd/system-redirection/Development/docker/HarborPilot.git/docs/en/architecture/2-progress/progress.md)
    ⎿  Added 14 lines, removed 14 lines
        37
        38  | Step | Description | Commit |
        39  |---|---|---|
        40 -| **1.1** | PORT_SLOT auto-calculation system | `b9424fd` |
        41 -| **1.2** | Migrate all platforms to PORT_SLOT | `f633569` |
        42 -| **1.3** | Interactive platform creation wizard | `408d340` |
        43 -| **1.4** | Sort platform list by PORT_SLOT order | `2b5aa14` |
        44 -| **1.5** | Split GitLab/Harbor into separate IP+port vars | `2ca4cff` |
        45 -| **1.6** | Add OS_DISTRIBUTION field to platform config | `476caf1` |
        46 -| **1.7** | Fix apt source replacement for Ubuntu 22.04/24.04+ and Debian | `a53f597` |
        47 -| **1.8** | Fix libncursesw5 → libncursesw6 cross-version | `be98dcf` |
        48 -| **1.9** | Handle pre-existing UID/GID for Ubuntu 24.04 | `ebe08ca` |
        49 -| **1.10** | Skip python2.7 on Ubuntu ≥ 22.04, use libncurses-dev | `22b9086` |
        50 -| **1.11** | Replace sed template rendering with envsubst in all 3 stages | `306e121` |
        51 -| **1.12** | Add JSON Schema for platform configuration | `793a7f8` |
        52 -| **1.13** | Add .devcontainer/devcontainer.json | `8a7d52b` |
        53 -| **1.14** | Add --non-interactive mode to create_platform.sh | `ba33bf1` |
        40 +| **1.1** | ✅ PORT_SLOT auto-calculation system | `b9424fd` |
        41 +| **1.2** | ✅ Migrate all platforms to PORT_SLOT | `f633569` |
        42 +| **1.3** | ✅ Interactive platform creation wizard | `408d340` |
        43 +| **1.4** | ✅ Sort platform list by PORT_SLOT order | `2b5aa14` |
        44 +| **1.5** | ✅ Split GitLab/Harbor into separate IP+port vars | `2ca4cff` |
        45 +| **1.6** | ✅ Add OS_DISTRIBUTION field to platform config | `476caf1` |
        46 +| **1.7** | ✅ Fix apt source replacement for Ubuntu 22.04/24.04+ and Debian | `a53f597` |
        47 +| **1.8** | ✅ Fix libncursesw5 → libncursesw6 cross-version | `be98dcf` |
        48 +| **1.9** | ✅ Handle pre-existing UID/GID for Ubuntu 24.04 | `ebe08ca` |
        49 +| **1.10** | ✅ Skip python2.7 on Ubuntu ≥ 22.04, use libncurses-dev | `22b9086` |
        50 +| **1.11** | ✅ Replace sed template rendering with envsubst in all 3 stages | `306e121` |
        51 +| **1.12** | ✅ Add JSON Schema for platform configuration | `793a7f8` |
        52 +| **1.13** | ✅ Add .devcontainer/devcontainer.json | `8a7d52b` |
        53 +| **1.14** | ✅ Add --non-interactive mode to create_platform.sh | `ba33bf1` |
        54
        55  ---
        56
    ⎿  1 PostToolUse hook ran

    ● Update(/mnt/2tb_wd_purpleSurveillance_hdd/system-redirection/Development/docker/HarborPilot.git/docs/en/architecture/2-progress/progress.md)
    ⎿  Added 19 lines, removed 19 lines
        86
        87  | Fix | Commit | Notes |
        88  |---|---|---|
        89 -| Dockerfile ARG cross-stage loss (CUDA/OpenCV never installed) | `0dd8a0c` | CRITICAL: 13 ARGs now in ENV block |
        90 -| eval injection in build.sh → `${!name}` | `2872784` | Security fix |
        91 -| UBUNTU_SERVER_IP orphan reference in Samba CIFS mount | `2872784` | Runtime bug fix, add SAMBA_SERVER_IP |
        92 -| Invalid bash expansion `${USE_NVIDIA_GPU,,:-false}` | `2872784` | Correctness fix |
        93 -| harbor: set -e, dead functions, dead code (~100 lines removed) | `0f0e12e` | |
        94 -| Shebangs moved to line 1 in 8 affected scripts | `d729c31` | |
        95 -| Chinese comments translated to English in 5 files | `d729c31` | |
        96 -| setup_workspace.sh: hardcoded "developer" → `${DEV_USERNAME}` | `d729c31` | |
        97 -| Stale documentation updated (UBUNTU_SERVER_IP, SERVER_SSH_PORT refs) | `3a06a79` | |
        98 -| OpenCV build fails: cmake not found (dev_tools ran after OpenCV) | `189a7f6` | Reorder: install dev_tools → OpenCV |
        99 -| pip3 externally-managed-environment on Ubuntu 24.04 (PEP 668) | `90611c0` | Add --break-system-packages |
        100 -| setup_workspace.sh_template: local vars replaced by envsubst → empty | `6f505a6` | CRITICAL: escape \${dir_path} etc. |
        101 -| setup_workspace.sh_template: \\${var} escape broke bash syntax (syntax error at 'then') | `987265c` | CRITICAL: use $1/$2/$3 positional params |
        102 -| ARG USE_NVIDIA_GPU missing; duplicate ARG ENABLE_SYSLOG | `4cc03db` | Lint fix + correctness |
        103 -| CHIP_FAMILY for Harbor/GitLab URL grouping | `9dd8d36` | REGISTRY_URL and SDK_GIT_REPO use ${CHIP_FAMILY} |
        104 -| ubuntu_only_entrance.sh modularized (6 modules) | `fe46132` | Auto-init for volumes symlink; numbered prefix naming |
        105 -| All platform .env migrated to CHIP_FAMILY/CHIP_EXTRACT_NAME pattern | `16ec81f` `281bd96` | Platform files renamed to chip-os convention; REGISTRY_URL fixed |
        106 -| docker compose project name dot error (PRODUCT_NAME contained `24.04`) | `(this commit)` | Add `OS_VERSION_ID` (dots→dashes); PRODUCT_NAME now uses `OS_VERSION_ID`; all p
            -latforms + create_platform.sh updated |
        107 -| harbor: grouping + create_platform.sh CHIP_EXTRACT_NAME | `aad4e32` | Clean visual grouping; wizard updated with new field |
        89 +| ✅ Dockerfile ARG cross-stage loss (CUDA/OpenCV never installed) | `0dd8a0c` | CRITICAL: 13 ARGs now in ENV block |
        90 +| ✅ eval injection in build.sh → `${!name}` | `2872784` | Security fix |
        91 +| ✅ UBUNTU_SERVER_IP orphan reference in Samba CIFS mount | `2872784` | Runtime bug fix, add SAMBA_SERVER_IP |
        92 +| ✅ Invalid bash expansion `${USE_NVIDIA_GPU,,:-false}` | `2872784` | Correctness fix |
        93 +| ✅ harbor: set -e, dead functions, dead code (~100 lines removed) | `0f0e12e` | |
        94 +| ✅ Shebangs moved to line 1 in 8 affected scripts | `d729c31` | |
        95 +| ✅ Chinese comments translated to English in 5 files | `d729c31` | |
        96 +| ✅ setup_workspace.sh: hardcoded "developer" → `${DEV_USERNAME}` | `d729c31` | |
        97 +| ✅ Stale documentation updated (UBUNTU_SERVER_IP, SERVER_SSH_PORT refs) | `3a06a79` | |
        98 +| ✅ OpenCV build fails: cmake not found (dev_tools ran after OpenCV) | `189a7f6` | Reorder: install dev_tools → OpenCV |
        99 +| ✅ pip3 externally-managed-environment on Ubuntu 24.04 (PEP 668) | `90611c0` | Add --break-system-packages |
        100 +| ✅ setup_workspace.sh_template: local vars replaced by envsubst → empty | `6f505a6` | CRITICAL: escape \${dir_path} etc. |
        101 +| ✅ setup_workspace.sh_template: \\${var} escape broke bash syntax (syntax error at 'then') | `987265c` | CRITICAL: use $1/$2/$3 positional params |
        102 +| ✅ ARG USE_NVIDIA_GPU missing; duplicate ARG ENABLE_SYSLOG | `4cc03db` | Lint fix + correctness |
        103 +| ✅ CHIP_FAMILY for Harbor/GitLab URL grouping | `9dd8d36` | REGISTRY_URL and SDK_GIT_REPO use ${CHIP_FAMILY} |
        104 +| ✅ ubuntu_only_entrance.sh modularized (6 modules) | `fe46132` | Auto-init for volumes symlink; numbered prefix naming |
        105 +| ✅ All platform .env migrated to CHIP_FAMILY/CHIP_EXTRACT_NAME pattern | `16ec81f` `281bd96` | Platform files renamed to chip-os convention; REGISTRY_URL fixed |
        106 +| ✅ docker compose project name dot error (PRODUCT_NAME contained `24.04`) | `12deccc` | Add `OS_VERSION_ID` (dots→dashes); PRODUCT_NAME now uses `OS_VERSION_ID`; all plat
            +forms + create_platform.sh updated |
        107 +| ✅ harbor: grouping + create_platform.sh CHIP_EXTRACT_NAME | `aad4e32` | Clean visual grouping; wizard updated with new field |
        108
        109  ---
        110
    ⎿  1 PostToolUse hook ran

                                                                                                                                                                09:22 AM claude-sonnet-4.6
    ● Phase 0 的步骤有版本号但没有 commit hash，根据你的要求（有 commit hash 的就加，没有的不加）：Phase 0 不加（只有 version，没有 hash）。Phase 2 所有条目都已经有 ✅ Done 状态但没有
    hash，所以不加。Phase 3 的优先级表中两个 Done 条目没有专属 hash，但有 commit 有 notes，根据规则应跳过。

    现在更新 ZH 版 progress.md 做同样的修改：

    ● Read(/mnt/2tb_wd_purpleSurveillance_hdd/system-redirection/Development/docker/HarborPilot.git/docs/zh/architecture/2-progress/progress.md)
    ⎿  Read 134 lines

    ● Update(/mnt/2tb_wd_purpleSurveillance_hdd/system-redirection/Development/docker/HarborPilot.git/docs/zh/architecture/2-progress/progress.md)
    ⎿  Added 14 lines, removed 14 lines
        37
        38  | 步骤 | 描述 | 提交 |
        39  |---|---|---|
        40 -| **1.1** | PORT_SLOT 自动计算系统 | `b9424fd` |
        41 -| **1.2** | 迁移所有平台到 PORT_SLOT | `f633569` |
        42 -| **1.3** | 交互式平台创建向导 | `408d340` |
        43 -| **1.4** | 按 PORT_SLOT 顺序排序平台列表 | `2b5aa14` |
        44 -| **1.5** | GitLab/Harbor 拆分为独立的 IP+端口变量 | `2ca4cff` |
        45 -| **1.6** | 向平台配置添加 OS_DISTRIBUTION 字段 | `476caf1` |
        46 -| **1.7** | 修复 Ubuntu 22.04/24.04+ 和 Debian 的 apt 源替换 | `a53f597` |
        47 -| **1.8** | 修复 libncursesw5 → libncursesw6 跨版本问题 | `be98dcf` |
        48 -| **1.9** | 处理 Ubuntu 24.04 预占用的 UID/GID | `ebe08ca` |
        49 -| **1.10** | Ubuntu ≥ 22.04 跳过 python2.7，使用 libncurses-dev | `22b9086` |
        50 -| **1.11** | 用 envsubst 替换三个 stage 中的 sed 模板渲染 | `306e121` |
        51 -| **1.12** | 添加平台配置的 JSON Schema | `793a7f8` |
        52 -| **1.13** | 添加 .devcontainer/devcontainer.json | `8a7d52b` |
        53 -| **1.14** | 为 create_platform.sh 添加 --non-interactive 模式 | `ba33bf1` |
        40 +| **1.1** | ✅ PORT_SLOT 自动计算系统 | `b9424fd` |
        41 +| **1.2** | ✅ 迁移所有平台到 PORT_SLOT | `f633569` |
        42 +| **1.3** | ✅ 交互式平台创建向导 | `408d340` |
        43 +| **1.4** | ✅ 按 PORT_SLOT 顺序排序平台列表 | `2b5aa14` |
        44 +| **1.5** | ✅ GitLab/Harbor 拆分为独立的 IP+端口变量 | `2ca4cff` |
        45 +| **1.6** | ✅ 向平台配置添加 OS_DISTRIBUTION 字段 | `476caf1` |
        46 +| **1.7** | ✅ 修复 Ubuntu 22.04/24.04+ 和 Debian 的 apt 源替换 | `a53f597` |
        47 +| **1.8** | ✅ 修复 libncursesw5 → libncursesw6 跨版本问题 | `be98dcf` |
        48 +| **1.9** | ✅ 处理 Ubuntu 24.04 预占用的 UID/GID | `ebe08ca` |
        49 +| **1.10** | ✅ Ubuntu ≥ 22.04 跳过 python2.7，使用 libncurses-dev | `22b9086` |
        50 +| **1.11** | ✅ 用 envsubst 替换三个 stage 中的 sed 模板渲染 | `306e121` |
        51 +| **1.12** | ✅ 添加平台配置的 JSON Schema | `793a7f8` |
        52 +| **1.13** | ✅ 添加 .devcontainer/devcontainer.json | `8a7d52b` |
        53 +| **1.14** | ✅ 为 create_platform.sh 添加 --non-interactive 模式 | `ba33bf1` |
        54
        55  ---
        56
    ⎿  1 PostToolUse hook ran

    ● Update(/mnt/2tb_wd_purpleSurveillance_hdd/system-redirection/Development/docker/HarborPilot.git/docs/zh/architecture/2-progress/progress.md)
    ⎿  Added 19 lines, removed 18 lines
        86
        87  | 修复内容 | 提交 | 备注 |
        88  |---|---|---|
        89 -| Dockerfile ARG 跨阶段丢失（CUDA/OpenCV 从未安装） | `0dd8a0c` | 关键：13 个 ARG 现在在 ENV 块中 |
        90 -| build.sh 中 eval 注入 → `${!name}` | `2872784` | 安全修复 |
        91 -| Samba CIFS 挂载中的 UBUNTU_SERVER_IP 孤儿引用 | `2872784` | 运行时 Bug 修复，添加 SAMBA_SERVER_IP |
        92 -| 无效的 bash 展开 `${USE_NVIDIA_GPU,,:-false}` | `2872784` | 正确性修复 |
        93 -| harbor：set -e、死函数、死代码（删除约 100 行） | `0f0e12e` | |
        94 -| 8 个受影响脚本的 shebang 移到第 1 行 | `d729c31` | |
        95 -| 5 个文件中的中文注释翻译为英文 | `d729c31` | |
        96 -| setup_workspace.sh：硬编码的 "developer" → `${DEV_USERNAME}` | `d729c31` | |
        97 -| 更新过时文档（UBUNTU_SERVER_IP、SERVER_SSH_PORT 引用） | `3a06a79` | |
        98 -| OpenCV 构建失败：找不到 cmake（dev_tools 在 OpenCV 之后运行） | `189a7f6` | 重新排序：先安装 dev_tools → 再 OpenCV |
        99 -| Ubuntu 24.04 上 pip3 externally-managed-environment（PEP 668） | `90611c0` | 添加 --break-system-packages |
        100 -| setup_workspace.sh_template：本地变量被 envsubst 替换为空 | `6f505a6` | 关键：转义 \${dir_path} 等 |
        101 -| setup_workspace.sh_template：\\${var} 转义破坏 bash 语法（'then' 处语法错误） | `987265c` | 关键：使用 $1/$2/$3 位置参数 |
        102 -| ARG USE_NVIDIA_GPU 缺失；ARG ENABLE_SYSLOG 重复 | `4cc03db` | Lint 修复 + 正确性 |
        103 -| Harbor/GitLab URL 分组的 CHIP_FAMILY | `9dd8d36` | REGISTRY_URL 和 SDK_GIT_REPO 使用 ${CHIP_FAMILY} |
        104 -| ubuntu_only_entrance.sh 模块化（6 个模块） | `fe46132` | volumes 软链接自动初始化；数字前缀命名 |
        105 -| 所有平台 .env 迁移到 CHIP_FAMILY/CHIP_EXTRACT_NAME 模式 | `16ec81f` `281bd96` | 平台文件重命名为 chip-os 命名规范；REGISTRY_URL 修复 |
        106 -| harbor 平台列表按芯片系列分组；create_platform.sh + CHIP_EXTRACT_NAME | `aad4e32` | 清晰的视觉分组；向导更新新字段 |
        89 +| ✅ Dockerfile ARG 跨阶段丢失（CUDA/OpenCV 从未安装） | `0dd8a0c` | 关键：13 个 ARG 现在在 ENV 块中 |
        90 +| ✅ build.sh 中 eval 注入 → `${!name}` | `2872784` | 安全修复 |
        91 +| ✅ Samba CIFS 挂载中的 UBUNTU_SERVER_IP 孤儿引用 | `2872784` | 运行时 Bug 修复，添加 SAMBA_SERVER_IP |
        92 +| ✅ 无效的 bash 展开 `${USE_NVIDIA_GPU,,:-false}` | `2872784` | 正确性修复 |
        93 +| ✅ harbor：set -e、死函数、死代码（删除约 100 行） | `0f0e12e` | |
        94 +| ✅ 8 个受影响脚本的 shebang 移到第 1 行 | `d729c31` | |
        95 +| ✅ 5 个文件中的中文注释翻译为英文 | `d729c31` | |
        96 +| ✅ setup_workspace.sh：硬编码的 "developer" → `${DEV_USERNAME}` | `d729c31` | |
        97 +| ✅ 更新过时文档（UBUNTU_SERVER_IP、SERVER_SSH_PORT 引用） | `3a06a79` | |
        98 +| ✅ OpenCV 构建失败：找不到 cmake（dev_tools 在 OpenCV 之后运行） | `189a7f6` | 重新排序：先安装 dev_tools → 再 OpenCV |
        99 +| ✅ Ubuntu 24.04 上 pip3 externally-managed-environment（PEP 668） | `90611c0` | 添加 --break-system-packages |
        100 +| ✅ setup_workspace.sh_template：本地变量被 envsubst 替换为空 | `6f505a6` | 关键：转义 \${dir_path} 等 |
        101 +| ✅ setup_workspace.sh_template：\\${var} 转义破坏 bash 语法（'then' 处语法错误） | `987265c` | 关键：使用 $1/$2/$3 位置参数 |
        102 +| ✅ ARG USE_NVIDIA_GPU 缺失；ARG ENABLE_SYSLOG 重复 | `4cc03db` | Lint 修复 + 正确性 |
        103 +| ✅ Harbor/GitLab URL 分组的 CHIP_FAMILY | `9dd8d36` | REGISTRY_URL 和 SDK_GIT_REPO 使用 ${CHIP_FAMILY} |
        104 +| ✅ ubuntu_only_entrance.sh 模块化（6 个模块） | `fe46132` | volumes 软链接自动初始化；数字前缀命名 |
        105 +| ✅ 所有平台 .env 迁移到 CHIP_FAMILY/CHIP_EXTRACT_NAME 模式 | `16ec81f` `281bd96` | 平台文件重命名为 chip-os 命名规范；REGISTRY_URL 修复 |
        106 +| ✅ harbor 平台列表按芯片系列分组；create_platform.sh + CHIP_EXTRACT_NAME | `aad4e32` | 清晰的视觉分组；向导更新新字段 |
        107 +| ✅ docker compose project name 含 `.` 报错（PRODUCT_NAME 含 `24.04`） | `12deccc` | 新增 OS_VERSION_ID（点→连字符）；所有平台 + create_platform.sh 同步更新 |
        108
        109  ---
        110
    ⎿  1 PostToolUse hook ran

                                                                                                                                                                    09:23 AM <synthetic>
    ⎿  Context limit reached · /compact or /clear to continue


    ```

Mar28.2026 08:45
- [x] docker compose project name 含 `.` 报错（如 rk3588-rk3588s_ubuntu-24.04）
    ```
    invalid project name "rk3588-rk3588s_ubuntu-24.04": must consist only of lowercase
    alphanumeric characters, hyphens, and underscores...
    ```
    → 已修复：新增 OS_VERSION_ID（点换连字符），PRODUCT_NAME 改用 OS_VERSION_ID 拼装，
      所有 platform .env + 01_base.env + create_platform.sh 同步更新。
      结果：rk3588-rk3588s_ubuntu-24-04（无点），Dockerfile FROM 仍用 OS_VERSION="24.04"。
- [x] docs/ 下有 3 份文档树（docs/architecture/ + docs/en/ + docs/zh/）
    → 已修复：docs/architecture/ 是迁移到 en/zh 双语结构后的遗留目录，仅剩一个
      NEED_TO_DO.md。该文件内容已合并至此文件，旧目录已删除。

Mar27.2026 17:00
- [x] 看看这个
    ```bash
    james@Anastasia:/mnt/2tb_wd_purpleSurveillance_hdd/system-redirection/Development/docker/HarborPilot.git$ ./project_handover/clientside/ubuntu/ubuntu_only_entrance.sh recreate
    ...
    ERROR: VOLUMES_DIR is not set and volumes symlink is not available
    ```
    → 已修复：main_entry_5th_cmd_recreate() 缺少 volumes_init_3rd_init_if_needed 调用，
      与 start 命令保持一致后问题消除。

Mar27.2026 16:00
- [x] 做了很多事情，一直没修改doc,请你接下来修改的时候，验证一个item，就check一个，然后commit，不许等全部都做完，context很快就用完了。
    ```bash
        ● 显示效果很清晰。现在 commit：

    ● Bash(git diff --stat)
    ⎿   docs/architecture/2-progress/NEED_TO_DO.md |  15 +++++
        harbor                                     |  59 ++++++++++++-----
        scripts/create_platform.sh                 | 103 ++++++++++++++++++++---------
        3 files changed, 129 insertions(+), 48 deletions(-)

    ● Bash(git add harbor scripts/create_platform.sh && git commit -m "$(cat <<'EOF'
        feat: add CHIP_EXTRACT_NAME to create_platform.sh; group platform list by chip family…)
    ⎿  [refactor/port-mapping aad4e32] feat: add CHIP_EXTRACT_NAME to create_platform.sh; group platform list by chip family
        2 files changed, 114 insertions(+), 48 deletions(-)
    ⎿  Context limit reached · /compact or /clear to continue

    ✻ Baked for 19m 50s

    5 tasks (3 done, 2 open)
    ✔ Optimize harbor platform list display (group by chip family)
    ✔ Update create_platform.sh with CHIP_FAMILY + CHIP_EXTRACT_NAME
    ◻ Write competitive analysis + highlights doc + update README
    ◻ Write MCP/AI Agent Phase 4 plan
    ✔ Confirm CHIP_FAMILY tag bug status & check checkbox

    ```

Mar27.2026 15:30
- [x] 我的./harbor [7].+ Create new platform应该需要增加选项，因为我增加了一个chip_exact_name
- [x] 我当前的item list显示太杂乱了，现在我把names都加长了，写得很详细，所以文本太密集，感觉获取信息的时间就增长了。
    ```bash
    Now we have below platforms:
    [1].rk3588-rk3588s_ubuntu-22.04
    [2].rv1126-rv1126bp_ubuntu-22.04
    [3].rk3568-rk3568_ubuntu-20.04
    [4].rv1126-rv1126_ubuntu-22.04
    [5].rk3568-rk3568_ubuntu-22.04
    [6].rk3588-rk3588s_ubuntu-24.04

    ```
    我之前要求按照port-map的递增顺序来排列，现在可以按照chip_family来，或者你有更好的建议，可以用你的。

Mar27.2026 10:45
- [x] 我这里要修改harbor push的url
    ```bash
    SDK_GIT_REPO="git@${GITLAB_SERVER_IP:-192.168.3.67}:team_${CONTAINER_NAME}/${CONTAINER_NAME}_sdk.git"
    ```
    例如这里，我每次都靠精准的匹配，但是其实我这里已经出现了rk3588s系列有多种os version，未来甚至可能出现多种os distribution。
    你觉得我这里最好的做法应该是直接写死url,不要用动态字符串匹配拼装的方式，还是我应该把字符串拆得更细，让它匹配更精准呢？
    以目前来看，我的rk3568竟然和rk3568-ubuntu-22不是一个team,这个就让人有点无奈了，应该是要以一个不变的主体为单位，其他的一切变体都在这个team内部，对吗？
    你给我建议，如何做最好，然后让我选择。（之前我已经决定要采纳用chip_family的方式来拼装harbor url了，但没做完，你可以继续做）
- [x] 我并不要你付诸实践，这里是有一条方案的征集
    如果我要实现跟当前项目几乎完全相同的功能，你会推荐什么现成的或者开源的软件，直接使用或二次开发都行，来达到我的目的呢？
    我其实要问的是：我的软件有什么独到之处，能够在ai时代杀出一条血路来，不是做大而全，但是是在我场景内的好用，并且尽可能覆盖多的场景，也都好用（如果10个场景做得不好，那我会精致做1个场景，做好用，需要其他9个场景，我可以写其他9款软件来适配）
    你把这个亮点，写到3-highlights里面去，放进合适的文档里（你可以新建），然后更新00_index。
    然后重新梳理我的亮点，按顺序排列，务求每一个亮点务实，且很容易记住，亮点体现到readme里面。
    → 已完成：新建 competitive_analysis.md，更新 README.md Key Features，更新 00_INDEX.md（commit: 3a8c37e）
- [x] 我当前这个项目，有什么可以给AI Agent开放的空间吗？
    请结合当下的主流，例如MCP/Skills这些内容，可以让我的软件第一优先是被AI Agent读取使用，其次是能够被AI推荐给其他人（这个不知道要怎么做），第三是给人git clone下来之后，自己配置选项，然后就可以使用。你详细跟我解释一下MCP的原理（例如你觉得是MCP可以做），然后介绍我们要怎么做，做成一个新的版本的计划。例如当前是phase3，你就把这个迭代的部分写到Phase4里去，然后专门出一个文档来介绍（或者一个chapter,你规划好就行）这个迭代任务，写仔细，让下一个ai一眼就可以看懂。
    → 已完成：新建 phase4_mcp_ai_agent_plan.md，更新 progress.md Phase 4 章节，更新 00_INDEX.md + codebase_map.md（commit: 见下）

- [x] 还是有这样的错误，表明你原先的chip_family并没有在tag的时候传递下去，肯定变量那边哪里出问题了。还有我已经修改了我要的标准样式，你看看HarborPilot.git/configs/platforms/rk3588s-ubuntu-24.env，这里就有我要的，你告诉我你看见什么了，然后才问我是否要把其他的几种.env也都照这样修改。
    → 已修复：所有平台 .env 已迁移至 CHIP_FAMILY/CHIP_EXTRACT_NAME 模式，REGISTRY_URL 使用 ${CHIP_FAMILY} 正确拼装（commits: 4a1ba37, 16ec81f, 281bd96）
    ```bash
    3 warnings found (use docker --debug to expand):
    - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "SAMBA_PRIVATE_ACCOUNT_PASSWORD") (line 125)
    - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "DEV_USER_PASSWORD") (line 47)
    - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "DEV_USER_ROOT_PASSWORD") (line 48)

    === 2. Preparing Version Information ===
    Using version: 1.7.1
    Getting final image ID for rk3588s-ubuntu-24-dev-env:1.7.1
    Final image ID: 4b07ebf08ff2

    --------------------
    Tag images?
    --------------------
    Default: Yes (Press 'n' to skip, any other key to continue, Ctrl+C or Esc to abort all)
    Starting in 1 seconds...
    Proceeding with default action...

    === 3. Tagging Images ===
    Tagging images...
    Executing: docker tag rk3588s-ubuntu-24-dev-env:1.7.1 192.168.3.67:9000/team_/rk3588s-ubuntu-24-dev-env:1.7.1
    error parsing reference: "192.168.3.67:9000/team_/rk3588s-ubuntu-24-dev-env:1.7.1" is not a valid repository/tag: invalid reference format
    ✗ Error: Failed to tag rk3588s-ubuntu-24-dev-env:1.7.1 as 192.168.3.67:9000/team_/rk3588s-ubuntu-24-dev-env:1.7.1
    ✗ Error: Failed to tag client image rk3588s-ubuntu-24-dev-env:1.7.1 as 192.168.3.67:9000/team_/rk3588s-ubuntu-24-dev-env:1.7.1
    Executing: docker tag rk3588s-ubuntu-24-dev-env:1.7.1 192.168.3.67:9000/team_/rk3588s-ubuntu-24-dev-env:latest
    error parsing reference: "192.168.3.67:9000/team_/rk3588s-ubuntu-24-dev-env:latest" is not a valid repository/tag: invalid reference format
    ✗ Error: Failed to tag rk3588s-ubuntu-24-dev-env:1.7.1 as 192.168.3.67:9000/team_/rk3588s-ubuntu-24-dev-env:latest
    ✗ Error: Failed to tag client image rk3588s-ubuntu-24-dev-env:1.7.1 as 192.168.3.67:9000/team_/rk3588s-ubuntu-24-dev-env:latest
    Done with tagging images.

    === 4. Pushing Images ===

    --------------------
    Push images to the registry?
    --------------------
    Default: Yes (Press 'n' to skip, any other key to continue, Ctrl+C or Esc to abort all)
    Starting in 1 seconds...
    Proceeding with default action...
    Pushing images...

    ##############################
    Pushing rk3588s-ubuntu-24-dev-env:1.7.1 to registry...
    ##############################
    Executing: docker push 192.168.3.67:9000/team_/rk3588s-ubuntu-24-dev-env:1.7.1
    invalid reference format
    ✗ Error: Failed to push rk3588s-ubuntu-24-dev-env:1.7.1
    ✗ Error: Failed to push/verify client image
    ✗ Error: Failed to push version 1.7.1

    ##############################
    Pushing rk3588s-ubuntu-24-dev-env:latest to registry...
    ##############################
    Executing: docker push 192.168.3.67:9000/team_/rk3588s-ubuntu-24-dev-env:latest
    invalid reference format
    ✗ Error: Failed to push rk3588s-ubuntu-24-dev-env:latest
    ✗ Error: Failed to push/verify client image
    ✗ Error: Failed to push latest version
    ```

Mar27.2026 10:00
- [x] 还是有错，但应该刚才的已经解决
    ```bash

    #58 [stage_5th_template-processor 1/5] RUN echo -e "\n========= Stage 5th =========\n\n"
    #58 0.075
    #58 0.075 ========= Stage 5th =========
    #58 0.075
    #58 0.075
    #58 DONE 0.1s

    #59 [stage_5th_template-processor 2/5] COPY ./stage_5_final/configs/ /tmp/configs/
    #59 DONE 0.0s

    #60 [stage_5th_template-processor 3/5] COPY ./stage_5_final/scripts/ /tmp/scripts/
    #60 DONE 0.0s

    #61 [stage_5th_template-processor 4/5] WORKDIR /tmp
    #61 DONE 0.0s

    #62 [stage_5th_template-processor 5/5] RUN for template in $(find /tmp/configs /tmp/scripts -name "*_template" 2>/dev/null); do         output_file="${template%_template}";         echo "Processing $template -> $output_file";         envsubst < "$template" > "$output_file";         chmod +x "$output_file";     done
    #62 0.075 Processing /tmp/configs/entrypoint.conf_template -> /tmp/configs/entrypoint.conf
    #62 0.079 Processing /tmp/configs/workspace.conf_template -> /tmp/configs/workspace.conf
    #62 0.081 Processing /tmp/scripts/setup_workspace.sh_template -> /tmp/scripts/setup_workspace.sh
    #62 0.085 Processing /tmp/scripts/entrypoint.sh_template -> /tmp/scripts/entrypoint.sh
    #62 DONE 0.1s

    #63 [stage_5th_final  1/10] COPY --from=stage_5th_template-processor /tmp/configs/workspace.conf /etc/workspace.conf
    #63 DONE 0.0s

    #64 [stage_5th_final  2/10] COPY --from=stage_5th_template-processor /tmp/configs/entrypoint.conf /etc/entrypoint.conf
    #64 DONE 0.0s

    #65 [stage_5th_final  3/10] COPY --from=stage_5th_template-processor /tmp/scripts/setup_workspace.sh /usr/local/bin/
    #65 DONE 0.0s

    #66 [stage_5th_final  4/10] COPY --from=stage_5th_template-processor /tmp/scripts/entrypoint.sh /usr/local/bin/
    #66 DONE 0.0s

    #67 [stage_5th_final  5/10] RUN chmod +x /usr/local/bin/setup_workspace.sh     && chmod +x /usr/local/bin/entrypoint.sh
    #67 DONE 0.1s

    #68 [stage_5th_final  6/10] RUN set -ex &&     /usr/local/bin/setup_workspace.sh
    #68 0.074 + /usr/local/bin/setup_workspace.sh
    #68 0.075 /usr/local/bin/setup_workspace.sh: line 21: syntax error near unexpected token `then'
    #68 ERROR: process "/bin/bash -c set -ex &&     /usr/local/bin/setup_workspace.sh" did not complete successfully: exit code: 2
    ------
    > [stage_5th_final  6/10] RUN set -ex &&     /usr/local/bin/setup_workspace.sh:
    0.074 + /usr/local/bin/setup_workspace.sh
    0.075 /usr/local/bin/setup_workspace.sh: line 21: syntax error near unexpected token `then'
    ------

    3 warnings found (use docker --debug to expand):
    - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "DEV_USER_PASSWORD") (line 47)
    - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "DEV_USER_ROOT_PASSWORD") (line 48)
    - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "SAMBA_PRIVATE_ACCOUNT_PASSWORD") (line 125)
    Dockerfile:531
    --------------------
    530 |     # Setup workspace and permissions
    531 | >>> RUN set -ex && \
    532 | >>>     /usr/local/bin/setup_workspace.sh
    533 |
    --------------------
    ERROR: failed to build: failed to solve: process "/bin/bash -c set -ex &&     /usr/local/bin/setup_workspace.sh" did not complete successfully: exit code: 2
    In /mnt/2tb_wd_purpleSurveillance_hdd/system-redirection/Development/docker/HarborPilot.git/docker/dev-env-clientside/build.sh, Docker build failed with exit status: 1
    Error: Failed to build clientside image


    ```

Mar27.2026 09:25
- [x] 编了opencv之后出现这个，这个是开了install-opencv才有的
    ```bash
    #19 163.7    creating: opencv-4.9.0/samples/wp8/OpenCVXaml/OpenCVXaml/Resources/
    #19 163.7   inflating: opencv-4.9.0/samples/wp8/OpenCVXaml/OpenCVXaml/Resources/AppResources.Designer.cs
    #19 163.7   inflating: opencv-4.9.0/samples/wp8/OpenCVXaml/OpenCVXaml/Resources/AppResources.resx
    #19 163.7   inflating: opencv-4.9.0/samples/wp8/readme.txt
    #19 163.8 /tmp/install_opencv.sh: line 38: cmake: command not found
    #19 163.8
    #19 163.8
    #19 163.8 ##########################################################
    #19 163.8 (3/4)OpenCV is installed, Done
    #19 163.8 ##########################################################
    #19 163.8
    #19 163.8

    ```

- [x] 还有这个，与是否opnecv/cuda无关
    ```bash
    #20 130.0 Setting up libpython3-dev:amd64 (3.12.3-0ubuntu2.1) ...
    #20 130.0 Setting up python3-dev (3.12.3-0ubuntu2.1) ...
    #20 130.0 Processing triggers for man-db (2.12.0-4build2) ...
    #20 130.9 pip 24.0 from /usr/lib/python3/dist-packages/pip (python 3.12)
    #20 131.2 error: externally-managed-environment
    #20 131.2
    #20 131.2 × This environment is externally managed
    #20 131.2 ╰─> To install Python packages system-wide, try apt install
    #20 131.2     python3-xyz, where xyz is the package you are trying to
    #20 131.2     install.
    #20 131.2
    #20 131.2     If you wish to install a non-Debian-packaged Python package,
    #20 131.2     create a virtual environment using python3 -m venv path/to/venv.
    #20 131.2     Then use path/to/venv/bin/python and path/to/venv/bin/pip. Make
    #20 131.2     sure you have python3-full installed.
    #20 131.2
    #20 131.2     If you wish to install a non-Debian packaged Python application,
    #20 131.2     it may be easiest to use pipx install xyz, which will manage a
    #20 131.2     virtual environment for you. Make sure you have pipx installed.
    #20 131.2
    #20 131.2     See /usr/share/doc/python3.12/README.venv for more information.
    #20 131.2
    #20 131.2 note: If you believe this is a mistake, please contact your Python installation or OS distribution provider. You can override this, at the risk of breaking your Python installation or OS, by passing --break-system-packages.
    #20 131.2 hint: See PEP 668 for the detailed specification.
    #20 131.3 Retry installing cmake-format (0/3)
    #20 136.5 error: externally-managed-environment
    #20 136.5
    #20 136.5 × This environment is externally managed
    #20 136.5 ╰─> To install Python packages system-wide, try apt install
    #20 136.5     python3-xyz, where xyz is the package you are trying to
    #20 136.5     install.
    #20 136.5
    #20 136.5     If you wish to install a non-Debian-packaged Python package,
    #20 136.5     create a virtual environment using python3 -m venv path/to/venv.
    #20 136.5     Then use path/to/venv/bin/python and path/to/venv/bin/pip. Make
    #20 136.5     sure you have python3-full installed.
    #20 136.5
    #20 136.5     If you wish to install a non-Debian packaged Python application,
    #20 136.5     it may be easiest to use pipx install xyz, which will manage a
    #20 136.5     virtual environment for you. Make sure you have pipx installed.
    #20 136.5
    #20 136.5     See /usr/share/doc/python3.12/README.venv for more information.
    #20 136.5
    #20 136.5 note: If you believe this is a mistake, please contact your Python installation or OS distribution provider. You can override this, at the risk of breaking your Python installation or OS, by passing --break-system-packages.
    #20 136.5 hint: See PEP 668 for the detailed specification.
    #20 136.6 Retry installing cmake-format (1/3)
    #20 141.8 error: externally-managed-environment
    #20 141.8
    #20 141.8 × This environment is externally managed
    #20 141.8 ╰─> To install Python packages system-wide, try apt install
    #20 141.8     python3-xyz, where xyz is the package you are trying to
    #20 141.8     install.
    #20 141.8
    #20 141.8     If you wish to install a non-Debian-packaged Python package,
    #20 141.8     create a virtual environment using python3 -m venv path/to/venv.
    #20 141.8     Then use path/to/venv/bin/python and path/to/venv/bin/pip. Make
    #20 141.8     sure you have python3-full installed.
    #20 141.8
    #20 141.8     If you wish to install a non-Debian packaged Python application,
    #20 141.8     it may be easiest to use pipx install xyz, which will manage a
    #20 141.8     virtual environment for you. Make sure you have pipx installed.
    #20 141.8
    #20 141.8     See /usr/share/doc/python3.12/README.venv for more information.
    #20 141.8
    #20 141.8 note: If you believe this is a mistake, please contact your Python installation or OS distribution provider. You can override this, at the risk of breaking your Python installation or OS, by passing --break-system-packages.
    #20 141.8 hint: See PEP 668 for the detailed specification.
    #20 141.9 Retry installing cmake-format (2/3)
    #20 146.9 Warning: Failed to install cmake-format, continuing anyway...
    #20 147.1 error: externally-managed-environment
    #20 147.1
    #20 147.1 × This environment is externally managed
    #20 147.1 ╰─> To install Python packages system-wide, try apt install
    #20 147.1     python3-xyz, where xyz is the package you are trying to
    #20 147.1     install.
    #20 147.1
    #20 147.1     If you wish to install a non-Debian-packaged Python package,
    #20 147.1     create a virtual environment using python3 -m venv path/to/venv.
    #20 147.1     Then use path/to/venv/bin/python and path/to/venv/bin/pip. Make
    #20 147.1     sure you have python3-full installed.
    #20 147.1
    #20 147.1     If you wish to install a non-Debian packaged Python application,
    #20 147.1     it may be easiest to use pipx install xyz, which will manage a
    #20 147.1     virtual environment for you. Make sure you have pipx installed.
    #20 147.1
    #20 147.1     See /usr/share/doc/python3.12/README.venv for more information.
    #20 147.1
    #20 147.1 note: If you believe this is a mistake, please contact your Python installation or OS distribution provider. You can override this, at the risk of breaking your Python installation or OS, by passing --break-system-packages.
    #20 147.1 hint: See PEP 668 for the detailed specification.
    #20 147.2 Retry installing pre-commit (0/3)
    #20 152.4 error: externally-managed-environment
    #20 152.4
    #20 152.4 × This environment is externally managed
    #20 152.4 ╰─> To install Python packages system-wide, try apt install
    #20 152.4     python3-xyz, where xyz is the package you are trying to
    #20 152.4     install.
    #20 152.4
    #20 152.4     If you wish to install a non-Debian-packaged Python package,
    #20 152.4     create a virtual environment using python3 -m venv path/to/venv.
    #20 152.4     Then use path/to/venv/bin/python and path/to/venv/bin/pip. Make
    #20 152.4     sure you have python3-full installed.
    #20 152.4
    #20 152.4     If you wish to install a non-Debian packaged Python application,
    #20 152.4     it may be easiest to use pipx install xyz, which will manage a
    #20 152.4     virtual environment for you. Make sure you have pipx installed.
    #20 152.4
    #20 152.4     See /usr/share/doc/python3.12/README.venv for more information.
    #20 152.4
    #20 152.4 note: If you believe this is a mistake, please contact your Python installation or OS distribution provider. You can override this, at the risk of breaking your Python installation or OS, by passing --break-system-packages.
    #20 152.4 hint: See PEP 668 for the detailed specification.
    #20 152.5 Retry installing pre-commit (1/3)
    #20 157.7 error: externally-managed-environment
    #20 157.7
    #20 157.7 × This environment is externally managed
    #20 157.7 ╰─> To install Python packages system-wide, try apt install
    #20 157.7     python3-xyz, where xyz is the package you are trying to
    #20 157.7     install.
    #20 157.7
    #20 157.7     If you wish to install a non-Debian-packaged Python package,
    #20 157.7     create a virtual environment using python3 -m venv path/to/venv.
    #20 157.7     Then use path/to/venv/bin/python and path/to/venv/bin/pip. Make
    #20 157.7     sure you have python3-full installed.
    #20 157.7
    #20 157.7     If you wish to install a non-Debian packaged Python application,
    #20 157.7     it may be easiest to use pipx install xyz, which will manage a
    #20 157.7     virtual environment for you. Make sure you have pipx installed.
    #20 157.7
    #20 157.7     See /usr/share/doc/python3.12/README.venv for more information.
    #20 157.7
    #20 157.7 note: If you believe this is a mistake, please contact your Python installation or OS distribution provider. You can override this, at the risk of breaking your Python installation or OS, by passing --break-system-packages.
    #20 157.7 hint: See PEP 668 for the detailed specification.
    #20 157.8 Retry installing pre-commit (2/3)
    #20 162.8 Warning: Failed to install pre-commit, continuing anyway...
    #20 162.8
    #20 162.8
    #20 162.8 ##########################################################
    #20 162.8 (4/4)Dev Tools are installed, Done
    #20 162.8 ##########################################################
    #20 162.8
    #20 162.8
    #20 DONE 162.9s

    #21 [stage_2nd_tools 10/12] RUN chmod +x /usr/local/bin/gitlfs_tracker.sh
    #21 DONE 0.1s

    #22 [stage_2nd_tools 11/12] RUN rm -f /tmp/install_*.sh &&     rm -f /tmp/tool_versions.conf
    #22 DONE 0.1s


    ```
- [x] 这个也是不论是否开opencv/cuda，都有的
    ```bash
    #68 [stage_5th_final  6/10] RUN set -ex &&     /usr/local/bin/setup_workspace.sh
    #68 0.074 + /usr/local/bin/setup_workspace.sh
    #68 0.075
    #68 0.075 Starting workspace setup...
    #68 0.075 Initializing workspace structure...
    #68 0.075 Creating directory:
    #68 0.075 ERROR: Directory path is empty
    #68 ERROR: process "/bin/bash -c set -ex &&     /usr/local/bin/setup_workspace.sh" did not complete successfully: exit code: 1
    ------
    > [stage_5th_final  6/10] RUN set -ex &&     /usr/local/bin/setup_workspace.sh:
    0.074 + /usr/local/bin/setup_workspace.sh
    0.075
    0.075 Starting workspace setup...
    0.075 Initializing workspace structure...
    0.075 Creating directory:
    0.075 ERROR: Directory path is empty
    ------

    4 warnings found (use docker --debug to expand):
    - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "DEV_USER_PASSWORD") (line 47)
    - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "DEV_USER_ROOT_PASSWORD") (line 48)
    - SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data (ARG "SAMBA_PRIVATE_ACCOUNT_PASSWORD") (line 125)
    - UndefinedVar: Usage of undefined variable '$USE_NVIDIA_GPU' (line 152)
    Dockerfile:529
    --------------------
    528 |     # Setup workspace and permissions
    529 | >>> RUN set -ex && \
    530 | >>>     /usr/local/bin/setup_workspace.sh
    531 |
    --------------------
    ERROR: failed to build: failed to solve: process "/bin/bash -c set -ex &&     /usr/local/bin/setup_workspace.sh" did not complete successfully: exit code: 1
    In /mnt/2tb_wd_purpleSurveillance_hdd/system-redirection/Development/docker/HarborPilot.git/docker/dev-env-clientside/build.sh, Docker build failed with exit status: 1
    Error: Failed to build clientside image

    ```


Mar27.2026 09:10
- [x] 运行出现
    ```bash
    $ ./harbor
    Build process started at:
    ###################################
    #   Fri Mar27.2026 09:03:39
    ###################################

    Now we have below platforms:

    ```
    请解决

Mar27.2026 08:40
- [x] 继续完成HarborPilot.git/docs/architecture/2-progress/Mar27.2026-RestWork里的剩余工作，做完后验证（包括请我手动验证，告诉我验证方法和项目是什么），然后确认做好，提醒我确认是否删除HarborPilot.git/docs/architecture/2-progress/Mar27.2026-RestWork文档，然后你commit

Mar26.2026 23:00
- [x] Fix README.md: all `doc/` references need updating to `docs/` after directory rename
- [x] Evaluate: should `docker/libs/iv_scripts/setup_base.sh` be deleted or merged into stage_1 version? → **Deleted** (fully superseded by stage_1 version)
- [x] Evaluate: should `docker/libs/ii_dockerfile_modules/*.df` be deleted (never used by current Dockerfile)? → **Deleted** (entire `docker/libs/` removed)
- [x] `docker-compose.yaml` in project_handover still has hardcoded values — should use `${VAR}` from `.env` → **Done** (8 values now configurable via defaults)

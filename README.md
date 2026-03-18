# HarborPilot
This is a One-Click docker images and containers setup base which is doing via a lot of bash scripts. My primary target is embedded linux development and you can choose your target whatever you want. Have fun. Thank you for your starts.

  结构变化

  configs/
  ├── defaults/                    ← Layer 1（新建，11个文件）
  │   ├── base.env                 全局基础：OS版本、用户、时区
  │   ├── build.env                Docker BuildKit 开关
  │   ├── tools.env                工具安装开关 & 版本号
  │   ├── workspace.env            工作区路径 & 行为配置
  │   ├── registry.env             Registry 地址（默认3.67:9000）
  │   ├── sdk.env                  SDK 安装开关
  │   ├── volumes.env              VOLUMES_ROOT 默认路径
  │   ├── samba.env                Samba 账号密码
  │   ├── runtime.env              SSH/GDB/syslog 开关（USE_NVIDIA_GPU=false）
  │   ├── serverside.env           distcc 配置
  │   └── proxy.env                HAS_PROXY=false（默认关）
  │
  ├── platform-independent/
  │   └── common.env              ← Layer 2（不变）
  │
  └── platforms/                  ← Layer 3（精简后）
      ├── rk3588s.env              78 行（原 187 行，缩减 58%）
      ├── rk3568.env               84 行（原 180 行，缩减 53%）
      ├── rv1126.env               83 行（原 187 行，缩减 56%）
      ├── rv1126bp.env             83 行（原 187 行，缩减 56%）
      ├── rk3568-ubuntu22.env      83 行（原 187 行，缩减 56%）
      └── offline.env              82 行（原 184 行，缩减 55%）

  各平台 env 现在只写"与默认不同的内容"

  ┌───────────────────┬──────────────────────────────────────────────┬────────────────────────┐
  │       类别        │                 每个平台必写                 │          说明          │
  ├───────────────────┼──────────────────────────────────────────────┼────────────────────────┤
  │ Platform Identity │ PRODUCT_NAME, OS_VERSION 等                  │ 无默认值，必须显式声明 │
  ├───────────────────┼──────────────────────────────────────────────┼────────────────────────┤
  │ 端口              │ CLIENT_SSH_PORT, SERVER_SSH_PORT, GDB_PORT   │ 每台平台独有           │
  ├───────────────────┼──────────────────────────────────────────────┼────────────────────────┤
  │ 路径              │ HOST_VOLUME_DIR                              │ 每台平台独有           │
  ├───────────────────┼──────────────────────────────────────────────┼────────────────────────┤
  │ 差异项            │ 如 HAS_PROXY=true, NPM_USE_CHINA_MIRROR=true │ 仅在与默认值不同时才写 │
  └───────────────────┴──────────────────────────────────────────────┴────────────────────────┘

  build.sh 加载逻辑

  现在是严格的三层顺序加载，后加载的覆盖先加载的，dedup 机制确保 BUILD_ARG 不重复传入。新增全局 flag？只改 defaults/xxx.env，所有平台自动继承。


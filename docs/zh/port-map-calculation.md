# HarborPilot — 端口映射 · PORT_SLOT 系统

> **Related:** [English Version →](../../en/port-map-calculation.md)

端口现已从单个 `PORT_SLOT` 数字自动计算。
无需手动计算任何端口。

## 工作原理

每个平台在其 .env 文件中定义 `PORT_SLOT=N`。
`configs/port_calc.sh` 脚本（在 Layer 3 之后 source）派生所有端口：

```
CLIENT_SSH_PORT = 2109 + (PORT_SLOT × 10)
GDB_PORT        = 2345 + (PORT_SLOT × 10)
```

## 当前插槽分配

| 插槽 | 平台               | SSH    | GDB    |
|------|--------------------|--------|--------|
|  0   | rk3588s            | 2109   | 2345   |
|  1   | rv1126bp           | 2119   | 2355   |
|  2   | rk3568             | 2129   | 2365   |
|  3   | rv1126             | 2139   | 2375   |
|  4   | rk3568-ubuntu22    | 2149   | 2385   |
|  5   | rk3588s-ubuntu24   | 2159   | 2395   |

## 添加新平台

运行 `./harbor` 并选择"创建新平台"。
向导会自动分配下一个可用插槽并生成 .env 文件。

## 规则

1. **PORT_SLOT 与显式端口互斥。**
   在同一个 .env 中不能同时设置 `PORT_SLOT` 和 `CLIENT_SSH_PORT`。
   系统会报错并指出哪些变量存在冲突。

2. **遗留显式模式** 仍受支持：若未定义 PORT_SLOT，
   则必须手动设置 `CLIENT_SSH_PORT` 和 `GDB_PORT`。

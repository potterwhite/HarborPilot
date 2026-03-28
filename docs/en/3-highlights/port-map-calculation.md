
# Port Mapping — PORT_SLOT System

> **Related:** [中文版 →](../../../../zh/4-reference/port-map-calculation.md)

Ports are now auto-calculated from a single `PORT_SLOT` number.
No manual port arithmetic is needed.

## How it works

Each platform defines `PORT_SLOT=N` in its .env file.
The `configs/port_calc.sh` script (sourced after Layer 3) derives all ports:

```
CLIENT_SSH_PORT = 2109 + (PORT_SLOT × 10)
GDB_PORT        = 2345 + (PORT_SLOT × 10)
```

## Current slot assignments

| Slot | Platform           | SSH    | GDB    |
|------|--------------------|--------|--------|
|  0   | rk3588s            | 2109   | 2345   |
|  1   | rv1126bp           | 2119   | 2355   |
|  2   | rk3568             | 2129   | 2365   |
|  3   | rv1126             | 2139   | 2375   |
|  4   | rk3568-ubuntu22    | 2149   | 2385   |
|  5   | rk3588s-ubuntu24   | 2159   | 2395   |

## Adding a new platform

Run `./harbor` and select "Create new platform".
The wizard auto-assigns the next available slot and generates the .env file.

## Rules

1. **PORT_SLOT and explicit ports are mutually exclusive.**
   You cannot set both `PORT_SLOT` and `CLIENT_SSH_PORT` in the same .env.
   The system will error out and tell you which variables conflict.

2. **Legacy explicit mode** is still supported: if no PORT_SLOT is defined,
   you must set `CLIENT_SSH_PORT` and `GDB_PORT` manually.

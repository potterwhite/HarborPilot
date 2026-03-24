#!/usr/bin/env bash
################################################################################
# File: scripts/port_calc.sh
#
# Description: Port auto-calculation and validation.
#              Sourced AFTER Layer 3 (platform overrides) in every config loader.
#
#   Two mutually exclusive modes:
#     MODE A — Declarative (recommended for new platforms):
#              Set PORT_SLOT in the platform .env file.
#              All ports are derived automatically from base values.
#
#     MODE B — Explicit (legacy or special cases):
#              Set CLIENT_SSH_PORT and GDB_PORT directly.
#              No PORT_SLOT is defined.
#
#   Mixing the two modes is an error — the script will print which
#   variables conflict and exit 1.
#
# Author: PotterWhite
# Created: 2026-03-24
#
# Copyright (c) 2024 [PotterWhite]
# License: MIT
################################################################################

# ─── Port base values (single source of truth) ──────────────────────────────
# Reference platform: rk3588s (PORT_SLOT=0)
_PORT_BASE_CLIENT_SSH=2109
_PORT_BASE_GDB=2345
_PORT_STEP=10

# ─── MODE A: PORT_SLOT defined → always takes priority ───────────────────────
# PORT_SLOT is the single source of truth. If it is set (even when CLIENT_SSH_PORT
# or GDB_PORT happen to be present as inherited env vars from a parent process),
# we simply (re-)calculate from PORT_SLOT and export, overriding anything else.
if [[ -n "${PORT_SLOT+set}" ]]; then
    if ! [[ "${PORT_SLOT}" =~ ^[0-9]+$ ]]; then
        echo "FATAL: PORT_SLOT must be a non-negative integer, got: '${PORT_SLOT}'"
        exit 1
    fi

    _offset=$(( PORT_SLOT * _PORT_STEP ))

    CLIENT_SSH_PORT=$(( _PORT_BASE_CLIENT_SSH + _offset ))
    GDB_PORT=$(( _PORT_BASE_GDB + _offset ))

    export CLIENT_SSH_PORT GDB_PORT

    echo "[port_calc] MODE A — PORT_SLOT=${PORT_SLOT} (offset=${_offset})"
    echo "[port_calc]   CLIENT_SSH_PORT = ${CLIENT_SSH_PORT}"
    echo "[port_calc]   GDB_PORT        = ${GDB_PORT}"

# ─── MODE B: No PORT_SLOT → require explicit ports ───────────────────────────
else
    _missing=""
    for _var in CLIENT_SSH_PORT GDB_PORT; do
        if [[ -z "${!_var+set}" ]]; then
            _missing="${_missing}  ${_var}\n"
        fi
    done

    if [[ -n "${_missing}" ]]; then
        echo ""
        echo "  =================================================================="
        echo "  FATAL: No PORT_SLOT defined and these required ports are missing:"
        echo "  =================================================================="
        echo ""
        echo -e "${_missing}"
        echo ""
        echo "  Either define PORT_SLOT for auto-calculation, or define all ports:"
        echo "    CLIENT_SSH_PORT=\"XXXX\""
        echo "    GDB_PORT=\"XXXX\""
        echo ""
        echo "  =================================================================="
        exit 1
    fi

    echo "[port_calc] MODE B — explicit ports from platform .env"
    echo "[port_calc]   CLIENT_SSH_PORT = ${CLIENT_SSH_PORT}"
    echo "[port_calc]   GDB_PORT        = ${GDB_PORT}"
fi

# ─── Cleanup internal variables ──────────────────────────────────────────────
unset _offset _missing _var

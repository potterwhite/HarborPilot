#!/usr/bin/env bash
################################################################################
# File: scripts/port_calc.sh
#
# Description: Port auto-calculation and validation.
#              Sourced AFTER Layer 3 (platform overrides) in every config loader.
#
#   Two modes with clear priority:
#
#     MODE A — Declarative (recommended, higher priority):
#              Set PORT_SLOT in the platform .env file.
#              All ports are derived automatically from base values.
#              Any explicit CLIENT_SSH_PORT/GDB_PORT from Layer 1 defaults
#              are overridden.
#
#     MODE B — Explicit (fallback when PORT_SLOT=0 or unset):
#              Use CLIENT_SSH_PORT and GDB_PORT directly.
#              Relies on Layer 1 defaults or explicit platform values.
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

# ─── MODE A: Calculate from PORT_SLOT (higher priority) ─────────────────────
# Only skip when PORT_SLOT is truly unset or empty — PORT_SLOT=0 is valid.
if [[ -n "${PORT_SLOT+set}" && -n "${PORT_SLOT}" ]]; then
    # Validate PORT_SLOT is a non-negative integer
    if ! [[ "${PORT_SLOT}" =~ ^[0-9]+$ ]]; then
        echo "FATAL: PORT_SLOT must be a non-negative integer, got: '${PORT_SLOT}'"
        exit 1
    fi

    # Clear any Layer 1 fallback ports before calculating
    unset CLIENT_SSH_PORT GDB_PORT

    _offset=$(( PORT_SLOT * _PORT_STEP ))

    CLIENT_SSH_PORT=$(( _PORT_BASE_CLIENT_SSH + _offset ))
    GDB_PORT=$(( _PORT_BASE_GDB + _offset ))

    export CLIENT_SSH_PORT GDB_PORT

    echo "[port_calc] PORT_SLOT=${PORT_SLOT} (offset=${_offset})"
    echo "[port_calc]   CLIENT_SSH_PORT = ${CLIENT_SSH_PORT}"
    echo "[port_calc]   GDB_PORT        = ${GDB_PORT}"
else
    # ─── MODE B: Explicit ports (fallback) ────────────────────────────────────
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

    echo "[port_calc] Explicit mode — ports from config"
    echo "[port_calc]   CLIENT_SSH_PORT = ${CLIENT_SSH_PORT}"
    echo "[port_calc]   GDB_PORT        = ${GDB_PORT}"
fi

# ─── Cleanup internal variables ──────────────────────────────────────────────
unset _offset _missing _var

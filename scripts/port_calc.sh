#!/usr/bin/env bash
################################################################################
# File: configs/port_calc.sh
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
_PORT_BASE_SERVER_SSH=2110
_PORT_BASE_GDB=2345
_PORT_STEP=10

# DISTCC base values
_PORT_BASE_DISTCC_GCC_11_MAIN=3652
_PORT_BASE_DISTCC_GCC_11_STATS=3653
_PORT_BASE_DISTCC_GCC_10_MAIN=3642
_PORT_BASE_DISTCC_GCC_10_STATS=3643

# ─── Detect which mode the platform file is using ───────────────────────────
_has_slot=""
_has_explicit=""
_explicit_list=""

if [[ -n "${PORT_SLOT+set}" ]]; then
    _has_slot=1
fi

# Check for explicitly defined port variables
for _var in CLIENT_SSH_PORT SERVER_SSH_PORT GDB_PORT \
            DISTCC_GCC_11_MAIN_PORT DISTCC_GCC_11_STATS_PORT \
            DISTCC_GCC_10_MAIN_PORT DISTCC_GCC_10_STATS_PORT; do
    if [[ -n "${!_var+set}" ]]; then
        _has_explicit=1
        _explicit_list="${_explicit_list}  ${_var}=${!_var}\n"
    fi
done

# ─── Validate: reject mixed mode ────────────────────────────────────────────
if [[ -n "${_has_slot}" && -n "${_has_explicit}" ]]; then
    echo ""
    echo "  =================================================================="
    echo "  FATAL: PORT_SLOT and explicit port variables cannot coexist."
    echo "  =================================================================="
    echo ""
    echo "  PORT_SLOT=${PORT_SLOT} is defined, but these explicit ports"
    echo "  were also found in the platform config:"
    echo ""
    echo -e "${_explicit_list}"
    echo ""
    echo "  Choose ONE mode:"
    echo ""
    echo "  MODE A (recommended) — Keep PORT_SLOT, remove all explicit ports:"
    echo "    PORT_SLOT=\"${PORT_SLOT}\""
    echo "    # Calculated ports:"
    echo "    #   CLIENT_SSH_PORT = $(( _PORT_BASE_CLIENT_SSH + PORT_SLOT * _PORT_STEP ))"
    echo "    #   SERVER_SSH_PORT = $(( _PORT_BASE_SERVER_SSH + PORT_SLOT * _PORT_STEP ))"
    echo "    #   GDB_PORT        = $(( _PORT_BASE_GDB + PORT_SLOT * _PORT_STEP ))"
    echo ""
    echo "  MODE B (explicit)   — Remove PORT_SLOT, keep these explicit ports:"
    echo -e "${_explicit_list}"
    echo ""
    echo "  =================================================================="
    exit 1
fi

# ─── MODE A: Calculate from PORT_SLOT ────────────────────────────────────────
if [[ -n "${_has_slot}" ]]; then
    # Validate PORT_SLOT is a non-negative integer
    if ! [[ "${PORT_SLOT}" =~ ^[0-9]+$ ]]; then
        echo "FATAL: PORT_SLOT must be a non-negative integer, got: '${PORT_SLOT}'"
        exit 1
    fi

    _offset=$(( PORT_SLOT * _PORT_STEP ))
    _d_offset="${DISTCC_PORT_OFFSET:-0}"

    # Validate DISTCC_PORT_OFFSET if set
    if [[ -n "${DISTCC_PORT_OFFSET+set}" ]] && ! [[ "${DISTCC_PORT_OFFSET}" =~ ^[0-9]+$ ]]; then
        echo "FATAL: DISTCC_PORT_OFFSET must be a non-negative integer, got: '${DISTCC_PORT_OFFSET}'"
        exit 1
    fi

    # SSH / GDB ports
    CLIENT_SSH_PORT=$(( _PORT_BASE_CLIENT_SSH + _offset ))
    SERVER_SSH_PORT=$(( _PORT_BASE_SERVER_SSH + _offset ))
    GDB_PORT=$(( _PORT_BASE_GDB + _offset ))

    # DISTCC ports
    DISTCC_GCC_11_MAIN_PORT=$(( _PORT_BASE_DISTCC_GCC_11_MAIN + _d_offset ))
    DISTCC_GCC_11_STATS_PORT=$(( _PORT_BASE_DISTCC_GCC_11_STATS + _d_offset ))
    DISTCC_GCC_10_MAIN_PORT=$(( _PORT_BASE_DISTCC_GCC_10_MAIN + _d_offset ))
    DISTCC_GCC_10_STATS_PORT=$(( _PORT_BASE_DISTCC_GCC_10_STATS + _d_offset ))

    # Export for downstream (docker build-args, compose, etc.)
    export CLIENT_SSH_PORT SERVER_SSH_PORT GDB_PORT
    export DISTCC_GCC_11_MAIN_PORT DISTCC_GCC_11_STATS_PORT
    export DISTCC_GCC_10_MAIN_PORT DISTCC_GCC_10_STATS_PORT

    echo "[port_calc] PORT_SLOT=${PORT_SLOT} (offset=${_offset}, distcc_offset=${_d_offset})"
    echo "[port_calc]   CLIENT_SSH_PORT = ${CLIENT_SSH_PORT}"
    echo "[port_calc]   SERVER_SSH_PORT = ${SERVER_SSH_PORT}"
    echo "[port_calc]   GDB_PORT        = ${GDB_PORT}"
    if [[ "${_d_offset}" -ne 0 ]]; then
        echo "[port_calc]   DISTCC GCC-11   = ${DISTCC_GCC_11_MAIN_PORT} / ${DISTCC_GCC_11_STATS_PORT}"
        echo "[port_calc]   DISTCC GCC-10   = ${DISTCC_GCC_10_MAIN_PORT} / ${DISTCC_GCC_10_STATS_PORT}"
    fi
fi

# ─── MODE B: Explicit ports — validate completeness ─────────────────────────
if [[ -z "${_has_slot}" ]]; then
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

    echo "[port_calc] Explicit mode — ports from platform .env"
    echo "[port_calc]   CLIENT_SSH_PORT = ${CLIENT_SSH_PORT}"
    [[ -n "${SERVER_SSH_PORT+set}" ]] && echo "[port_calc]   SERVER_SSH_PORT = ${SERVER_SSH_PORT}"
    echo "[port_calc]   GDB_PORT        = ${GDB_PORT}"
fi

# ─── Cleanup internal variables ──────────────────────────────────────────────
unset _has_slot _has_explicit _explicit_list _offset _d_offset _missing _var

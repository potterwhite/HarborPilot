#!/bin/bash
# Copyright (c) 2026 Potter White
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

################################################################################
# Module: package.sh
# Description: Handover package creation for HarborPilot
# Functions: 7_package_handover
################################################################################

################################################################################
# 7. Package handover for client delivery
#
# Creates a self-contained tarball with:
#   - configs/1_defaults/         (global defaults)
#   - configs/2_platforms/<name>  (selected platform only)
#   - configs/3_hosts/            (template + README only)
#   - project_handover/           (entrance scripts)
#   - scripts/                    (port_calc.sh + lib/config.sh)
#
# The tarball is placed in the output/ directory (gitignored).
################################################################################
7_package_handover() {
    echo -e "\n=== Packaging Client Handover ==="

    # Use BASE_PLATFORM from the selected platform or host config
    local base_platform="${BASE_PLATFORM}"
    if [ -z "${base_platform}" ]; then
        echo "Error: BASE_PLATFORM not set. Cannot determine which platform to package."
        return 1
    fi

    local platform_env="${TOP_CONFIGS_DIR}/2_platforms/${base_platform}.env"
    if [ ! -f "${platform_env}" ]; then
        echo "Error: Platform config not found: ${platform_env}"
        return 1
    fi

    local version="${PROJECT_VERSION:-unknown}"
    local output_dir="${TOP_ROOT_DIR}/output"
    mkdir -p "${output_dir}"
    local archive_name="${output_dir}/project_handover_${base_platform}_v${version}.tar.gz"

    echo "  Platform : ${base_platform}"
    echo "  Version  : ${version}"
    echo "  Output   : ${archive_name}"
    echo ""

    # ── Assemble archive in a temp staging directory ──────────────────────────
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    local stage="${tmp_dir}/stage"

    mkdir -p "${stage}/project_handover/clientside/volumes"
    mkdir -p "${stage}/configs/1_defaults"
    mkdir -p "${stage}/configs/2_platforms"
    mkdir -p "${stage}/configs/3_hosts"
    mkdir -p "${stage}/scripts/lib"

    # 1. Copy ubuntu client directory
    cp -rL --no-dereference \
        "${HANDOVER_DIR}/clientside/ubuntu" \
        "${stage}/project_handover/clientside/ubuntu" 2>/dev/null || \
    cp -r "${HANDOVER_DIR}/clientside/ubuntu" \
          "${stage}/project_handover/clientside/ubuntu"
    rm -f "${stage}/project_handover/clientside/ubuntu/volumes"
    rm -f "${stage}/project_handover/clientside/ubuntu/docker-compose.yaml"

    # 2. Preserve volumes/.gitkeep placeholder
    touch "${stage}/project_handover/clientside/volumes/.gitkeep"

    # 3. Copy configs/1_defaults (all .env files)
    cp "${TOP_CONFIGS_DIR}/1_defaults/"*.env "${stage}/configs/1_defaults/"

    # 4. Copy only the selected platform config
    cp "${platform_env}" "${stage}/configs/2_platforms/${base_platform}.env"

    # 5. Copy host config template + README (not actual host configs)
    cp "${TOP_CONFIGS_DIR}/3_hosts/TEMPLATE.env.example" "${stage}/configs/3_hosts/"
    cp "${TOP_CONFIGS_DIR}/3_hosts/README.md" "${stage}/configs/3_hosts/"

    # 6. Copy shared scripts
    cp "${TOP_ROOT_DIR}/scripts/port_calc.sh" "${stage}/scripts/"
    cp "${TOP_ROOT_DIR}/scripts/lib/config.sh" "${stage}/scripts/lib/"

    # 7. Copy handover README (Chinese)
    if [ -f "${HANDOVER_DIR}/README_handover.md" ]; then
        cp "${HANDOVER_DIR}/README_handover.md" "${stage}/project_handover/"
    fi

    # ── Create the final tarball ─────────────────────────────────────────────
    tar -czf "${archive_name}" \
        -C "${stage}" \
        "project_handover" \
        "configs" \
        "scripts"

    # Clean up staging area
    rm -rf "${tmp_dir}"

    if [ ! -f "${archive_name}" ]; then
        echo "✗ Error: archive was not created."
        return 1
    fi

    local size
    size="$(du -sh "${archive_name}" | cut -f1)"

    echo ""
    echo "  ╔══════════════════════════════════════════════════════════════════╗"
    echo "  ║              HANDOVER PACKAGE CREATED SUCCESSFULLY              ║"
    echo "  ╠══════════════════════════════════════════════════════════════════╣"
    echo "  ║                                                                  ║"
    printf "  ║  File     : %-51s║\n" "$(basename "${archive_name}")"
    printf "  ║  Size     : %-51s║\n" "${size}"
    printf "  ║  Platform : %-51s║\n" "${base_platform}"
    printf "  ║  Version  : %-51s║\n" "${version}"
    echo "  ║                                                                  ║"
    echo "  ║  Deliver this tarball to the client Ubuntu host, then:          ║"
    echo "  ║                                                                  ║"
    printf "  ║    tar -xzf %-51s║\n" "$(basename "${archive_name}")"
    echo "  ║    cd project_handover/                                         ║"
    echo "  ║    ./clientside/ubuntu/ubuntu_only_entrance.sh start             ║"
    echo "  ║                                                                  ║"
    echo "  ╚══════════════════════════════════════════════════════════════════╝"
    echo ""
}

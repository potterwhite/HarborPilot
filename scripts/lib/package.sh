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
# Creates a self-contained tarball.  Layout after extraction:
#
#   project_handover_<platform>_v<version>/
#   ├── README_handover.md
#   ├── ubuntu_only_entrance.sh -> clientside/ubuntu/ubuntu_only_entrance.sh
#   └── clientside/
#       └── ubuntu/
#           ├── ubuntu_only_entrance.sh
#           ├── scripts/          (handover scripts, self-contained)
#           ├── configs/
#           │   ├── 1_defaults/   (global defaults)
#           │   ├── 2_platforms/  (selected platform only)
#           │   └── 3_hosts/      (template only)
#           └── volumes/
#
# The handover is fully self-contained — no external scripts/lib/config.sh
# or scripts/port_calc.sh are included.  Config loading logic is
# internalised in 01_env_loader.sh.
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
    local pkg_dirname="project_handover_${base_platform}_v${version}"
    local stage="${tmp_dir}/${pkg_dirname}"

    mkdir -p "${stage}/clientside/ubuntu"
    mkdir -p "${stage}/clientside/volumes"
    mkdir -p "${stage}/clientside/ubuntu/configs/1_defaults"
    mkdir -p "${stage}/clientside/ubuntu/configs/2_platforms"
    mkdir -p "${stage}/clientside/ubuntu/configs/3_hosts"

    # 1. Copy ubuntu client scripts
    cp -rL --no-dereference \
        "${HANDOVER_DIR}/clientside/ubuntu" \
        "${stage}/clientside/" 2>/dev/null || \
    cp -r "${HANDOVER_DIR}/clientside/ubuntu" \
          "${stage}/clientside/"
    rm -f "${stage}/clientside/ubuntu/volumes"
    rm -f "${stage}/clientside/ubuntu/docker-compose.yaml"

    # 2. Copy config layers into clientside/ubuntu/configs/
    cp "${TOP_CONFIGS_DIR}/1_defaults/"*.env \
        "${stage}/clientside/ubuntu/configs/1_defaults/"
    cp "${platform_env}" \
        "${stage}/clientside/ubuntu/configs/2_platforms/${base_platform}.env"
    cp "${TOP_CONFIGS_DIR}/3_hosts/TEMPLATE.env.example" \
        "${stage}/clientside/ubuntu/configs/3_hosts/"
    # Remove any stray .md from configs (e.g. host README)
    find "${stage}/clientside/ubuntu/configs" -name "*.md" -delete

    # 3. Volumes placeholder
    touch "${stage}/clientside/volumes/.gitkeep"

    # 4. README at root (first thing teammate sees)
    if [ -f "${HANDOVER_DIR}/README_handover.md" ]; then
        cp "${HANDOVER_DIR}/README_handover.md" "${stage}/"
    fi

    # 5. Symlink: root-level ubuntu_only_entrance.sh
    ln -sf clientside/ubuntu/ubuntu_only_entrance.sh \
        "${stage}/ubuntu_only_entrance.sh"

    # ── Create the final tarball ─────────────────────────────────────────────
    tar -czf "${archive_name}" -C "${tmp_dir}" "${pkg_dirname}"

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
    printf "  ║    cd %-57s║\n" "${pkg_dirname}/"
    echo "  ║    cat README_handover.md                                        ║"
    echo "  ║    ./ubuntu_only_entrance.sh start                               ║"
    echo "  ║                                                                  ║"
    echo "  ╚══════════════════════════════════════════════════════════════════╝"
    echo ""
}

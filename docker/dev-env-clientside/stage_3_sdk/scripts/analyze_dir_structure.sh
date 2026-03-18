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

#!/bin/bash

# File name: analyze_dir_structure.sh
# Purpose: Quick analysis of large SDK directory
# Usage: ./analyze_dir_structure.sh <sdk_path> [max_depth]

# Check parameters
if [ $# -lt 1 ]; then
    echo "Usage: $0 <path_to_sdk> [max_depth]"
    echo "Example: $0 /development/sdk 3"
    exit 1
fi

SDK_PATH="$1"
MAX_DEPTH=${2:-4}  # Default max depth is 4

# Check if directory exists
if [ ! -d "$SDK_PATH" ]; then
    echo "Error: Directory $SDK_PATH does not exist!"
    exit 1
fi

echo "==========================================="
echo "Quick analyzing SDK directory: $SDK_PATH"
echo "Max depth: $MAX_DEPTH"
echo "==========================================="

# Exclude patterns for faster scanning
EXCLUDE_PATTERN="\.git\|\.repo\|\.svn\|node_modules\|\.o$\|\.d$"

echo -e "\n1. Top 20 Largest Files:"
echo "-------------------------------------------"
find "$SDK_PATH" -maxdepth $MAX_DEPTH -type f ! -path "*.git*" ! -path "*.repo*" -exec du -h {} + | \
    sort -rh | \
    head -n 20 | \
    while read size file; do
        echo "$size : $file"
    done

echo -e "\n2. Size by Directory (Top 20):"
echo "-------------------------------------------"
du -h --max-depth=$MAX_DEPTH "$SDK_PATH" | \
    sort -rh | \
    head -n 20

echo -e "\n3. Quick Extension Statistics (Top 20):"
echo "-------------------------------------------"
find "$SDK_PATH" -maxdepth $MAX_DEPTH -type f ! -path "*.git*" ! -path "*.repo*" -printf "%f\n" | \
    awk -F. '{if (NF>1) print $NF}' | \
    sort | \
    uniq -c | \
    sort -nr | \
    head -n 20

echo -e "\n4. Overall Statistics:"
echo "-------------------------------------------"
echo "Total Size: $(du -sh "$SDK_PATH" | cut -f1)"
echo "Files (estimated): $(find "$SDK_PATH" -maxdepth $MAX_DEPTH -type f ! -path "*.git*" ! -path "*.repo*" | wc -l)"
echo "Directories (estimated): $(find "$SDK_PATH" -maxdepth $MAX_DEPTH -type d ! -path "*.git*" ! -path "*.repo*" | wc -l)"

echo -e "\nAnalysis Complete!"
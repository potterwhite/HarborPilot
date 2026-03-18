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
###############################################################################
# Git LFS Tracker
# Description: Track large files and add them to Git LFS
# Usage: ./gitlfs_tracker.sh [size_threshold]
# Default size threshold: 100MB
# Example: ./gitlfs_tracker.sh 100M
# Note: This script will scan the current directory and all subdirectories
#       for files larger than the specified size threshold.
#       It will then generate tracking patterns for these files and add them
#       to the .gitattributes file.
#       Finally, it will prompt the user to commit and push the changes.
#
#
# Created by: @PotterWhite.themanuknowwhom@outlook.com
# Created at: 2024-11-27
# Modified by: @PotterWhite.themanuknowwhom@outlook.com
# Modified at: 2024-11-27
###############################################################################

# Set file size threshold (default 100MB)
SIZE_THRESHOLD=${1:-100M}

echo "Scanning for files larger than $SIZE_THRESHOLD..."

# Create temporary file
TEMP_FILE=$(mktemp)

# Find large files and record their path patterns
find . -type f -size "+$SIZE_THRESHOLD" | while read -r file; do
    # Ignore .git directory
    if [[ $file == ./.git/* ]]; then
        continue
    fi

    # Get directory path
    dir=$(dirname "$file")
    # Get file extension
    ext="${file##*.}"

    # Generate tracking patterns
    # 1. Specific extension in specific directory
    echo "${dir#./}/*.$ext"
    # 2. All large files with this extension
    echo "*.$ext"

done | sort -u > "$TEMP_FILE"

# Check current LFS tracking configuration
if [ -f .gitattributes ]; then
    echo "Current LFS tracking patterns:"
    grep "filter=lfs" .gitattributes
fi

# Add new tracking patterns
while read -r pattern; do
    if ! grep -q "^$pattern filter=lfs" .gitattributes 2>/dev/null; then
        echo "Adding new pattern: $pattern"
        git lfs track "$pattern"
    fi
done < "$TEMP_FILE"

# Clean up temporary file
rm "$TEMP_FILE"

# Show updated configuration
echo -e "\nUpdated LFS tracking patterns:"
git lfs track

# Prompt for next steps
echo -e "\nTo apply changes to repository:"
echo "1.    git add ."
echo "2.    git commit -a"
echo "3.    git lfs migrate import --everything --above=${SIZE_THRESHOLD}"
echo "   or git lfs migrate import --include-ref=refs/heads/\${YOUR_BRANCH_NAME} --above=${SIZE_THRESHOLD}"
echo "4.    git push origin --force"

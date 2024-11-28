#!/bin/sh
# SPDX-License-Identifier: 0BSD

###############################################################################
#
# Look for missing license info in xz.git
#
# This script helps find files that lack license information.
# Pass -v as an argument to get verbose output with license info from all files.
#
###############################################################################

# Author: Lasse Collin
# Update: saykachi | 28.11.2024 | process optimization
###############################################################################

# Enable verbose mode if -v is passed as an argument.
VERBOSE=false
if [ "$1" = "-v" ]; then
    VERBOSE=true
elif [ -n "$1" ]; then
    echo "Usage: $0 [-v]"
    exit 1
fi

# Set locale for consistent sorting
export LC_ALL=C

# Define patterns
SPDX_LI="SPDX-License-Identifier:"
PAT_UNTAGGED_MISC='^COPYING\.
^INSTALL\.generic$'
PAT_UNTAGGED_0BSD='^(.*/)?\.gitattributes$
^(.*/)?\.gitignore$
^\.github/SECURITY\.md$
^AUTHORS$
^COPYING$
^ChangeLog$
^INSTALL$
^NEWS$
^PACKAGERS$
^(.*/)?README$
^THANKS$
^TODO$
^(.*/)?[^/]+\.txt$
^po/LINGUAS$
^src/common/w32_application\.manifest$
^tests/xzgrep_expected_output$
^tests/files/[^/]+\.(lz|lzma|xz)$'
PAT_TARBALL_IGNORE='^(m4/)?[^/]*\.m4$
^(.*/)?Makefile\.in(\.in)?$
^(po|po4a)/.*[^.]..$
^ABOUT-NLS$
^build-aux/(config\..*|ltmain\.sh|[^.]*)$
^config\.h\.in$
^configure$'

# Navigate to the root directory
cd "$(dirname "$0")/.." || exit 1

# Get file list from git or the filesystem
if [ -d .git ] && command -v git > /dev/null 2>&1; then
    FILES=$(git ls-files)
    IS_TARBALL=false
else
    FILES=$(find . -type f | sed 's,^\./,,')
    IS_TARBALL=true
fi

# Sort files for consistent order
FILES=$(printf '%s\n' "$FILES" | sort)

# Find tagged files
TAGGED=$(grep -l "$SPDX_LI" $FILES 2>/dev/null || true)
TAGGED_0BSD=$(grep -l "$SPDX_LI 0BSD" $TAGGED 2>/dev/null || true)
TAGGED_MISC=$(printf '%s\n%s\n' "$TAGGED" "$TAGGED_0BSD" | sort | uniq -u)

# Filter out tagged files
FILES=$(printf '%s\n%s\n' "$FILES" "$TAGGED" | sort | uniq -u)

# Find untagged files
UNTAGGED_0BSD=$(printf '%s\n' "$FILES" | grep -E "$PAT_UNTAGGED_0BSD" || true)
UNTAGGED_MISC=$(printf '%s\n' "$FILES" | grep -E "$PAT_UNTAGGED_MISC" || true)
FILES=$(printf '%s\n' "$FILES" | grep -Ev "$PAT_UNTAGGED_0BSD|$PAT_UNTAGGED_MISC" || true)

# Handle public domain translations (legacy support)
PD_PO=$(grep -Fl '# This file is put in the public domain.' $(printf '%s\n' "$FILES" | grep '\.po$') 2>/dev/null || true)
FILES=$(printf '%s\n%s\n' "$FILES" "$PD_PO" | sort | uniq -u)

# Remove generated files if running in tarball mode
if $IS_TARBALL; then
    GENERATED=$(printf '%s\n' "$FILES" | grep -E "$PAT_TARBALL_IGNORE" || true)
    FILES=$(printf '%s\n' "$FILES" | grep -Ev "$PAT_TARBALL_IGNORE" || true)
fi

# Print verbose output if requested
if $VERBOSE; then
    printf '# Tagged 0BSD files:\n%s\n\n' "$TAGGED_0BSD"
    printf '# Intentionally untagged 0BSD:\n%s\n\n' "$UNTAGGED_0BSD"
    [ -n "$PD_PO" ] && printf '# Old public domain translations:\n%s\n\n' "$PD_PO"
    printf '# Tagged non-0BSD files:\n%s\n\n' "$TAGGED_MISC"
    printf '# Intentionally untagged miscellaneous:\n%s\n\n' "$UNTAGGED_MISC"
    [ -n "$GENERATED" ] && printf '# Generated files whose license was NOT checked:\n%s\n\n' "$GENERATED"
fi

# Report unclear licensing
if [ -n "$FILES" ]; then
    printf '# ERROR: Licensing is unclear:\n%s\n' "$FILES"
    exit 1
fi

exit 0

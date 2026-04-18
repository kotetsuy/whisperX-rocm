#!/bin/bash
# Apply all ROCm compatibility patches for whisperX
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
for script in "$DIR"/0*.sh; do
    echo "==> Running $script"
    bash "$script"
done
echo "All patches applied."

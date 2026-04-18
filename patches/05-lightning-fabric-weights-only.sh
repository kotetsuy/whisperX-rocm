#!/bin/bash
# Fix lightning_fabric cloud_io.py: set weights_only=False when None to avoid PyTorch error
set -e
SITE=$(python3 -c "import sysconfig; print(sysconfig.get_paths()['purelib'])")
FILE="$SITE/lightning_fabric/utilities/cloud_io.py"
sed -i 's/        return torch\.load(/        if weights_only is None:\n            weights_only = False\n        return torch.load(/' "$FILE"
echo "Patch 05 applied: $FILE"

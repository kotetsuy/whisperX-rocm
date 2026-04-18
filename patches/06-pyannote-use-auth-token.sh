#!/bin/bash
# Fix pyannote use_auth_token → token (Hugging Face API change)
set -e
SITE=$(python3 -c "import sysconfig; print(sysconfig.get_paths()['purelib'])")
sed -i 's/use_auth_token=use_auth_token/token=use_auth_token/g' \
    "$SITE/pyannote/audio/core/pipeline.py" \
    "$SITE/pyannote/audio/core/model.py"
echo "Patch 06 applied: pyannote/audio/core/pipeline.py and model.py"

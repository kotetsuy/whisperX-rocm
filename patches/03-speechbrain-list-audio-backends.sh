#!/bin/bash
# Fix speechbrain list_audio_backends to hardcode ["soundfile"]
set -e
SITE=$(python3 -c "import sysconfig; print(sysconfig.get_paths()['purelib'])")
FILE="$SITE/speechbrain/utils/torch_audio_backend.py"
sed -i 's/torchaudio\.list_audio_backends()/["soundfile"]/g' "$FILE"
echo "Patch 03 applied: $FILE"

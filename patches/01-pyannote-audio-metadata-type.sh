#!/bin/bash
# Fix pyannote AudioMetaData return type annotation (torchaudio.AudioMetaData → Any)
set -e
SITE=$(python3 -c "import sysconfig; print(sysconfig.get_paths()['purelib'])")
IO="$SITE/pyannote/audio/core/io.py"
sed -i '1s/^/from typing import Any\n/' "$IO"
sed -i 's/) -> torchaudio\.AudioMetaData:/) -> Any:/' "$IO"
sed -i 's/info : torchaudio\.AudioMetaData/info : Any/' "$IO"
echo "Patch 01 applied: $IO"

#!/bin/bash
# Fix pyannote list_audio_backends to hardcode "soundfile"
set -e
SITE=$(python3 -c "import sysconfig; print(sysconfig.get_paths()['purelib'])")
IO="$SITE/pyannote/audio/core/io.py"
python3 << 'EOF'
import sysconfig
filepath = sysconfig.get_paths()['purelib'] + "/pyannote/audio/core/io.py"
with open(filepath, 'r') as f:
    content = f.read()
old = "        backends = (\n            torchaudio.list_audio_backends()\n        )  # e.g ['ffmpeg', 'soundfile', 'sox']\n        backend = \"soundfile\" if \"soundfile\" in backends else backends[0]"
new = '        backend = "soundfile"'
content = content.replace(old, new)
old2 = "            backends = (\n                torchaudio.list_audio_backends()\n            )  # e.g ['ffmpeg', 'soundfile', 'sox']\n            backend = \"soundfile\" if \"soundfile\" in backends else backends[0]"
new2 = '            backend = "soundfile"'
content = content.replace(old2, new2)
with open(filepath, 'w') as f:
    f.write(content)
print("Patch 02 applied:", filepath)
EOF

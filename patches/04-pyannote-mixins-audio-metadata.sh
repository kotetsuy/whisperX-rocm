#!/bin/bash
# Fix pyannote mixins.py: replace torchaudio.AudioMetaData import with SimpleNamespace shim
set -e
python3 << 'EOF'
import sysconfig
filepath = sysconfig.get_paths()['purelib'] + "/pyannote/audio/tasks/segmentation/mixins.py"
with open(filepath, 'r') as f:
    content = f.read()
content = content.replace(
    'from torchaudio import AudioMetaData',
    'from types import SimpleNamespace\ndef AudioMetaData(**kwargs): return SimpleNamespace(**kwargs)'
)
with open(filepath, 'w') as f:
    f.write(content)
print("Patch 04 applied:", filepath)
EOF

#!/usr/bin/env bash
# WhisperX + ROCm の実行環境設定 (2026-08-05, Ubuntu 26.04 + ROCm 7.14 で再構築)
#   使い方:  source env-rocm.sh
#
# なぜ必要か:
#  - torch (2.8.0+rocm7.12.0) は **自前の ROCm 7.12 を wheel に同梱** している。
#    システムの /opt/rocm (7.14) を LD_LIBRARY_PATH に混ぜると libhipblaslt が
#    undefined symbol (rocRoller) で落ちる。**/opt/rocm は混ぜないこと。**
#  - ctranslate2 の _ext は RUNPATH が /usr/local/lib に焼き込まれているので、
#    libctranslate2 本体は /usr/local/lib のものが使われる（要 sudo make install）。
#  - libomp.so だけはどちらにも無いので、torch 同梱の _rocm_sdk_core から通す。

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV="$HERE/.venv"
SP="$(ls -d "$VENV"/lib/python3.*/site-packages 2>/dev/null | head -1)"

export LD_LIBRARY_PATH="$SP/_rocm_sdk_core/lib/llvm/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export HIP_VISIBLE_DEVICES=0
# HSA_OVERRIDE_GFX_VERSION は設定しない (gfx1151 ネイティブビルドのため)

# venv を有効化
# shellcheck disable=SC1091
source "$VENV/bin/activate"

echo "WhisperX ROCm 環境: python=$(python -V 2>&1) venv=$VENV"
echo "注意: ctranslate2 は torch より後に import すること"

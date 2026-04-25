# WhisperX ROCm7.2.1 セットアップガイド（日本語）

AMD GPU（ROCm）環境でWhisperXを動作させるための手順まとめです。

## 動作確認環境

- **OS**: Ubuntu 24.04.4 LTS
- **GPU**: AMD RYZEN AI MAX+ 395 w/ Radeon 8060S（gfx1151、48GB VRAM）
- **ROCm**: 7.2.1
- **Python**: 3.12.3

## 1. リポジトリのclone

GitHubで [kotetsuy/whisperX-rocm](https://github.com/kotetsuy/whisperX-rocm) をforkし、cloneします。

```bash
mkdir -p ~/AIzunda && cd ~/AIzunda
git clone -b rocm-nucbox-patch git@github.com:kotetsuy/whisperX-rocm.git ~/AIzunda/whisperX-rocm
```

## 2. PyTorch（ROCm版）のインストール

AMD公式リポジトリからROCm 7.2.1対応wheelを取得してインストールします。

```bash
# wheelをダウンロード
mkdir -p ~/AIzunda/wheels && cd ~/AIzunda/wheels
wget "https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2.1/torch-2.9.1%2Brocm7.2.1.lw.gitff65f5bc-cp312-cp312-linux_x86_64.whl"
wget "https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2.1/torchvision-0.24.0%2Brocm7.2.1.gitb919bd0c-cp312-cp312-linux_x86_64.whl"
wget "https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2.1/torchaudio-2.9.0%2Brocm7.2.1.gite3c6ee2b-cp312-cp312-linux_x86_64.whl"
wget "https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2.1/triton-3.5.1%2Brocm7.2.1.gita272dfa8-cp312-cp312-linux_x86_64.whl"

# インストール
pip3 install --break-system-packages \
  torch-2.9.1+rocm7.2.1.lw.gitff65f5bc-cp312-cp312-linux_x86_64.whl \
  torchvision-0.24.0+rocm7.2.1.gitb919bd0c-cp312-cp312-linux_x86_64.whl \
  torchaudio-2.9.0+rocm7.2.1.gite3c6ee2b-cp312-cp312-linux_x86_64.whl \
  triton-3.5.1+rocm7.2.1.gita272dfa8-cp312-cp312-linux_x86_64.whl
```

動作確認：

```bash
HSA_OVERRIDE_GFX_VERSION=11.5.1 python3 -c \
  "import torch; print(torch.__version__); print(torch.cuda.is_available())"
# 期待値: 2.9.1+rocm7.2.1... / True
```

## 3. CTranslate2（ROCm版）のビルド

[paralin/ctranslate2-rocm](https://github.com/paralin/ctranslate2-rocm) をソースからビルドします。

```bash
cd ~/AIzunda
git clone https://github.com/paralin/ctranslate2-rocm.git ~/AIzunda/ctranslate2-rocm
cd ~/AIzunda/ctranslate2-rocm
git submodule update --init --recursive
mkdir -p build && cd build

export HSA_OVERRIDE_GFX_VERSION=11.5.1
export AMDGPU_TARGETS=gfx1151

cmake .. -DWITH_HIP=ON -DWITH_MKL=OFF -DWITH_OPENBLAS=ON \
  -DCMAKE_HIP_ARCHITECTURES=gfx1151 -DCMAKE_BUILD_TYPE=Release \
  -DOPENMP_RUNTIME=COMP \
  -DCMAKE_HIP_COMPILER=/opt/rocm/lib/llvm/bin/clang++ \
  -DCMAKE_CXX_COMPILER=/opt/rocm/lib/llvm/bin/clang++ \
  -DCMAKE_C_COMPILER=/opt/rocm/lib/llvm/bin/clang \
  -DCMAKE_PREFIX_PATH=/opt/rocm -DBUILD_CLI=OFF

make -j$(nproc) && sudo make install
```

Pythonバインディングのインストール：

```bash
cd ~/AIzunda/whisperX-rocm
uv venv --python 3.12
export CTRANSLATE2_ROOT=/usr/local
uv pip install --reinstall pybind11 ~/AIzunda/ctranslate2-rocm/python
```

## 4. WhisperXのインストール

```bash
cd ~/AIzunda/whisperX-rocm
uv pip install -e .
```

## 5. 依存パッケージへのパッチ適用

インストール後、互換性パッチを適用します（`patches/` ディレクトリ内のスクリプトを使用）。

```bash
cd ~/AIzunda/whisperX-rocm
bash patches/apply_all.sh
```

### パッチ一覧

| ファイル | 内容 |
|---|---|
| `01-pyannote-audio-metadata-type.sh` | pyannote `io.py` の型アノテーションを `Any` に変更 |
| `02-pyannote-list-audio-backends.sh` | pyannote `io.py` のオーディオバックエンドを `soundfile` に固定 |
| `03-speechbrain-list-audio-backends.sh` | speechbrain のオーディオバックエンドを `soundfile` に固定 |
| `04-pyannote-mixins-audio-metadata.sh` | pyannote `mixins.py` の `AudioMetaData` を `SimpleNamespace` で代替 |
| `05-lightning-fabric-weights-only.sh` | `lightning_fabric` の `weights_only` エラーを修正 |
| `06-pyannote-use-auth-token.sh` | pyannote の `use_auth_token` → `token` に移行 |

## 6. 実行

```bash
export HSA_OVERRIDE_GFX_VERSION=11.5.1
export ROCM_PATH=/opt/rocm
export HIP_VISIBLE_DEVICES=0
export LD_LIBRARY_PATH=/usr/local/lib:/opt/rocm/lib:/opt/rocm/lib/llvm/lib:$LD_LIBRARY_PATH

# 基本の文字起こし
whisperx audio.wav --model small --language ja --device cuda --compute_type float16

# 話者区別あり
whisperx audio.wav --model large-v2 --language ja --compute_type float32 --diarize
```

## GPU Architecture 対応表

| GPU | アーキテクチャ | HSA_OVERRIDE_GFX_VERSION |
|---|---|---|
| RYZEN AI MAX+ 395 (Radeon 8060S) | gfx1151 | 11.5.1 |
| RX 7900 XTX/XT | gfx1100 | 11.0.0 |
| RX 7800/7700 XT | gfx1101 | 11.0.1 |
| RX 7600 | gfx1102 | 11.0.2 |
| RX 6900/6800/6700 | gfx1030 | 10.3.0 |

## 参考

- [Qiita: WhisperX ROCm 7.2.0 インストール手順](https://qiita.com/kotetsu_yama/items/1dbec3d895217d3dc5c4)
- [paralin/whisperX-rocm](https://github.com/paralin/whisperX-rocm)
- [paralin/ctranslate2-rocm](https://github.com/paralin/ctranslate2-rocm)

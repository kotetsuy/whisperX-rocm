# WhisperX ROCm7.2.1 セットアップガイド（修正版）

AMD GPU（ROCm）環境でWhisperXを動作させるための手順です。  
**重要**: インストール順序を間違えるとROCm版PyTorchがPyPI版に上書きされます。以下の順序を守ってください。

## 動作確認環境

- **OS**: Ubuntu 24.04.4 LTS
- **GPU**: AMD RYZEN AI MAX+ 395 w/ Radeon 8060S（gfx1151、48GB VRAM）
- **ROCm**: 7.2.1
- **Python**: 3.12.3

---

## Step 1: リポジトリのclone

```bash
mkdir -p ~/AIzunda && cd ~/AIzunda
git clone -b rocm-nucbox-patch git@github.com:kotetsuy/whisperX-rocm.git ~/AIzunda/whisperX-rocm
```

## Step 2: PyTorch（ROCm版）wheelのダウンロード

```bash
mkdir -p ~/AIzunda/wheels && cd ~/AIzunda/wheels
wget "https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2.1/torch-2.9.1%2Brocm7.2.1.lw.gitff65f5bc-cp312-cp312-linux_x86_64.whl"
wget "https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2.1/torchvision-0.24.0%2Brocm7.2.1.gitb919bd0c-cp312-cp312-linux_x86_64.whl"
wget "https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2.1/torchaudio-2.9.0%2Brocm7.2.1.gite3c6ee2b-cp312-cp312-linux_x86_64.whl"
wget "https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2.1/triton-3.5.1%2Brocm7.2.1.gita272dfa8-cp312-cp312-linux_x86_64.whl"
```

## Step 3: CTranslate2（ROCm版）のビルド

```bash
cd ~/AIzunda
git clone https://github.com/paralin/ctranslate2-rocm.git ~/AIzunda/ctranslate2-rocm
cd ~/AIzunda/ctranslate2-rocm
git submodule update --init --recursive
mkdir -p build && cd build

# clang22対応パッチ（trailing comma除去）
sed -i 's/model\.use_flash_attention(),$/model.use_flash_attention()/' \
  ~/AIzunda/ctranslate2-rocm/src/layers/whisper.cc
sed -i 's/_use_flash_attention,$/_use_flash_attention/' \
  ~/AIzunda/ctranslate2-rocm/src/layers/transformer.cc

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

## Step 4: venv作成

```bash
cd ~/AIzunda/whisperX-rocm
uv venv --python 3.12
source .venv/bin/activate
```

## Step 5: 依存パッケージのインストール（PyTorchより先に）

WhisperXの依存パッケージをインストールします。この時点ではPyPI版のtorchが入りますが、次のステップで上書きします。

```bash
uv pip install -e .
```

## Step 6: ROCm版PyTorchで上書き（最重要）

PyPI版torchをROCm版で強制的に上書きします。`--force-reinstall --no-deps` により、依存パッケージに影響を与えずtorch関連だけ差し替えます。

```bash
uv pip install --force-reinstall --no-deps \
  ~/AIzunda/wheels/torch-2.9.1+rocm7.2.1.lw.gitff65f5bc-cp312-cp312-linux_x86_64.whl \
  ~/AIzunda/wheels/torchvision-0.24.0+rocm7.2.1.gitb919bd0c-cp312-cp312-linux_x86_64.whl \
  ~/AIzunda/wheels/torchaudio-2.9.0+rocm7.2.1.gite3c6ee2b-cp312-cp312-linux_x86_64.whl \
  ~/AIzunda/wheels/triton-3.5.1+rocm7.2.1.gita272dfa8-cp312-cp312-linux_x86_64.whl
```

### 動作確認

```bash
HSA_OVERRIDE_GFX_VERSION=11.5.1 python3 -c \
  "import torch; print(torch.__version__); print(torch.cuda.is_available())"
# 期待値: 2.9.1+rocm7.2.1.gitff65f5bc / True
```

## Step 7: CTranslate2 Pythonバインディングのインストール

```bash
export CTRANSLATE2_ROOT=/usr/local
uv pip install --reinstall pybind11 ~/AIzunda/ctranslate2-rocm/python
```

## Step 8: パッチ適用

依存パッケージがすべて `.venv` 内にインストールされた状態でパッチを適用します。

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

## Step 9: 実行

```bash
export HSA_OVERRIDE_GFX_VERSION=11.5.1
export ROCM_PATH=/opt/rocm
export HIP_VISIBLE_DEVICES=0
export LD_LIBRARY_PATH=/usr/local/lib:/opt/rocm/lib:/opt/rocm/lib/llvm/lib:$LD_LIBRARY_PATH

whisperx audio.wav --model small --language ja --device cuda --compute_type float16
```

---

## インストール順序まとめ（ハマりポイント）

```
Step 4: venv作成
Step 5: uv pip install -e .          ← 依存パッケージ込み（PyPI版torchが入る）
Step 6: ROCm版wheelで上書き           ← --force-reinstall --no-deps で安全に差し替え
Step 7: ctranslate2 Pythonバインディング
Step 8: パッチ適用                     ← 依存パッケージが入った後に実行
```

**NG パターン（元の手順）:**
```
uv pip install -e . --no-deps  ← 依存が入らずパッチ対象ファイルが存在しない
bash patches/apply_all.sh      ← エラー: そのようなファイルやディレクトリはありません
```

## 参考

- [Qiita: WhisperX ROCm 7.2.0 インストール手順](https://qiita.com/kotetsu_yama/items/1dbec3d895217d3dc5c4)
- [paralin/whisperX-rocm](https://github.com/paralin/whisperX-rocm)
- [paralin/ctranslate2-rocm](https://github.com/paralin/ctranslate2-rocm)

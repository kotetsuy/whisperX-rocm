# WhisperX ROCm Fork

This is a fork of [m-bain/whisperX](https://github.com/m-bain/whisperX) configured for AMD ROCm GPUs.

## Tested Configuration

- **OS**: Debian Sid (trixie/forky)
- **GPU**: AMD Radeon RX 7700 XT (gfx1101, 12GB VRAM)
- **ROCm**: 7.1.1
- **Python**: 3.10
- **PyTorch**: 2.11.0+rocm7.0 (nightly)
- **CTranslate2**: 4.6.2 (ROCm build from [paralin/ctranslate2-rocm](https://github.com/paralin/ctranslate2-rocm))

## Prerequisites

1. ROCm 7.1+ installed at `/opt/rocm`
2. CTranslate2 built with ROCm support (see [paralin/ctranslate2-rocm](https://github.com/paralin/ctranslate2-rocm))

## Installation (Debian Sid)

### 1. Clone and setup

```bash
git clone https://github.com/paralin/whisperX-rocm.git ~/whisperx
cd ~/whisperx
git checkout rocm
```

### 2. Create venv with uv

```bash
uv venv
uv pip install -e .
```

### 3. Install ROCm PyTorch

```bash
uv pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/rocm7.0
```

### 4. Install ROCm CTranslate2

First build CTranslate2 with ROCm support (see [paralin/ctranslate2-rocm](https://github.com/paralin/ctranslate2-rocm)), then:

```bash
# Remove PyPI ctranslate2 (has CUDA binaries)
rm -rf .venv/lib/python3.10/site-packages/ctranslate2*

# Install ROCm build
export CTRANSLATE2_ROOT=/usr/local
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
uv pip install --reinstall pybind11 ~/ctranslate2/python
```

## Environment Variables

These must be set before running whisperx:

```bash
export HSA_OVERRIDE_GFX_VERSION=11.0.1  # for gfx1101
export AMDGPU_TARGETS=gfx1101
export ROCM_PATH=/opt/rocm
export HIP_VISIBLE_DEVICES=0
export ROCR_VISIBLE_DEVICES=0
export LD_LIBRARY_PATH=/usr/local/lib:/opt/rocm/lib:/opt/rocm/lib/llvm/lib:$LD_LIBRARY_PATH
```

## Usage

```bash
# Set environment (add to ~/.bashrc for convenience)
export HSA_OVERRIDE_GFX_VERSION=11.0.1
export ROCM_PATH=/opt/rocm
export HIP_VISIBLE_DEVICES=0
export LD_LIBRARY_PATH=/usr/local/lib:/opt/rocm/lib:/opt/rocm/lib/llvm/lib:$LD_LIBRARY_PATH

cd ~/whisperx
uv run whisperx audio.wav \
  --language en \
  --model large-v3 \
  --compute_type float16 \
  --device cuda \
  --batch_size 8 \
  --vad_method silero \
  --output_dir ./output \
  --output_format all
```

Note: We use `--device cuda` because ROCm's HIP layer translates CUDA API calls to AMD GPU.

## Verify Installation

```bash
# Check PyTorch sees the GPU
python -c "import torch; print(CUDA:, torch.cuda.is_available()); print(Device:, torch.cuda.get_device_name(0))"

# Check CTranslate2
python -c "import ctranslate2; print(ctranslate2.__version__); print(ctranslate2.get_supported_compute_types(cuda))"
```

Expected output:
```
CUDA: True
Device: AMD Radeon RX 7700 XT

4.6.2
{int8_float16, int8_bfloat16, bfloat16, int8_float32, int8, float16, float32}
```

## GPU Architecture

Set `HSA_OVERRIDE_GFX_VERSION` based on your GPU:

| GPU | Architecture | HSA_OVERRIDE_GFX_VERSION |
|-----|--------------|--------------------------|
| RX 7900 XTX/XT | gfx1100 | 11.0.0 |
| RX 7800 XT | gfx1101 | 11.0.1 |
| RX 7700 XT | gfx1101 | 11.0.1 |
| RX 7600 | gfx1102 | 11.0.2 |
| RX 6900/6800/6700 | gfx1030 | 10.3.0 |
| RX 6600 | gfx1032 | 10.3.2 |

## Upstream

- Original: [m-bain/whisperX](https://github.com/m-bain/whisperX)

#!/usr/bin/env bash
set -euo pipefail

module load LUMI/22.08 partition/G
module load PyTorch/2.6.0-rocm-6.2.4-python-3.12-singularity-20250404

# ------------------------------------------------------------------
# 0.  Resolve the host-side path and ensure it is writable
# ------------------------------------------------------------------
ROOT="$CONTAINERROOT"               # set by the module
if [[ -z "$ROOT" ]]; then
    echo "FATAL: CONTAINERROOT is not defined; did the module load fail?" >&2
    exit 1
fi

echo "+ Using CONTAINERROOT = $ROOT"

rm -f  "$ROOT/user-software.squashfs"
rm -rf "$ROOT/user-software"
mkdir -p "$ROOT/user-software"
chmod 700 "$ROOT/user-software"

# ------------------------------------------------------------------
# 1.  Build everything inside the container
# ------------------------------------------------------------------
start-shell -c "bash -eu <<'INSIDE'
    source /opt/miniconda3/etc/profile.d/conda.sh
    conda activate pytorch

    # Create venv only if missing (directory now writable!)
    if [ ! -d /user-software/venv/pytorch ]; then
        python3 -m venv --system-site-packages /user-software/venv/pytorch
    fi
    source /user-software/venv/pytorch/bin/activate
    pip uninstall -y vllm
    pip install -U pip 'setuptools>=79' wheel setuptools_scm ninja cmake pybind11 'importlib-metadata<=8.0.0'

    # 1. Downgrade CMake (<4) so hiprtc-config.cmake is happy
    pip uninstall -y cmake
    pip install 'cmake<4.0.0'

    # 2. Tell vLLM we really want an ROCm build
    export VLLM_TARGET_DEVICE='rocm'
    #export CMAKE_BUILD_PARALLEL_LEVEL=64
    export MAX_JOBS=64                  # limits Ninja -j (important for triton build)
    export CFLAGS="-Wno-error=deprecated-declarations"
    export CXXFLAGS="-Wno-error=deprecated-declarations"

    # optional: if you still prefer the CMake variable
    export CMAKE_BUILD_PARALLEL_LEVEL=64

    rm -rf /tmp/triton
    git clone https://github.com/OpenAI/triton.git /tmp/triton
    cd /tmp/triton && git checkout e5be006 && cd python && pip install . && cd /

    pip install 'importlib-metadata<=8.0.0'
    # rm -rf /tmp/vllm
    # git clone https://github.com/vllm-project/vllm.git /tmp/vllm
    # cd /tmp/vllm
    git clone https://github.com/vllm-project/vllm.git /user-software/vllm
    cd /user-software/vllm
    pip install -r requirements/rocm.txt
    pip install 'importlib-metadata<=8.0.0'
    export PYTORCH_ROCM_ARCH='gfx90a'
    python3 setup.py develop  --no-deps
INSIDE"

# 2.  Pack overlay
make-squashfs
echo "+ SUCCESS – reload the PyTorch module and submit jobs."
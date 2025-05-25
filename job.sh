#!/bin/bash
#SBATCH --account=project_xxxxxxxxxx
#SBATCH --partition=small-g
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=56
#SBATCH --gpus-per-node=8
#SBATCH --mem=480G
#SBATCH --time=2-00:00:00

export EBU_USER_PREFIX=/flash/project_xxxxxxxxxx/username/EasyBuild

echo starting load

EBU_USER_PREFIX=/flash/project_xxxxxxxxxx/username/EasyBuild module load LUMI/22.08 partition/G
EBU_USER_PREFIX=/flash/project_xxxxxxxxxx/username/EasyBuild module load PyTorch/2.6.0-rocm-6.2.4-python-3.12-singularity-20250404

echo finished load

export HF_HOME=/scratch/project_xxxxxxxxxx/username/hf-cache
export TRANSFORMERS_CACHE=/scratch/project_xxxxxxxxxx/username/hf-cache
export HF_DATASETS_CACHE=/scratch/project_xxxxxxxxxx/username/hf-cache


$WITH_VENV

export PYTORCH_ROCM_ARCH=gfx90a
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
export VLLM_ALLOW_LONG_MAX_MODEL_LEN=1

export SCRATCH=/scratch/project_xxxxxxxxxx/username/vllm-logs

MODEL="Qwen/Qwen3-32B"
CTX=32768; TP=8; PP=1; GPU_MEM=0.95

LOG=$SCRATCH/vllm-${SLURM_JOB_ID}.log

echo starting python
echo logging to $LOG

python -m vllm.entrypoints.openai.api_server \
       --model $MODEL \
       --tensor-parallel-size $TP \
       --pipeline-parallel-size $PP \
       --enable-reasoning --reasoning-parser deepseek_r1 \
       --gpu-memory-utilization $GPU_MEM \
       --max-model-len $CTX \
       --enforce-eager          \
       > $LOG 2>&1 &
SERVER=$!

until curl -sf http://localhost:8000/v1/models >/dev/null ; do sleep 5 ; done
python run_llm_api_multiple.py --max-context-length $CTX
kill $SERVER
cat  $LOG


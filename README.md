# Guide to build the latest version of VLLM using the PyTorch-2.6.0-rocm-6.2.4-python-3.12-singularity-20250404 container 

Since the ROCm version available on LUMI is extremely outdated and doesn't support running the latest vLLM version (and therefore the latest reasoning LLMs). Here is a guid on how to build the latest vLLM version with the singularity image `PyTorch-2.6.0-rocm-6.2.4-python-3.12-singularity-2025040` which is the most recent available image that includes a ROCm version that is still compatible with the latest vLLM.

Follow these steps to get it running:

1. Create the easybuild image

```bash 1_init.sh```

2. Build vLLM and triton flash attention using this image

```bash 2_build_image.sh```

3. Submit the job

```sbatch job.sh```


4. Add you python file to make the requests.

At the bottom of the `job.sh` file you can find the invocation of a python file. This should be you own python tool that makes the requests to vLLM. Place this file in the folder of job.sh and update the name appropriately in the file.

## Important:
Update your project number and username appropriately in the path of the scripts:
1. Replace `project_xxxxxxxxxx` with your project number
2. Replace `username` with your username folder inside your project folders
3. The final line in jobs.sh launches the python script that makes the requests against vLLM. Update the name of this file to your python file that makes the requests. In it set the OPENAI_API_BASE to `http://localhost:8000/v1` to make the requests against vLLM.

## Note:
1. As you see in the commands we set the EBU_USER_PREFIX so that easybuild creates the image in our project folder on /flash instead of in the limited size user folder.
2. We ask vLLM to cache the models on /scratch/ 
3. The example job script deploys the Qwen/Qwen3-32B model with reasoning mode enabled using vLLM and tensor-parallel-size= 8 and pipeline-parallel-size=1 which seems to yield the highest throughput (~ 650 tps at 50 concurrent requests)
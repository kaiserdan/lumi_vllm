# Guide to build the latest version of VLLM using the PyTorch-2.6.0-rocm-6.2.4-python-3.12-singularity-20250404 container 

1. Create the easybuild image

```bash 1_init.sh```

2. Build vLLM and triton flash attention using this image

```bash 2_build_image.sh```

3. Submit the job

```sbatch job.sh```

## Important:
Update your project number and username appropriately in the path of the scripts:
1. Replace `project_xxxxxxxxxx` with your project number
2. Replace `username` with your username folder inside your project folders
3. The final line in jobs.sh launches the python script that makes the requests against vLLM. Update the name of this file to your python file that makes the requests. In it set the OPENAI_API_BASE to `http://localhost:8000/v1` to make the requests against vLLM.

## Note:
1. As you see in the commands we set the EBU_USER_PREFIX so that easybuild creates the image in our project folder on /flash instead of in the limited size user folder.
2. We ask vLLM to cache the models on /scratch/ 
3. The example job script deploys the Qwen/Qwen3-32B model with reasoning mode enabled using vLLM and tensor-parallel-size= 8 and pipeline-parallel-size=1 which seems to yield the highest throughput (~ 650 tps at 50 concurrent requests)
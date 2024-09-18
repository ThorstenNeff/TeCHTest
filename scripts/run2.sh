set -x
export INPUT_FILE=$1;
export EXP_DIR=$2;
export SUBJECT_NAME=$(basename $1 | cut -d"." -f1);
export REPLICATE_API_TOKEN=""; # your replicate token for BLIP API
export CUDA_HOME=/usr/local/cuda-12.2/ #/your/cuda/home/dir;
export PYOPENGL_PLATFORM=osmesa
export MESA_GL_VERSION_OVERRIDE=4.1
export PYTHONPATH=$PYTHONPATH:$(pwd);

# Step 2: Get BLIP prompt and gender, you can also use your own prompt
python utils/get_prompt_blip.py --img-path ${EXP_DIR}/png/${SUBJECT_NAME}_crop.png --out-path ${EXP_DIR}/prompt.txt
# python core/get_prompt.py ${EXP_DIR}/png/${SUBJECT_NAME}_crop.png
export PROMPT="`cat ${EXP_DIR}/prompt.txt| cut -d'|' -f1`"
export GENDER="`cat ${EXP_DIR}/prompt.txt| cut -d'|' -f2`"

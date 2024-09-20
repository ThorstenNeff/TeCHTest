set -x
export INPUT_FILE=$1;
export EXP_DIR=$2;
export GENDER=$3;
export SUBJECT_NAME=$(basename $1 | cut -d"." -f1);
export REPLICATE_API_TOKEN=$4;
export CUDA_HOME=/usr/local/cuda-12.2/;
export PYOPENGL_PLATFORM=osmesa
export MESA_GL_VERSION_OVERRIDE=4.1
export PYTHONPATH=$PYTHONPATH:$(pwd);

# Step 1: Preprocess image, get SMPL-X & normal estimation
python utils/body_utils/preprocess.py --in_path ${INPUT_FILE} --out_dir ${EXP_DIR}
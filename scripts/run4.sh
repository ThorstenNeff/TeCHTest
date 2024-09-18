set -x
export INPUT_FILE=$1;
export EXP_DIR=$2;
export GENDER=$3;
export SUBJECT_NAME=$(basename $1 | cut -d"." -f1);
export REPLICATE_API_TOKEN=""; # your replicate token for BLIP API
export CUDA_HOME=/usr/local/cuda-12.2/ #/your/cuda/home/dir;
export PYOPENGL_PLATFORM=osmesa
export MESA_GL_VERSION_OVERRIDE=4.1
export PYTHONPATH=$PYTHONPATH:$(pwd);


# Step 4: Run geometry stage (Run on a single GPU)
python core/main.py --config configs/tech_geometry.yaml --exp_dir $EXP_DIR --sub_name $SUBJECT_NAME
python utils/body_utils/postprocess.py --dir $EXP_DIR/obj --name $SUBJECT_NAME
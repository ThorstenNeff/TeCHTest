set -x
export INPUT_FILE=$1;
export EXP_DIR=$2;
export GENDER=$3;
export SUBJECT_NAME=$(basename $1 | cut -d"." -f1);
export REPLICATE_API_TOKEN=""; # your replicate token for BLIP API
export CUDA_HOME=/usr/local/cuda-11.6/ #/your/cuda/home/dir;
export PYOPENGL_PLATFORM=osmesa
export MESA_GL_VERSION_OVERRIDE=4.1
export PYTHONPATH=$PYTHONPATH:$(pwd);

# Step 1: Preprocess image, get SMPL-X & normal estimation
#python utils/body_utils/preprocess.py --in_path ${INPUT_FILE} --out_dir ${EXP_DIR}

# Skip Step2 for now and take info from parameters
export PROMPT=""

# Step 3: Finetune Dreambooth model (minimal GPU memory requirement: 2x32G)
rm -rf ${EXP_DIR}/ldm
python utils/ldm_utils/main.py -t --data_root ${EXP_DIR}/png/ --logdir ${EXP_DIR}/ldm/ --reg_data_root data/dreambooth_data/class_${GENDER}_images/ --bg_root data/dreambooth_data/bg_images/ --class_word ${GENDER} --no-test --gpus 0,1
# Convert Dreambooth model to diffusers format
python utils/ldm_utils/convert_ldm_to_diffusers.py --checkpoint_path ${EXP_DIR}/ldm/_v1-finetune_unfrozen/checkpoints/last.ckpt --original_config_file utils/ldm_utils/configs/stable-diffusion/v1-inference.yaml --scheduler_type ddim --image_size 512 --prediction_type epsilon --dump_path ${EXP_DIR}/sd_model
# [Optional] you can delete the original ldm exp dir to save disk memory
rm -rf ${EXP_DIR}/ldm
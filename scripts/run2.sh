set -x
export SUBJECT_NAME=$(basename $1 | cut -d"." -f1);
export CUSTOM_PROMPT=$2
export GENDER=$3
export EXP_DIR=$4
export CUDA_HOME=/usr/local/cuda-12.2/;
export PYOPENGL_PLATFORM=osmesa
export MESA_GL_VERSION_OVERRIDE=4.1
export PYTHONPATH=$PYTHONPATH:$(pwd);

# Step 2: Get BLIP prompt and gender, you can also use your own prompt
echo "STEP2"
# Step 2: Get BLIP prompt and gender, you can also use your own prompt
python utils/get_prompt_blip.py --img-path ${EXP_DIR}/png/${SUBJECT_NAME}_crop.png --out-path ${EXP_DIR}/prompt.txt
# python core/get_prompt.py ${EXP_DIR}/png/${SUBJECT_NAME}_crop.png
p="$2|$3"
echo  $p > "$4/prompt.txt"
# python core/get_prompt.py ${EXP_DIR}/png/${SUBJECT_NAME}_crop.png
export PROMPT="`cat ${EXP_DIR}/prompt.txt| cut -d'|' -f1`"
export GENDER="`cat ${EXP_DIR}/prompt.txt| cut -d'|' -f2`"


echo "STEP3"
# Step 3: Finetune Dreambooth model (minimal GPU memory requirement: 2x32G)
rm -rf ${EXP_DIR}/ldm
python utils/ldm_utils/main.py -t --data_root ${EXP_DIR}/png/ --logdir ${EXP_DIR}/ldm/ --reg_data_root data/dreambooth_data/class_${GENDER}_images/ --bg_root data/dreambooth_data/bg_images/ --class_word ${GENDER} --no-test --gpus 0
# Convert Dreambooth model to diffusers format
python utils/ldm_utils/convert_ldm_to_diffusers.py --checkpoint_path ${EXP_DIR}/ldm/_v1-finetune_unfrozen/checkpoints/last.ckpt --original_config_file utils/ldm_utils/configs/stable-diffusion/v1-inference.yaml --scheduler_type ddim --image_size 512 --prediction_type epsilon --dump_path ${EXP_DIR}/sd_model
# [Optional] you can delete the original ldm exp dir to save disk memory
rm -rf ${EXP_DIR}/ldm

echo "STEP4"
# Step 4: Run geometry stage (Run on a single GPU)
python core/main.py --config configs/tech_geometry.yaml --exp_dir $EXP_DIR --sub_name $SUBJECT_NAME
python utils/body_utils/postprocess.py --dir $EXP_DIR/obj --name $SUBJECT_NAME
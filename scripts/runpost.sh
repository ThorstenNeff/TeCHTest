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

echo "STEP2"
# Step 2: Get BLIP prompt and gender, you can also use your own prompt
python utils/get_prompt_blip.py --img-path ${EXP_DIR}/png/${SUBJECT_NAME}_crop.png --out-path ${EXP_DIR}/prompt.txt
# python core/get_prompt.py ${EXP_DIR}/png/${SUBJECT_NAME}_crop.png
export PROMPT="`cat ${EXP_DIR}/prompt.txt| cut -d'|' -f1`"
export GENDER="`cat ${EXP_DIR}/prompt.txt| cut -d'|' -f2`"

python utils/body_utils/postprocess.py --dir $EXP_DIR/obj --name $SUBJECT_NAME

echo "STEP5"
# Step 5: Run texture stage (Run on a single GPU)
python core/main.py --config configs/tech_texture.yaml --exp_dir $EXP_DIR --sub_name $SUBJECT_NAME

echo "STEP6"
# [Optional] export textured mesh with UV map, using atlas for UV unwraping.
python core/main.py --config configs/tech_texture_export.yaml --exp_dir $EXP_DIR --sub_name $SUBJECT_NAME --test

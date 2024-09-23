set -x
export SUBJECT_NAME=$(basename $1 | cut -d"." -f1);
export CUSTOM_PROMPT=$2
export GENDER=$3
export EXP_DIR=$4
export SUBJECT_NAME=$5
# Step 2: Get BLIP prompt and gender, you can also use your own prompt
p="$2|$3"
echo  $p > "$4/prompt.txt"
# python core/get_prompt.py ${EXP_DIR}/png/${SUBJECT_NAME}_crop.png
export PROMPT=$2
export GENDER=$3

echo "STEP4"
# Step 4: Run geometry stage (Run on a single GPU)
python core/main.py --config configs/tech_geometry.yaml --exp_dir $EXP_DIR --sub_name $SUBJECT_NAME
python utils/body_utils/postprocess.py --dir $EXP_DIR/obj --name $SUBJECT_NAME

echo "STEP5"
# Step 5: Run texture stage (Run on a single GPU)
python core/main.py --config configs/tech_texture.yaml --exp_dir $EXP_DIR --sub_name $SUBJECT_NAME

echo "STEP6"
# [Optional] export textured mesh with UV map, using atlas for UV unwraping.
python core/main.py --config configs/tech_texture_export.yaml --exp_dir $EXP_DIR --sub_name $SUBJECT_NAME --test
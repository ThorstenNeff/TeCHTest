set -x
export CUSTOM_PROMPT=$1
export GENDER=$2
export EXP_DIR=$3

# Step 2: Get BLIP prompt and gender, you can also use your own prompt
p="$1|$2"
echo  $p > "$3/prompt.txt"
# python core/get_prompt.py ${EXP_DIR}/png/${SUBJECT_NAME}_crop.png
export PROMPT=$1
export GENDER=$2

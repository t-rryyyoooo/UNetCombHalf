#!/bin/bash

# Input 
readonly INPUT_DIRECTORY="input"
echo -n "Is json file name segmentation_comb.json?[y/n]:"
read which
while [ ! $which = "y" -a ! $which = "n" ]
do
 echo -n "Is json file name the same as this file name?[y/n]:"
 read which
done

# Specify json file path.
if [ $which = "y" ];then
 JSON_NAME="segmentation_comb.json"
else
 echo -n "JSON_FILE_NAME="
 read JSON_NAME
fi

readonly JSON_FILE="${INPUT_DIRECTORY}/${JSON_NAME}"

readonly IMAGE_PATH_LAYER_1=$(eval echo $(cat ${JSON_FILE} | jq -r ".image_path_layer_1"))
readonly IMAGE_PATH_LAYER_2=$(eval echo $(cat ${JSON_FILE} | jq -r ".image_path_layer_2"))
readonly IMAGE_PATH_THIN=$(eval echo $(cat ${JSON_FILE} | jq -r ".image_path_thin"))
readonly LABEL_PATH=$(eval echo $(cat ${JSON_FILE} | jq -r ".label_path"))
readonly MODELWEIGHTFILE=$(eval echo $(cat ${JSON_FILE} | jq -r ".modelweightfile"))
readonly IMAGE_ORIGINAL_PATH=$(eval echo $(cat ${JSON_FILE} | jq -r ".image_original_path"))
readonly IMAGE_NAME=$(cat ${JSON_FILE} | jq -r ".image_name")
readonly PATCH_SIZE=$(cat ${JSON_FILE} | jq -r ".patch_size")
readonly PLANE_SIZE=$(cat ${JSON_FILE} | jq -r ".plane_size")
readonly SAVE_DIRECTORY=$(eval echo $(cat ${JSON_FILE} | jq -r ".save_directory"))
readonly SAVE_NAME=$(cat ${JSON_FILE} | jq -r ".save_name")
readonly OVERLAP=$(cat ${JSON_FILE} | jq -r ".overlap")
readonly NUM_REP=$(cat ${JSON_FILE} | jq -r ".num_rep")
readonly NUM_ARRAY=$(cat ${JSON_FILE} | jq -r ".num_array[]")
readonly GPU_ID=$(cat ${JSON_FILE} | jq -r ".gpu_id")

echo $NUM_ARRAY
for number in ${NUM_ARRAY[@]}
do

    echo "number:${number}"
    echo "IMAGE_PATH_LAYER_1:${IMAGE_PATH_LAYER_1}"
    echo "IMAGE_PATH_LAYER_2:${IMAGE_PATH_LAYER_2}"
    echo "IMAGE_PATH_THIN:${IMAGE_PATH_THIN}"
    echo "LABEL_PATH:${LABEL_PATH}"
    echo "MODELWEIGHTFILE:${MODELWEIGHTFILE}"
    echo "PATCH_SIZE:${PATCH_SIZE}"
    echo "plane_size:${PLANE_SIZE}"
    echo "OVERLAP:${OVERLAP}"
    echo "NUM_REP:${NUM_REP}"

    org_image="${IMAGE_ORIGINAL_PATH}/case_${number}/${IMAGE_NAME}"
    save_path="${SAVE_DIRECTORY}/case_${number}/${SAVE_NAME}"
    echo "org_image:${org_image}"
    echo "save_path:${save_path}"

    python3 segmentation.py ${number} ${IMAGE_PATH_LAYER_1} ${IMAGE_PATH_LAYER_2} ${IMAGE_PATH_THIN} ${LABEL_PATH} ${MODELWEIGHTFILE} ${org_image} ${save_path} --patch_size ${PATCH_SIZE} --plane_size ${PLANE_SIZE} --overlap ${OVERLAP} --num_rep ${NUM_REP}

done

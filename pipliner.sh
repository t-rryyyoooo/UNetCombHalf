#!/bin/bash

# Input 
readonly INPUT_DIRECTORY="input"
echo -n "Is json file name pipliner_comb.json?[y/n]:"
read which
while [ ! $which = "y" -a ! $which = "n" ]
do
 echo -n "Is json file name the same as this file name?[y/n]:"
 read which
done

# Specify json file path.
if [ $which = "y" ];then
 JSON_NAME="pipliner_comb.json"
else
 echo -n "JSON_FILE_NAME="
 read JSON_NAME
fi

readonly JSON_FILE="${INPUT_DIRECTORY}/${JSON_NAME}"

# Training input
readonly CONCAT_PATH=$(eval echo $(cat ${JSON_FILE} | jq -r ".concat_path"))
readonly IMAGE_PATH_THIN=$(eval echo $(cat ${JSON_FILE} | jq -r ".image_path_thin"))
readonly LABEL_PATH=$(eval echo $(cat ${JSON_FILE} | jq -r ".label_path"))
readonly MODEL_SAVEPATH=$(eval echo $(cat ${JSON_FILE} | jq -r ".model_savepath"))
readonly TRAIN_LISTS=$(cat ${JSON_FILE} | jq -r ".train_lists")
readonly VAL_LISTS=$(cat ${JSON_FILE} | jq -r ".val_lists")
readonly LOG=$(eval echo $(cat ${JSON_FILE} | jq -r ".log"))
readonly IN_CHANNEL_1=$(cat ${JSON_FILE} | jq -r ".in_channel_1")
readonly IN_CHANNEL_2=$(cat ${JSON_FILE} | jq -r ".in_channel_2")
readonly IN_CHANNEL_THIN=$(cat ${JSON_FILE} | jq -r ".in_channel_thin")
readonly OUT_CHANNEL_THIN=$(cat ${JSON_FILE} | jq -r ".out_channel_thin")
readonly NUM_CLASS=$(cat ${JSON_FILE} | jq -r ".num_class")
readonly LEARNING_RATE=$(cat ${JSON_FILE} | jq -r ".learning_rate")
readonly BATCH_SIZE=$(cat ${JSON_FILE} | jq -r ".batch_size")
readonly NUM_WORKERS=$(cat ${JSON_FILE} | jq -r ".num_workers")
readonly EPOCH=$(cat ${JSON_FILE} | jq -r ".epoch")
readonly GPU_IDS=$(cat ${JSON_FILE} | jq -r ".gpu_ids")
readonly API_KEY=$(cat ${JSON_FILE} | jq -r ".api_key")
readonly PROJECT_NAME=$(cat ${JSON_FILE} | jq -r ".project_name")
readonly EXPERIMENT_NAME=$(cat ${JSON_FILE} | jq -r ".experiment_name")

readonly TRAIN_DIR=$(cat ${JSON_FILE} | jq -r ".train_dir")

readonly FOLD_LIST=$(cat ${JSON_FILE} | jq -r ".train_lists | keys[]")

# Segmentation input
readonly SEG_DIR=$(cat ${JSON_FILE} | jq -r ".seg_dir")
readonly MODEL_NAME=$(cat ${JSON_FILE} | jq -r ".model_name")
readonly IMAGE_DIRECTORY=$(cat ${JSON_FILE} | jq -r ".image_directory")
readonly IMAGE_NAME=$(cat ${JSON_FILE} | jq -r ".image_name")
readonly PATCH_SIZE=$(cat ${JSON_FILE} | jq -r ".patch_size")
readonly PLANE_SIZE=$(cat ${JSON_FILE} | jq -r ".plane_size")
readonly SAVE_NAME=$(cat ${JSON_FILE} | jq -r ".save_name")
readonly OVERLAP=$(cat ${JSON_FILE} | jq -r ".overlap")
readonly NUM_REP=$(cat ${JSON_FILE} | jq -r ".num_rep")
readonly TEST_LISTS=$(cat ${JSON_FILE} | jq -r ".test_lists")

# Caluculation input
readonly TRUE_NAME=$(cat ${JSON_FILE} | jq -r ".true_name")
readonly CSV_SAVEPATH=$(eval echo $(cat ${JSON_FILE} | jq -r ".csv_savepath"))
readonly CLASS_LABEL=$(cat ${JSON_FILE} | jq -r ".class_label")


all_patients=""
for fold in ${FOLD_LIST[@]}
do
 train_list=$(echo $TRAIN_LISTS | jq -r ".$fold")
 val_list=$(echo $VAL_LISTS | jq -r ".$fold")
 image_path_layer_1="${CONCAT_PATH}/${TRAIN_DIR}/layer_1/${fold}"
 image_path_layer_2="${CONCAT_PATH}/${TRAIN_DIR}/layer_2/${fold}"
 image_path_thin="${IMAGE_PATH_THIN}/${TRAIN_DIR}/image"
 label_path="${LABEL_PATH}/${TRAIN_DIR}/image"
 model_savepath="${MODEL_SAVEPATH}/${fold}"
 log="${LOG}/${fold}"
 experiment_name="${EXPERIMENT_NAME}-${fold}"

 echo "---------- Training ----------"
 echo "image_path_layer_1:${image_path_layer_1}"
 echo "image_path_layer_2:${image_path_layer_2}"
 echo "image_path_thin:${image_path_thin}"
 echo "label_path:${label_path}"
 echo "model_savepath:${model_savepath}"
 echo "train_list:${train_list}"
 echo "val_list:${val_list}"
 echo "log:${log}"
 echo "IN_CHANNEL_1:${IN_CHANNEL_1}"
 echo "IN_CHANNEL_2:${IN_CHANNEL_2}"
 echo "IN_CHANNEL_THIN:${IN_CHANNEL_THIN}"
 echo "OUT_CHANNEL_THIN:${OUT_CHANNEL_THIN}"
 echo "NUM_CLASS:${NUM_CLASS}"
 echo "LEARNING_RATE:${LEARNING_RATE}"
 echo "BATCH_SIZE:${BATCH_SIZE}"
 echo "NUM_WORKERS:${NUM_WORKERS}"
 echo "EPOCH:${EPOCH}"
 echo "GPU_IDS:${GPU_IDS}"
 echo "API_KEY:${API_KEY}"
 echo "PROJECT_NAME:${PROJECT_NAME}"
 echo "experiment_name:${experiment_name}"

#python3 train.py ${image_path_layer_1} ${image_path_layer_2} ${image_path_thin} ${label_path} ${model_savepath} --train_list ${train_list} --val_list ${val_list} --log ${log} --in_channel_1 ${IN_CHANNEL_1} --in_channel_2 ${IN_CHANNEL_2} --in_channel_thin ${IN_CHANNEL_THIN} --num_class ${NUM_CLASS} --lr ${LEARNING_RATE} --batch_size ${BATCH_SIZE} --num_workers ${NUM_WORKERS} --epoch ${EPOCH} --gpu_ids ${GPU_IDS} --api_key ${API_KEY} --project_name ${PROJECT_NAME} --experiment_name ${experiment_name} --out_channel_thin ${OUT_CHANNEL_THIN}
 
 if [ $? -ne 0 ];then
  exit 1
 fi
 
 echo "---------- Segmentation ----------"
 test_list=$(echo $TEST_LISTS | jq -r ".$fold")
 t_list=(${test_list// / })
 image_path_layer_1="${CONCAT_PATH}/${SEG_DIR}/layer_1/${fold}"
 image_path_layer_2="${CONCAT_PATH}/${SEG_DIR}/layer_2/${fold}"
 image_path_thin="${IMAGE_PATH_THIN}/${SEG_DIR}/image"
 label_path="${LABEL_PATH}/${SEG_DIR}/image"
 save_path="${LABEL_PATH}/${SEG_DIR}/segmentation"
 model_path="${MODEL_SAVEPATH}/${fold}/${MODEL_NAME}"

 for number in ${t_list[@]}
 do
  layer_1_patient="${image_path_layer_1}"
  layer_2_patient="${image_path_layer_2}"
  thin_patient="${image_path_thin}"
  label_patient="${label_path}"
  org="${IMAGE_DIRECTORY}/case_${number}/${IMAGE_NAME}"
  save="${save_path}/case_${number}/${SAVE_NAME}"

  echo "layer_1:${layer_1_patient}"
  echo "layer_2:${layer_2_patient}"
  echo "thin:${thin_patient}"
  echo "label:${label_patient}"
  echo "model:${model_path}"
  echo "org:${org}"
  echo "PATCH_SIZE:${PATCH_SIZE}"
  echo "PLANE_SIZE:${PLANE_SIZE}"
  echo "OVERLAP:${OVERLAP}"
  echo "NUM_REP:${NUM_REP}"
  echo "save:${save}"

  python3  segmentation.py ${number} ${layer_1_patient} ${layer_2_patient} ${thin_patient} ${label_patient} ${model_path} ${org} ${save} --patch_size ${PATCH_SIZE} --plane_size ${PLANE_SIZE} --overlap ${OVERLAP} --num_rep ${NUM_REP}

  if [ $? -ne 0 ];then
   exit 1
  fi

 done

 all_patients="${all_patients}${test_list} "

done

echo " ---------- Caluculation ----------"
echo "TRUE_DIRECTORY:${IMAGE_DIRECTORY}"
echo "PREDICT_DIRECTORY:${save_path}"
echo "CSV_SAVEPATH:${CSV_SAVEPATH}"
echo "ALL_PATIENTS:${all_patients}"
echo "NUM_CLASS:${NUM_CLASS}"
echo "CLASS_LABEL:${CLASS_LABEL}"
echo "TRUE_NAME:${TRUE_NAME}"
echo "PREDICT_NAME:${SAVE_NAME}"

python3 caluculateDICE.py ${IMAGE_DIRECTORY} ${save_path} ${CSV_SAVEPATH} ${all_patients} --classes ${NUM_CLASS} --class_label ${CLASS_LABEL} --true_name ${TRUE_NAME} --predict_name ${SAVE_NAME} 


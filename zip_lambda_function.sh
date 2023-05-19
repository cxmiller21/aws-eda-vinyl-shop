#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LAMBDA_ZIP_FILE_NAME="lambda.zip"

lambda_functions=("${SCRIPT_DIR}/files/notification-service" "${SCRIPT_DIR}/files/order-service-layer" "${SCRIPT_DIR}/files/order-service/create-order" "${SCRIPT_DIR}/files/order-service/update-order")

# echo "Zipping NodeJS files with dependencies"

# cd $SCRIPT_DIR/files/order-service-layer/nodejs
# npm i

# cd $SCRIPT_DIR/files/notification-service
# npm i

# Loop through the list
for file_path in "${lambda_functions[@]}"
do
  echo "Zipping Lambda function: $file_path"
  cd $file_path

  if [ -f "./${LAMBDA_ZIP_FILE_NAME}.zip" ]; then
    echo "Deleting Lambda zip file"
    rm ./$LAMBDA_ZIP_FILE_NAME
  fi

  if [[ $file_path == *"order-service-layer"* ]] || [[ $file_path == *"notification-service"* ]]; then
    npm i
  fi
  zip -r ./$LAMBDA_ZIP_FILE_NAME .
done

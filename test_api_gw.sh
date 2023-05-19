#!/bin/bash

METHOD="POST"
API_URL="https://350gmolke9.execute-api.us-east-1.amazonaws.com"
API_STAGE="v1"
API_PATH="order"
DATA='{"id":193,"amount":621}'

API_URL_FULL="${API_URL}/${API_STAGE}/${API_PATH}"

curl -X $METHOD $API_URL_FULL -d $DATA

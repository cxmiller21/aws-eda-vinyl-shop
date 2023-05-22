#!/bin/bash

METHOD="POST"
API_URL="https://x.execute-api.us-east-1.amazonaws.com"
API_STAGE="v1"
API_PATH="order"
DATA='{"id":3,"amount":501}'

API_URL_FULL="${API_URL}/${API_STAGE}/${API_PATH}"

curl -X $METHOD $API_URL_FULL -d $DATA

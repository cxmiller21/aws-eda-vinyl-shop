#!/bin/bash

API_GW_ID="x"
METHOD="POST"
API_URL="https://${API_GW_ID}.execute-api.us-east-1.amazonaws.com"
API_STAGE="v1"
API_PATH="order"
DATA='{"id":4,"amount":300}'

API_URL_FULL="${API_URL}/${API_STAGE}/${API_PATH}"

curl -X $METHOD $API_URL_FULL -d $DATA

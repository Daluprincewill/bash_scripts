#!/bin/bash

#Price checker script uses APIs to get information about current asset price and displays output in shell
#Uses exchangerate.host API
#Usage:
#	export MY_KEY="your_api_key"
#	./price_checker BTC USD
#	./price_checker NGN USD


#Enable strictmode
set -euo pipefail

if [ $# -lt 2 ]; then
	echo "Usage: $0 BASE TARGET"
	echo "Example: $0 USD NGN  #US Dollar to Nigerian Naira "
	echo "$0 BTC USD  #Bitcoin  to US Dollar "
	exit 1
fi

BASE="$1"
TARGET="$2"

API_URL="https://api.exchangerate.host/convert?access_key=${MY_KEY}&from=${BASE}&to=${TARGET}"

#Make the API Request
RESP=$(curl -s --fail "$API_URL")|| {
	echo "Network error: could not fetch data."
	exit 2
}

#check if  jq is installed
if ! command -v jq &> /dev/null; then
	echo "Please install jq (sudo apt install jq)"
	echo "Raw Api response: "
	echo "$RESP"
	exit 3
fi

#parse the result
SUCCESS=$(echo "$RESP" | jq -r '.success')
if [ "$SUCCESS" != "true" ]; then
	echo "API error: invalid response"
	echo "$RESP"
	exit 4
fi

RATE=$(echo "$RESP" | jq -r '.result')
DATE$(echo "$RESP" | jq -r '.date')

cat <<EOF
Exchange Rate Checker
----------------------
Base	: $BASE
Target	: $TARGET
Rate	: 1 $BASE = $RATE $TARGET
Date	: $DATE
EOF

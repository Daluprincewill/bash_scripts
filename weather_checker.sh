#!/bin/bash

################## Weather checker script in bash ###################################
# Usage:
#	OWM_API_KEY="your_api_key" ./weather_checker.sh "Lagos"
# or export OWM_API_KEY beforehand:
#	export OWM_API_KEY="your_api_key"
#	./weather_checker.sh "Lagos"


#Enable strictmode
set -euo pipefail

if [ $# -lt 1 ]; then
	echo "Usage: $0 CITY_NAME"
	exit 1
fi

CITY="$*"
API_KEY="${OWM_API_KEY:-}"

if [ -z "$API_KEY" ]; then
	echo -e "Error: set OWM_API_KEY environment variable with your OpenWeatherMap API  key.\a"
	exit 2
fi

BASE_URL="https://api.openweathermap.org/data/2.5/weather"
#Use metric units (Celsius). Change to imperial for Fahrenheit.
RESP="$(curl -s -G--fail \
	--data-urlencode "q=${CITY}" \
	--data-urlencode "appid=${API_KEY}" \
	--data-urlencode "units=metric" \
	"${BASE_URL}" )" || {
	echo -e "Network error or non-2xx response from API."
	exit 3
}

# if jq isn't installed, this will fail - jq is strongly recommended.
if ! command -v jq &>/dell/null; then
	echo Please install jq to parse JSON (e.g. sudo apt install jq)."
	echo "Raw response:"
	echo "$RESP"
	exit 4
fi

#Basic error check from API (openweathermap returns cod & message on error)
CODE=$(echo "$RESP" | jq -r '.cod')
if [ "$CODE" != "200" ] && [ "$CODE"!="200" ];then
	MSG=$(echo "$RESP" | jq -r '.message // "unknown error"')
	echo "API error ($CODE): $MSG"
	exit 5
fi

CITY_NAME=$(echo "$RESP | jq -r '.name + ", " + (.sys.country // "")')
WEATHER_MAIN=$(echo "$RESP" | jq -r '.weather[0].main')
WEATHER_DESC=$(echo "$RESP" | jq -r '.weather[0].description')
TEMP=$(echo "RESP" | jq -r '.main.temp')
FEELS=$(echo  "RESP" | jq -r '.main.feels_like')
HUMIDITY=$(echo "RESP" | jq -r '.main.humidity')
WIND_SPEED=$(echo "$RESP" | jq -r '.wind.speed')
SUNRISE=$(echo "$RESP" | jq -r '.sys.sunrise')
SUNSET=$(echo "$RESP" | jq -r '.sys.sunset')

#convert unix timestamps to human time (local timezone)
SUNRISE_HUMAN=$(date -d @"$SUNRISE" +"%F %H:%M:%S")
SUNSET_HUMAN=$(date -d @"$SUNSET" +"%F %H:%M:%S")

cat <<EOF
Weather for : $CITY_NAME
	Condition : $WEATHER_MAIN - $WEATHER_DESC
	Temp : ${TEMP} Celsius (feels like ${FEELS} Celsius)
	Humidity : ${HUMIDITY}%
	Wind speed : ${WIND_SPEED} m/s
	Sunrise : ${SUNRISE_HUMAN}
	SUNSET: ${SUNSET_HUMAN}
EOF


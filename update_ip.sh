#!/bin/sh

# Configuration file path
CONFIG_FILE="/usr/local/bin/config.json"
# IP file path
IP_FILE="/var/log/current_ip.txt"
# File to store the number of checks
CHECK_COUNT_FILE="/var/log/check_count.txt"
# Maximum number of checks before forcing a DNS check
MAX_CHECKS=10

# Function to log messages
log_message() {
  echo "- $1"
  # echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Validate configuration file
validate_config() {
  if [ ! -f "$CONFIG_FILE" ]; then
    log_message "Error: Configuration file $CONFIG_FILE does not exist."
    exit 1
  fi
}

# Get public IP with error handling
get_public_ip() {
  while true; do
    IP=$(curl -s http://checkip.amazonaws.com)
    if [ $? -eq 0 ]; then
      log_message "Public IP obtained: $IP"
      break
    else
      log_message "Error: Unable to obtain public IP. Retrying in 10 seconds..."
      sleep 10
    fi
  done
}

# Read the old IP from the file
read_old_ip() {
  if [ -f $IP_FILE ]; then
    OLD_IP=$(cat $IP_FILE)
  else
    OLD_IP=""
  fi
}

# Read the check count from the file
read_check_count() {
  if [ -f $CHECK_COUNT_FILE ]; then
    CHECK_COUNT=$(cat $CHECK_COUNT_FILE)
  else
    CHECK_COUNT=0
  fi
}

# Update DNS record
update_record() {
  local DOMAIN=$1
  local ZONE_ID=$2
  local API_KEY=$3
  local EMAIL=$4
  local TTL=$5
  local SUBDOMAIN=$6
  local FULL_SUBDOMAIN="${SUBDOMAIN}.${DOMAIN}"
  
  log_message "Retrieving record ID for $FULL_SUBDOMAIN"
  RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$FULL_SUBDOMAIN" \
    -H "X-Auth-Email: $EMAIL" \
    -H "X-Auth-Key: $API_KEY" \
    -H "Content-Type: application/json")

  RECORD_ID=$(echo $RESPONSE | jq -r '.result[0].id')
  CURRENT_IP=$(echo $RESPONSE | jq -r '.result[0].content')
  IS_PROXIED=$(echo $RESPONSE | jq -r '.result[0].proxied')

  if [ -z "$RECORD_ID" ] || [ "$RECORD_ID" = "null" ]; then
    log_message "Error: Unable to retrieve record ID for $FULL_SUBDOMAIN. Response: $RESPONSE"
    return 1
  fi

  # Force update if CHECK_COUNT reaches MAX_CHECKS
  if [ "$IP" != "$CURRENT_IP" ] || [ $CHECK_COUNT -ge $MAX_CHECKS ]; then
    log_message "Updating DNS record for $FULL_SUBDOMAIN with IP $IP"
    UPDATE_RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
      -H "X-Auth-Email: $EMAIL" \
      -H "X-Auth-Key: $API_KEY" \
      -H "Content-Type: application/json" \
      --data "{\"type\":\"A\",\"name\":\"$FULL_SUBDOMAIN\",\"content\":\"$IP\",\"ttl\":$TTL,\"proxied\":$IS_PROXIED}")

    if echo "$UPDATE_RESPONSE" | grep -q '"success":true'; then
      log_message "DNS record updated for $FULL_SUBDOMAIN with IP $IP"
      # Ensure the directory exists before writing to the IP file
      mkdir -p $(dirname $IP_FILE)
      echo $IP > $IP_FILE
      CHECK_COUNT=0 # Reset the check count after a forced update
    else
      log_message "Error: Unable to update DNS record for $FULL_SUBDOMAIN. Response: $UPDATE_RESPONSE"
    fi
  else
    log_message "Current IP is already set. No update needed."
    CHECK_COUNT=$((CHECK_COUNT + 1))
  fi
  echo $CHECK_COUNT > $CHECK_COUNT_FILE
}

# Main function
main() {
  validate_config
  get_public_ip
  read_old_ip
  read_check_count

  # Read MAX_CHECKS from config file
  MAX_CHECKS=$(jq -r '.max_checks // 10' $CONFIG_FILE)

  if [ "$IP" = "$OLD_IP" ] && [ $CHECK_COUNT -lt $MAX_CHECKS ]; then
    log_message "IP has not changed and no forced check is needed. No update required."
    CHECK_COUNT=$((CHECK_COUNT + 1))
    echo $CHECK_COUNT > $CHECK_COUNT_FILE
    exit 0
  fi

  # Iterate over each domain and its subdomains
  jq -c '.targets[]' $CONFIG_FILE | while read -r DOMAIN_ENTRY; do
    DOMAIN=$(echo "$DOMAIN_ENTRY" | jq -r '.domain')
    ZONE_ID=$(echo "$DOMAIN_ENTRY" | jq -r '.zone_id')
    API_KEY=$(echo "$DOMAIN_ENTRY" | jq -r '.global_api_key')
    EMAIL=$(echo "$DOMAIN_ENTRY" | jq -r '.email')
    TTL=$(echo "$DOMAIN_ENTRY" | jq -r '.ttl')
    SUBDOMAINS=$(echo "$DOMAIN_ENTRY" | jq -r '.subdomains[]')
    for SUBDOMAIN in $SUBDOMAINS; do
      update_record $DOMAIN $ZONE_ID $API_KEY $EMAIL $TTL $SUBDOMAIN
    done
  done
}

# Execute the main function
main

# Set up cron to run the script at the specified interval
CRON_INTERVAL=$(jq -r '.cron_interval // "*/5 * * * *"' $CONFIG_FILE)
echo "$CRON_INTERVAL /bin/sh /usr/local/bin/update_ip.sh" | crontab -

# Start cron in the foreground
crond -f -l 2
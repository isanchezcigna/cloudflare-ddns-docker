#!/bin/bash
source /usr/local/bin/.env

IP=$(curl -s http://checkip.amazonaws.com)

update_record() {
  local SUBDOMAIN=$1
  RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$SUBDOMAIN" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')

  curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json" \
    --data '{"type":"A","name":"'"$SUBDOMAIN"'","content":"'"$IP"'","ttl":'"$TTL"',"proxied":false}'
}

update_record $SUBDOMAIN1
update_record $SUBDOMAIN2
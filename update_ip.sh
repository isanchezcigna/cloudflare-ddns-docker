#!/bin/sh
# Cargar variables del archivo .env
. /usr/local/bin/.env

# Archivo de log
LOG_FILE="/var/log/update_ip.log"
# Archivo para almacenar la IP anterior
IP_FILE="/var/log/current_ip.txt"

# Función para registrar mensajes
log_message() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Validar variables de entorno
validate_env() {
  for var in EMAIL GLOBAL_API_KEY ZONE_ID SUBDOMAINS; do
    if [ -z "$(eval echo \$$var)" ]; then
      log_message "Error: La variable de entorno $var no está definida."
      exit 1
    fi
  done
}

# Obtener la IP pública
get_public_ip() {
  IP=$(curl -s http://checkip.amazonaws.com)
  if [ $? -ne 0 ]; then
    log_message "Error: No se pudo obtener la IP pública"
    exit 1
  fi
  log_message "IP pública obtenida: $IP"
}

# Leer la IP anterior del archivo
read_old_ip() {
  if [ -f $IP_FILE ]; then
    OLD_IP=$(cat $IP_FILE)
  else
    OLD_IP=""
  fi
}

# Actualizar el registro DNS
update_record() {
  local FULL_SUBDOMAIN=$1
  log_message "Obteniendo ID del registro para $FULL_SUBDOMAIN"
  RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$FULL_SUBDOMAIN" \
    -H "X-Auth-Email: $EMAIL" \
    -H "X-Auth-Key: $GLOBAL_API_KEY" \
    -H "Content-Type: application/json")

  RECORD_ID=$(echo $RESPONSE | jq -r '.result[0].id')
  IS_PROXIED=$(echo $RESPONSE | jq -r '.result[0].proxied')

  if [ -z "$RECORD_ID" ] || [ "$RECORD_ID" = "null" ]; then
    log_message "Error: No se pudo obtener el ID del registro para $FULL_SUBDOMAIN. Respuesta: $RESPONSE"
    return 1
  fi

  [ "$TTL" = "auto" ] && TTL=1

  log_message "Actualizando registro DNS para $FULL_SUBDOMAIN con IP $IP"
  UPDATE_RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
    -H "X-Auth-Email: $EMAIL" \
    -H "X-Auth-Key: $GLOBAL_API_KEY" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"$FULL_SUBDOMAIN\",\"content\":\"$IP\",\"ttl\":$TTL,\"proxied\":$IS_PROXIED}")

  if echo "$UPDATE_RESPONSE" | grep -q '"success":true'; then
    log_message "Registro DNS actualizado para $FULL_SUBDOMAIN con IP $IP"
    echo $IP > $IP_FILE
  else
    log_message "Error: No se pudo actualizar el registro DNS para $FULL_SUBDOMAIN. Respuesta: $UPDATE_RESPONSE"
  fi
}

# Función principal
main() {
  validate_env
  get_public_ip
  read_old_ip

  if [ "$IP" = "$OLD_IP" ]; then
    log_message "La IP no ha cambiado. No se requiere actualización."
    exit 0
  fi

  SUBDOMAIN_ARRAY=$(echo $SUBDOMAINS | tr ',' ' ')
  for FULL_SUBDOMAIN in $SUBDOMAIN_ARRAY; do
    update_record $FULL_SUBDOMAIN
  done
}

# Ejecutar la función principal
main
FROM alpine:latest

# Instalar dependencias
RUN apk --no-cache add curl jq

# Copiar scripts y archivos de configuración
COPY update_ip.sh /usr/local/bin/update_ip.sh
COPY .env /usr/local/bin/.env
COPY crontab /etc/crontabs/root

# Dar permisos de ejecución al script
RUN chmod +x /usr/local/bin/update_ip.sh

# Ejecutar cron en primer plano
CMD ["crond", "-f"]
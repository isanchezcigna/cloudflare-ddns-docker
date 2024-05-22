FROM alpine:latest

# Instalar dependencias
RUN apk add --no-cache curl jq dos2unix

# Copiar scripts y archivos de configuración
COPY update_ip.sh /usr/local/bin/update_ip.sh
COPY .env /usr/local/bin/.env

# Convertir los scripts a formato UNIX
RUN dos2unix /usr/local/bin/update_ip.sh /usr/local/bin/.env

# Eliminar dos2unix para reducir el tamaño de la imagen
RUN apk del dos2unix

# Dar permisos de ejecución al script
RUN chmod +x /usr/local/bin/update_ip.sh

# Configurar cron para ejecutar el script cada 5 minutos
RUN crontab -l | { cat; echo "*/5 * * * * /bin/sh /usr/local/bin/update_ip.sh >> /var/log/cron.log 2>&1"; } | crontab -

# Ejecutar cron en primer plano
CMD ["crond", "-f", "-l", "2", "-L", "/var/log/cron.log"]
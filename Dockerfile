FROM alpine:latest

# Install dependencies
RUN apk add --no-cache curl jq dos2unix

# Copy scripts and configuration files
COPY update_ip.sh /usr/local/bin/update_ip.sh
COPY config.json /usr/local/bin/config.json

# Convert scripts to UNIX format
RUN dos2unix /usr/local/bin/update_ip.sh

# Remove dos2unix to reduce image size
RUN apk del dos2unix

# Grant execution permissions to the script
RUN chmod +x /usr/local/bin/update_ip.sh

# Execute the script at container startup
CMD ["/bin/sh", "/usr/local/bin/update_ip.sh"]

# # Configurar cron para ejecutar el script cada 5 minutos
# RUN echo "*/5 * * * * /bin/sh /usr/local/bin/update_ip.sh" | crontab -

# # Ejecutar cron en primer plano
# CMD ["crond", "-f", "-l", "2", "-L", "/var/log/cron.log"]
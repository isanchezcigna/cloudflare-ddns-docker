# Cloudflare DDNS Docker

> English
# Cloudflare DDNS Docker
This Docker checks the public IP and updates it in the specified subdomains in Cloudflare for multiple accounts and multiple domains.

## Prerequisites

### Get Cloudflare API
1. Get the Global API Key from Cloudflare.
2. Get the zone ID from the domain dashboard in Cloudflare.

## Configuration
Create a config.json file with the following format:
    
```json
{
  "cron_interval": "*/5 * * * *", 
  "max_checks": 12,
  "targets": [
    {
      "domain": "domain.com",
      "zone_id": "zoneidcloudflare1",
      "global_api_key": "globalapikeycloudflare1",
      "email": "email1@domain.com",
      "ttl": "auto",
      "subdomains": [
        "subdomain1",
        "subdomain2",
        "subdomain3"
      ]
    }
  ]
}
```

- Cron interval: Time interval in which the script will run. By default, every 5 minutes.

- Max checks: Number of attempts before forcing an update. By default, 12 attempts.

## Build
To build the Docker image, run the following command:

```docker build -t cloudflare-ddns .```

## Run
To run the container, run the following command:

```docker run -d --name cloudflare-ddns cloudflare-ddns```

## Using Docker Compose
Create a docker-compose.yml file with the following content:

```yaml
services:
  cloudflare-ddns:
    build: .
    container_name: cloudflare-ddns
    restart: always
    volumes:
      - ./config.json:/usr/local/bin/config.json
    environment:
      - TZ=America/Santiago
```

To build and start the container, run:

```docker-compose up -d```

To view the container logs, run:

```docker-compose logs -f```

---

> Spanish

Este Docker verifica la IP pública y la actualiza en los subdominios especificados en Cloudflare para múltiples cuentas y múltiples dominios.

## Requisitos previos

### Obtener API de Cloudflare
1. Obtener la Global API Key desde Cloudflare.
2. Obtener el ID de zona y correo asociado desde el dashboard del dominio en Cloudflare.

## Configuración

### Archivo de configuración
Crea un archivo `config.json` con el siguiente formato:

```json
{
  "cron_interval": "*/5 * * * *", 
  "max_checks": 12,
  "targets": [
    {
      "domain": "domain.com",
      "zone_id": "zoneidcloudflare1",
      "global_api_key": "globalapikeycloudflare1",
      "email": "email1@domain.com",
      "ttl": "auto",
      "subdomains": [
        "subdomain1",
        "subdomain2",
        "subdomain3"
      ]
    }
  ]
}
```
- Cron interval: Intervalo de tiempo en el que se ejecutará el script. Por defecto, cada 5 minutos.

- Max checks: Número de intentos antes de forzar una actualización. Por defecto, 12 intentos.

## Construcción
Para construir la imagen Docker, ejecuta el siguiente comando:

```docker build -t cloudflare-ddns .```

## Ejecución
Para ejecutar el contenedor, ejecuta el siguiente comando:

```docker run -d --name cloudflare-ddns cloudflare-ddns```

## Usando Docker Compose
Crea un archivo docker-compose.yml con el siguiente contenido:

```yaml
services:
  cloudflare-ddns:
    build: .
    container_name: cloudflare-ddns
    restart: always
    volumes:
      - ./config.json:/usr/local/bin/config.json
    environment:
      - TZ=America/Santiago
```

Para construir e iniciar el contenedor, ejecuta:

```docker-compose up -d```

Para ver los logs del contenedor, ejecuta:

```docker-compose logs -f```
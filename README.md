> [!NOTE]
> Spanish
# Cloudflare DDNS Docker
Este Docker realiza la verificación de la IP pública y la actualiza en los subdominios especificados en Cloudflare.

## Requisitos previos

### Obtener API de Cloudflare
1. Obtener la Global API Key desde (Cloudflare)[].
2. Obtener el ID de zona desde el dashboard del dominio en Cloudflare.

## Construcción
Para construir la imagen Docker, ejecuta el siguiente comando:

```docker build -t cloudflare-ddns .```

## Ejecución
Para ejecutar el contenedor, ejecuta el siguiente comando:

```docker run -d --name cloudflare-ddns cloudflare-ddns```


> [!NOTE]
> English
# Cloudflare DDNS Docker
This Docker verifies the public IP and updates it in the subdomains specified in Cloudflare.

## Prerequisites

### Get Cloudflare API
1. Get the Global API Key from Cloudflare.
2. Get the zone ID from the domain dashboard in Cloudflare.

## Build
To build the Docker image, run the following command:

```docker build -t cloudflare-ddns .```

## Run
To run the container, run the following command:

```docker run -d --name cloudflare-ddns cloudflare-ddns```
# Se debe solicitar primero API de Cloudflare:

1. Crear un token de API en Cloudflare:
2. Accede a My Profile → API Tokens.
3. Pulsa el botón Create Token.
4. Selecciona la plantilla Edit Zone DNS pulsando el botón Use template.
5. Agrega el permiso Zone > Zone > Read.
6. Selecciona la zona específica que incluirás: Zone > Specific zone > midominio.com.
7. Pulsa el botón Continue to summary y luego Create Token.
8. Guarda el token generado en un lugar seguro, ya que solo se muestra una vez

# Para construir:
docker build -t cloudflare-ddns .

# Para ejecutar:
docker run -d --name cloudflare-ddns cloudflare-ddns

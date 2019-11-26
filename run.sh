#!/usr/bin/env bashio
set -e

CONFIG_PATH=/data/options.json
NGROK_AUTH=$(jq --raw-output ".NGROK_AUTH" $CONFIG_PATH)
NGROK_SUBDOMAIN=$(jq --raw-output ".NGROK_SUBDOMAIN" $CONFIG_PATH)
NGROK_HOSTNAME=$(jq --raw-output ".NGROK_HOSTNAME" $CONFIG_PATH)
NGROK_REGION=$(jq --raw-output ".NGROK_REGION" $CONFIG_PATH)
NGROK_INSPECT=$(jq --raw-output ".NGROK_INSPECT" $CONFIG_PATH)
PORT_80=$(jq --raw-output ".PORT_80" $CONFIG_PATH)
PORT_443=$(jq --raw-output ".PORT_443" $CONFIG_PATH)
PORT_8123=$(jq --raw-output ".PORT_8123" $CONFIG_PATH)

echo "web_addr: 0.0.0.0:4040" > /ngrok-config/ngrok.yml

declare DOMAIN
if [ -n "$NGROK_HOSTNAME" ] && [ -n "$NGROK_AUTH" ]; then
  DOMAIN="hostname: $NGROK_HOSTNAME"
elif [ -n "$NGROK_SUBDOMAIN" ] && [ -n "$NGROK_AUTH" ]; then
  DOMAIN="subdomain: $NGROK_SUBDOMAIN"
elif [ -n "$NGROK_HOSTNAME" ] || [ -n "$NGROK_SUBDOMAIN" ]; then
  if [ -z "$NGROK_AUTH" ]; then
    echo "You must specify an authentication token after registering at https://ngrok.com to use custom domains."
    exit 1
  fi
else
  DOMAIN=null
fi

if [ -n "$NGROK_AUTH" ]; then
  echo "authtoken: $NGROK_AUTH" >> /ngrok-config/ngrok.yml
fi

echo "region: $NGROK_REGION" >> /ngrok-config/ngrok.yml

if [[ !$PORT_80  && !$PORT_443 && !$PORT_8123 ]]; then
  echo "You must specify at least one port to forward."
  exit 1
fi
echo "tunnels:" >> /ngrok-config/ngrok.yml
if [ "$PORT_80" ]; then
  echo "  http-80:" >> /ngrok-config/ngrok.yml
  echo "    proto: http" >> /ngrok-config/ngrok.yml
  echo "    addr: 127.0.0.1:80" >> /ngrok-config/ngrok.yml
  if [ -n "$DOMAIN" ]; then
    echo "    $DOMAIN" >> /ngrok-config/ngrok.yml
  fi
  echo "    bind-tls: false" >> /ngrok-config/ngrok.yml
  echo "    inspect: $NGROK_INSPECT" >> /ngrok-config/ngrok.yml
fi

if [ "$PORT_443" ]; then
  echo "  tls-443:" >> /ngrok-config/ngrok.yml
  echo "    proto: tls" >> /ngrok-config/ngrok.yml
  echo "    addr: 127.0.0.1:443" >> /ngrok-config/ngrok.yml
  if [ -n "$DOMAIN" ]; then
    echo "    $DOMAIN" >> /ngrok-config/ngrok.yml
  fi
  echo "    inspect: $NGROK_INSPECT" >> /ngrok-config/ngrok.yml
fi

if [ "$PORT_8123" ]; then
  echo "  http-8123:" >> /ngrok-config/ngrok.yml
  echo "    proto: http" >> /ngrok-config/ngrok.yml
  echo "    addr: 127.0.0.1:8123" >> /ngrok-config/ngrok.yml
  if [ -n "$DOMAIN" ]; then
    echo "    $DOMAIN" >> /ngrok-config/ngrok.yml
  fi
  echo "    bind-tls: both" >> /ngrok-config/ngrok.yml
  echo "    inspect: $NGROK_INSPECT" >> /ngrok-config/ngrok.yml
fi

ngrok start -config /ngrok-config/ngrok.yml --all
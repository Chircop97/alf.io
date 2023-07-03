#!/bin/bash

# Variables
CERTBOT_IMAGE="certbot/dns-cloudflare"
DOMAIN="dev.lambiancetickets.com"
CERT_DIR="$(pwd)/certs"
RENEW_DAYS_THRESHOLD=30

# Function to check SSL certificate expiry
check_certificate_expiry() {
  # Get the expiry date of the certificate
  expiry_date=$(openssl x509 -in "$CERT_DIR"/live/"$DOMAIN"/cert.pem -noout -enddate | cut -d= -f2)
  
  # Convert the expiry date to Unix timestamp
  expiry_timestamp=$(date -d "$expiry_date" +%s)
  
  # Get the current Unix timestamp
  current_timestamp=$(date +%s)
  
  # Calculate the number of days until expiry
  days_until_expiry=$(( (expiry_timestamp - current_timestamp) / 86400 ))
  
  # Check if the certificate is about to expire
  if [[ $days_until_expiry -lt $RENEW_DAYS_THRESHOLD ]]; then
    echo "SSL certificate for $DOMAIN is about to expire in $days_until_expiry days. Renewing..."
    renew_certificate
  else
    echo "SSL certificate for $DOMAIN is valid. No renewal is required."
  fi
}

# Function to renew SSL certificate
renew_certificate() {
  # Run the certbot container to renew the certificate
  docker run -it --rm \
    -v "$CERT_DIR:/etc/letsencrypt" \
    "$CERTBOT_IMAGE" \
    certonly --staging --non-interactive --agree-tos --email chircop97@gmail.com \
    --dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
    -d "$DOMAIN"

  # Restart the services that use the SSL certificate (e.g., web server)
  # Uncomment and modify the following line according to your setup
  # systemctl restart your_service
}

# Main script

# Check if the certificate directory exists
if [[ ! -d "$CERT_DIR"/live/"$DOMAIN" ]]; then
  echo "Certificate directory does not exist. Initializing certificate issuance..."
  renew_certificate
else
  echo "Certificate directory already exists. Checking certificate expiry..."
  check_certificate_expiry
fi

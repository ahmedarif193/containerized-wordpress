#!/bin/bash

# Initialize variables
CONTAINER_NAME=""
DB_PASSWORD=123456
WORDPRESS_NETWORK=wordpress-network
MARIADB_CONTAINER=wordpressdb
NGINX_SITES_ENABLED_DIR="/etc/nginx/sites-enabled"

# Function to show usage
usage() {
    echo "Usage: $0 --name [container-name]"
    exit 1
}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --name) CONTAINER_NAME="$2"; shift ;;
        *) usage ;;
    esac
    shift
done

# Check if the container name was provided
if [ -z "$CONTAINER_NAME" ]; then
    usage
fi

DB_NAME=$CONTAINER_NAME

# Check if the MariaDB container exists and create it if not
if [ ! "$(docker ps -q -f name=$MARIADB_CONTAINER)" ]; then
    if [ "$(docker ps -aq -f status=exited -f name=$MARIADB_CONTAINER)" ]; then
        # cleanup
        docker rm $MARIADB_CONTAINER
    fi
    # run your container
    docker run -e MYSQL_ROOT_PASSWORD=$DB_PASSWORD -e MYSQL_DATABASE=$DB_NAME --name $MARIADB_CONTAINER --network $WORDPRESS_NETWORK -v "$PWD/database":/var/lib/mysql -d mariadb:latest
    # Wait for MariaDB to start
    echo "Waiting for MariaDB to start..."
    sleep 10

fi

# Create a new database in MariaDB
docker exec $MARIADB_CONTAINER mariadb -uroot -p$DB_PASSWORD -e "CREATE DATABASE $DB_NAME;"

# Create a new WordPress container
docker run -e WORDPRESS_DB_HOST=$MARIADB_CONTAINER -e WORDPRESS_DB_NAME=$DB_NAME -e WORDPRESS_DB_USER=root -e WORDPRESS_DB_PASSWORD=$DB_PASSWORD -e WORDPRESS_TABLE_PREFIX=wp2_ --name $CONTAINER_NAME --network $WORDPRESS_NETWORK -v "$PWD/html1":/var/www/html -d wordpress

# Fetch and print the IP address of the new WordPress container
IP_ADDRESS=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CONTAINER_NAME)
echo "WordPress container IP address: $IP_ADDRESS"

# Generate Nginx configuration
NGINX_CONFIG="
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name $CONTAINER_NAME;
    
    # Proxy configuration
    location / {
        proxy_pass http://$IP_ADDRESS:80;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header Host \$host;
    }
}"

# Write the Nginx configuration to the sites-enabled directory
echo "$NGINX_CONFIG" | sudo tee "$NGINX_SITES_ENABLED_DIR/$CONTAINER_NAME.conf" > /dev/null

# Obtain SSL certificate and configure Nginx for HTTPS
sudo certbot --nginx --non-interactive --agree-tos --email contact@jojmagroup.com -d jojmagroup.com --redirect

# Reload Nginx to apply changes
sudo nginx -s reload


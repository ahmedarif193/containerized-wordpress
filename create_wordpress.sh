#!/bin/bash

# Initialize variables
CONTAINER_NAME=""
DOMAIN_NAME=""
DB_PASSWORD=123456
WORDPRESS_NETWORK=wordpress-network
MARIADB_CONTAINER=wordpressdb
NGINX_SITES_ENABLED_DIR="/etc/nginx/sites-enabled"

# Function to show usage
usage() {
    echo "Usage: $0 --create -c [container-name] -d [domain-name]"
    echo "       $0 --rm -c [container-name]"
    echo "       $0 --ls"
    echo "       $0 --help"
    exit 1
}


# Function to create containers and configurations
create_containers() {
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
    else
        # Create a new database in MariaDB
        docker exec $MARIADB_CONTAINER mariadb -uroot -p$DB_PASSWORD -e "CREATE DATABASE $DB_NAME;"
    fi

    # Create a new WordPress container
    docker run -e WORDPRESS_DB_HOST=$MARIADB_CONTAINER -e WORDPRESS_DB_NAME=$DB_NAME -e WORDPRESS_DB_USER=root -e WORDPRESS_DB_PASSWORD=$DB_PASSWORD -e WORDPRESS_TABLE_PREFIX=wp2_ --name $CONTAINER_NAME --network $WORDPRESS_NETWORK -v "$PWD/html_$CONTAINER_NAME":/var/www/html -d wordpress

    # Fetch and print the IP address of the new WordPress container
    IP_ADDRESS=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $CONTAINER_NAME)
    echo "WordPress container IP address: $IP_ADDRESS"

    # Generate Nginx configuration
    generate_nginx_config

    # Obtain SSL certificate and configure Nginx for HTTPS
    sudo certbot --nginx --non-interactive --agree-tos --email contact@jojmagroup.com -d $DOMAIN_NAME --redirect

    # Reload Nginx to apply changes
    sudo nginx -s reload
}

# Function to generate Nginx configuration
generate_nginx_config() {
    NGINX_CONFIG="
server {
    listen 80;
    server_name $DOMAIN_NAME;
    
    # Proxy configuration
    location / {
        proxy_pass http://$IP_ADDRESS:80;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header Host \$host;
    }
}
server {
    listen 443 ssl;
    server_name $DOMAIN_NAME;
    ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;
    # Include SSL configuration from certbot
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
    
    # SSL Proxy configuration
    location / {
        proxy_pass http://$IP_ADDRESS:80;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header Host \$host;
    }
}
"
    # Write the Nginx configuration to the sites-enabled directory
    echo "$NGINX_CONFIG" | sudo tee "$NGINX_SITES_ENABLED_DIR/$DOMAIN_NAME.conf" > /dev/null
}

# Function to list containers
ls_containers() {
    echo "Container Name | Domain Name | IP Address"
    echo "---------------|-------------|-----------"
    shopt -s nullglob
    for config in "$NGINX_SITES_ENABLED_DIR"/*.conf; do
        if [ -f "$config" ]; then
            domain=$(basename "$config" .conf)
            container_name=$(grep "proxy_pass http://" "$config" | head -n1 | awk -F'//' '{print $2}' | awk -F':' '{print $1}')
            if [ -n "$container_name" ]; then
                ip_address=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name" 2>/dev/null)
                echo "$container_name | $domain | ${ip_address:-N/A}"
            else
                echo "N/A | $domain | N/A"
            fi
        fi
    done
    shopt -u nullglob
}

# Function to remove containers and configurations
remove_containers() {
    # Stop and remove the WordPress container
    docker stop "$CONTAINER_NAME"
    docker rm "$CONTAINER_NAME"

    # Remove the database for this container
    docker exec $MARIADB_CONTAINER mariadb -uroot -p$DB_PASSWORD -e "DROP DATABASE IF EXISTS $CONTAINER_NAME;"

    # Remove the Nginx configuration
    sudo rm "$NGINX_SITES_ENABLED_DIR/$DOMAIN_NAME.conf"

    # Remove Let's Encrypt certificates and renewal configurations
    sudo rm "/etc/letsencrypt/renewal/$DOMAIN_NAME.conf" 2>/dev/null
    sudo rm -r "/etc/letsencrypt/live/$DOMAIN_NAME" 2>/dev/null
    sudo rm -r "/etc/letsencrypt/archive/$DOMAIN_NAME" 2>/dev/null

    # Reload Nginx to apply changes
    sudo nginx -s reload

    echo "Container, database, Nginx configuration, and SSL certificates removed for $DOMAIN_NAME"
}

# Check for no arguments or --help argument
if [ "$#" -eq 0 ]; then
    usage
    exit 0
fi

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --create) shift; CREATE_FLAG=true ;;
        --ls) ls_containers; exit 0 ;;
        --rm) shift; REMOVE_FLAG=true ;;
        -c) CONTAINER_NAME="$2"; shift ;;
        -d) DOMAIN_NAME="$2"; shift ;;
        --help) usage; exit 0 ;;
    esac
    shift
done
# Execute actions based on flags and arguments
if [ "$CREATE_FLAG" = true ]; then
    if [ -z "$CONTAINER_NAME" ] && [ -z "$DOMAIN_NAME" ]; then
        usage
        exit 0
    fi
    create_containers
elif [ "$REMOVE_FLAG" = true ]; then
    if [ -z "$CONTAINER_NAME" ]; then
        usage
        exit 0
    fi
    remove_containers
fi
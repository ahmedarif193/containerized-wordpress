# WordPress Multi-Host Automation Script with DNS Management

## Overview
This project provides a streamlined solution for deploying and managing multiple WordPress sites using Docker. It features a reverse proxy setup with Nginx for single IP management, shared MariaDB database usage, and automated DNS record management with Google Cloud DNS. This setup is ideal for efficiently managing multiple WordPress instances from a single VPS with ease and scalability.

## Features
- **Automated WordPress and Database Container Creation**: Sets up WordPress instances with MariaDB databases using Docker.
- **Dynamic Container and Domain Management**: Specify container names and domain names for each WordPress instance.
- **Network Configuration and Nginx Integration**: Configures WordPress instances in Docker networks with ready-to-use Nginx configurations.
- **IP Address Allocation and DNS Management**: Retrieves IP addresses and manages DNS records automatically.
- **SSL Certification with Certbot**: Integrates with Certbot for SSL certificate issuance and management.
- **DNS Record Automation (`helper-dns`)**: Simplifies the addition or removal of DNS records, automating interactions with Google Cloud DNS.
- **Multi-Domain Support**: Initially set to support domains like `jojmagroup.com`.

## Usage

### Setting Up the Scripts
1. Ensure Docker, Docker Compose, Nginx, gcloud and Certbot are installed on your system.
2. Clone this repository to your local machine or server.

### Running the Helper Scripts
- **DNS Management (`helper-dns`)**:
  - List domain zones: `./helper-dns --ls`
  - Attach/detach domain zones: `./helper-dns --attach|--detach -d domain-name.com`

- **WordPress Setup (`helper-wordpress`)**:
  - Create a new WordPress site: `./helper-wordpress --create -c container-name -d domain-name.com`
  - List running WordPress containers: `./helper-wordpress --ls`

### Post-Execution
Your WordPress site will be accessible at the specified domain, with Nginx routing and SSL configured. DNS management is simplified with `helper-dns`.

## Requirements
- Docker and Docker Compose
- Nginx
- Certbot
- Google Cloud SDK (for `helper-dns`)
- Bash environment for script execution

## Customization
Customize the scripts for specific database settings, WordPress configurations, Nginx templates, and DNS record management as needed.

## Contribution
Contributions to enhance or extend the functionality of these scripts are welcome. Adhere to standard coding practices and document major changes.

## Disclaimer
This script is provided as-is. Users should adapt it to their environment and requirements. Test in a non-production environment first.

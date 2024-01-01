# WordPress Multi-Host Automation Script

## Overview
This project presents a comprehensive automation script designed to streamline the setup and management of multiple WordPress sites. Initially tailored for the specific needs of Jojmagroup Holding, the script offers a robust and flexible solution for deploying WordPress instances across various hosts efficiently.

## Features
- **Automated WordPress and Database Container Creation**: Quickly sets up WordPress instances along with their respective MariaDB databases using Docker.
- **Dynamic Container Naming**: Allows specification of unique container names for each WordPress instance.
- **Automatic Database Creation**: Seamlessly creates a new database in MariaDB for each WordPress instance.
- **Network Configuration**: Each WordPress instance is configured to operate within a specified Docker network.
- **Nginx Integration**: Generates and deploys Nginx configurations for each WordPress site, ensuring immediate readiness for web traffic.
- **IP Address Allocation**: Automatically retrieves and displays the IP address for each WordPress container.
- **SSL Certification**: Integrates with Certbot for SSL certificate issuance and management, initially set to support `jojmagroup.com`.

## Usage
1. **Setting Up the Script**:
   - Ensure Docker and Docker Compose are installed on your system.
   - Install Nginx and Certbot (for SSL management) on the host machine.
   - Clone this repository to your local machine or server.

2. **Running the Script**:
   - Execute the script with the desired container name using the `--name` argument. Example: `./wordpress_setup.sh --name mywordpresssite`.
   - The script handles the creation of the WordPress and database containers, configures Nginx, and sets up SSL for the domain (if applicable).

3. **Post-Execution**:
   - After running the script, your WordPress site will be accessible at the specified domain.
   - Nginx will proxy requests to the WordPress container, and SSL will be configured if you have provided a domain.

## Requirements
- Docker and Docker Compose
- Nginx
- Certbot (for SSL certificate management)
- Bash environment for script execution

## Customization
The script can be customized for specific needs:
- Modify database settings, WordPress table prefixes, and network configurations as needed.
- Update the Nginx configuration template within the script for specific use cases or advanced configurations.

## Contribution
Contributions to enhance this script or extend its functionality are welcome. Please adhere to standard coding practices and document any major changes.

## Support for Jojmagroup Holding
This project was initially developed to support Jojmagroup Holding's multi-host WordPress management needs. It demonstrates a scalable approach to managing multiple web properties efficiently.

## Disclaimer
This script is provided as-is, and users should adapt it to their specific environment and requirements. Always test in a non-production environment first.

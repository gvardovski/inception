# Developer Documentation

## Project Overview

**Inception** is a Docker-based WordPress deployment project featuring service isolation, security best practices, and infrastructure-as-code principles. The stack consists of three containerized services orchestrated via Docker Compose:

- **Nginx**: Reverse proxy with TLS/SSL termination
- **WordPress**: PHP-FPM application server
- **MariaDB**: Relational database

---

## Architecture

### Service Topology

```
┌─────────────────────────────────────────┐
│         Docker Bridge Network (webnet)  │
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────────┐                      │
│  │   Nginx      │ (port 443)           │
│  │  (reverse    │──────────────┐       │
│  │   proxy)     │              │       │
│  └──────────────┘              │       │
│                                │       │
│  ┌──────────────┐              │       │
│  │  WordPress   │◄─────────────┘       │
│  │  (PHP-FPM)   │                      │
│  └──────────────┘                      │
│         │                              │
│         │                              │
│  ┌──────▼──────────┐                   │
│  │   MariaDB       │                   │
│  │  (port 3306)    │                   │
│  └─────────────────┘                   │
│                                         │
└─────────────────────────────────────────┘
```

### Persistent Storage

Data is stored on the host system using bind mounts to Docker named volumes:

```
Host File System          Docker Volumes          Container Mount
├── ~/data/wordpress ──── wp_data ────────────────► /var/www/wordpress
└── ~/data/mariadb ────── db_data ────────────────► /var/lib/mysql
```

### Configuration Management

- **Secrets**: Sensitive values (passwords) stored as Docker secrets in `secrets/` directory
- **Environment Variables**: Non-sensitive config in `.env` file
- **Dockerfiles**: Service-specific builds in `srcs/requirements/*/`

---

## Prerequisites

### System Requirements

- Linux operating system with `sudo` access
- 2GB+ free disk space
- Internet connection for Docker image pulls and package installations
- Bash shell environment

### Required Software

Option 1: Manual installation
- Docker Engine (any recent version)
- Docker Compose plugin (or standalone `docker-compose` binary)

Option 2: Automatic installation via Makefile
```bash
make docker
```

### Verifying Prerequisites

```bash
# Check Docker installation
docker --version
docker compose version

# Verify Docker daemon is running
docker ps

# Check sudo access
sudo -l | grep -E '(ALL|NOPASSWD)'
```

---

## Project Setup from Scratch

### Step 1: Install Docker (if needed)

```bash
# Automated installation
make docker

# Or manual steps (Ubuntu/Debian):
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### Step 2: Configure Docker for Current User

```bash
# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify
docker ps
```

### Step 3: Create Persistent Volume Directories

```bash
# Create data directories with proper permissions
mkdir -p ~/data/wordpress
mkdir -p ~/data/mariadb
chown -R $USER:$USER ~/data

# Verify
ls -la ~/data/
```

Or use the Makefile:
```bash
make volumes
```

### Step 4: Configure Secrets

Create password files in the `secrets/` directory:

```bash
# Generate strong passwords (example)
echo "secure_db_password_123" > secrets/db_password.txt
echo "secure_db_root_password_456" > secrets/db_root_password.txt
echo "secure_wordpress_admin_pwd_789" > secrets/wp_admin_password.txt
echo "secure_wordpress_user_pwd_000" > secrets/wp_user_password.txt

# Set appropriate permissions
chmod 600 secrets/*.txt

# Verify
ls -la secrets/
```

**Important**: All password files must exist before building containers. Passwords should be at least 12 characters and include mixed case, numbers, and symbols.

### Step 5: Configure Environment Variables

Edit or create `.env` in the `srcs/` directory:

```bash
# srcs/.env example
WP_DB_HOST=mariadb
WP_DB_USER=wordpress_user
WP_DB_PASSWORD_FILE=/run/secrets/db_password
WP_DB_NAME=wordpress
WP_URL=https://svolkau.42.fr
WP_TITLE=My WordPress Site
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD_FILE=/run/secrets/wp_admin_password
WP_ADMIN_EMAIL=admin@example.com
WP_USER_NAME=user
WP_USER_PASSWORD_FILE=/run/secrets/wp_user_password
WP_USER_EMAIL=user@example.com
WP_USER_ROLE=subscriber
MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress_user
```

### Step 6: Configure Domain Name

Add domain entry to `/etc/hosts`:

```bash
# Get local IP
LOCAL_IP=$(hostname -I | awk '{print $1}')
echo "$LOCAL_IP svolkau.42.fr" | sudo tee -a /etc/hosts

# Verify
grep svolkau.42.fr /etc/hosts
```

Or use the Makefile:
```bash
make domain
```

### Step 7: Build Docker Images

```bash
# Build images without cache (recommended for first build)
make build

# Or verbose output
cd srcs && docker compose build --no-cache
```

This will:
1. Read each Dockerfile in `srcs/requirements/*/`
2. Download base images (Debian, etc.)
3. Install dependencies (Nginx packages, PHP, MariaDB, etc.)
4. Execute startup and configuration scripts
5. Tag images as `nginx`, `wordpress`, `mariadb`

### Step 8: Start Services

```bash
# Start all services
make up

# Follow logs during startup
docker compose logs -f

# Expected sequence:
# 1. MariaDB initializes and reports healthy
# 2. WordPress connects to MariaDB
# 3. WordPress reports healthy
# 4. Nginx starts and joins the network
```

Wait 30-60 seconds for full initialization. Services become healthy in order:
1. MariaDB (database)
2. WordPress (app depends on DB)
3. Nginx (web server depends on app)

### Step 9: Verify Installation

```bash
# Check all containers running
docker ps

# All three should show "Up" status:
# - nginx
# - wordpress
# - mariadb

# Test website access
curl -k https://svolkau.42.fr

# Access in browser: https://svolkau.42.fr
```

---

## Building and Launching

### Complete Build-to-Run Workflow

```bash
# 1. Clean up any previous state
make fclean

# 2. Create volumes and data directories
make volumes

# 3. Set up domain
make domain

# 4. Build fresh images
make build

# 5. Start services
make up

# 6. Monitor startup
docker compose logs -f
```

### Incremental Development Workflow

For development changes to a specific service:

```bash
# Edit Dockerfile or configuration
# e.g., srcs/requirements/nginx/Dockerfile

# Rebuild just that service
cd srcs && docker compose build --no-cache nginx

# Restart the service
docker restart nginx

# Check logs
docker logs nginx
```

### Rebuilding All Services

```bash
# Remove all images and rebuild
make clean
make build
make up
```

---

## Container and Volume Management

### Essential Docker Commands

#### Container Management

```bash
# View running containers
docker ps

# View all containers (including stopped)
docker ps -a

# Stop all containers gracefully
docker compose down

# Stop and remove images
docker compose down --rmi all

# Stop and remove everything (careful!)
docker compose down -v --rmi all

# Restart a service
docker restart wordpress

# View detailed container info
docker inspect nginx
docker inspect nginx --format='{{.State.Health.Status}}'
```

#### Logs and Debugging

```bash
# View logs from a container
docker logs nginx

# Follow logs in real-time (Ctrl+C to exit)
docker logs -f wordpress

# Last 50 lines
docker logs --tail 50 mariadb

# Logs with timestamps
docker logs -t nginx

# Filter logs (e.g., errors)
docker logs wordpress | grep -i error
```

#### Executing Commands in Containers

```bash
# Interactive shell in a container
docker exec -it wordpress bash

# Run a single command
docker exec wordpress php --version

# Run as specific user
docker exec -u www-data wordpress whoami

# Database operations
docker exec -it mariadb mariadb -u root -p < ~/backup.sql
```

#### Volume Management

```bash
# List all volumes
docker volume ls

# Inspect a volume
docker volume inspect wp_data

# View volume mount point
docker inspect wordpress --format='{{json .Mounts}}'

# Manual data backup
cp -r ~/data/wordpress ~/backup_$(date +%Y%m%d)

# Check volume usage
du -sh ~/data/wordpress ~/data/mariadb
```

### Network Management

```bash
# List Docker networks
docker network ls

# Inspect the project network
docker network inspect webnet

# Test service-to-service connectivity
docker exec wordpress ping -c 1 mariadb
docker exec nginx ping -c 1 wordpress

# View DNS resolution
docker exec wordpress nslookup mariadb
```

---

## Data Persistence and Storage

### Where Data Lives

**WordPress Files:**
- **Host**: `~/data/wordpress/`
- **Container**: `/var/www/wordpress/`
- **Volume**: `wp_data` (named volume with bind mount)

**MariaDB Data:**
- **Host**: `~/data/mariadb/`
- **Container**: `/var/lib/mysql/`
- **Volume**: `db_data` (named volume with bind mount)

### How Data Persists

1. **Between Container Restarts**: Data stored in volumes survives `docker restart` or `make down`
2. **Across Image Rebuilds**: Old images are replaced but volumes remain intact
3. **Bind Mounts**: Volume data is backed by `~/data/` directories on the host

### Verifying Data Persistence

```bash
# Check WordPress files
ls -la ~/data/wordpress/wp-content/

# Check MariaDB files
ls -la ~/data/mariadb/

# Inside a container
docker exec wordpress ls -la /var/www/wordpress/

# MariaDB tablesMariaDB data
docker exec mariadb ls -la /var/lib/mysql/wordpress/
```

### Backing Up Data

```bash
# Full backup
mkdir -p ~/backups
tar -czf ~/backups/wordpress_$(date +%Y%m%d_%H%M%S).tar.gz ~/data/wordpress/
tar -czf ~/backups/mariadb_$(date +%Y%m%d_%H%M%S).tar.gz ~/data/mariadb/

# Database dump (recommended for MariaDB)
docker exec mariadb mariadb-dump -u root -p$(cat ../secrets/db_root_password.txt) --all-databases > ~/backup_$(date +%Y%m%d).sql

# Restore from dump
docker exec -i mariadb mariadb -u root -p$(cat ../secrets/db_root_password.txt) < ~/backup_YYYYMMDD.sql
```

### Clearing Volumes (Data Reset)

```bash
# WARNING: This deletes all data!

# Stop containers and remove volumes
make fclean

# Manually remove volumes
docker volume rm wp_data db_data
rm -rf ~/data/wordpress ~/data/mariadb

# Rebuild everything
make build
make up
```

---

## Configuration Files

### Dockerfile Customization

Service-specific Dockerfiles:
- `srcs/requirements/nginx/Dockerfile`: Nginx image build
- `srcs/requirements/wordpress/Dockerfile`: WordPress/PHP image build
- `srcs/requirements/mariadb/Dockerfile`: MariaDB image build

Common customizations:
- Dependencies: Add/remove packages in RUN statements
- Base image: Change FROM statement (e.g., `ubuntu:22.04` to `ubuntu:24.04`)
- Exposed ports: Modify EXPOSE statements
- Entry points: Change CMD or ENTRYPOINT

### Docker Compose Configuration

File: `srcs/docker-compose.yml`

Key sections:
- **services**: Container definitions (nginx, wordpress, mariadb)
- **networks**: Network configuration (webnet bridge network)
- **volumes**: Volume definitions with bind-mount options
- **secrets**: Secret file references

Modify for:
- Port mappings: Change `ports:` section
- Service dependencies: Modify `depends_on:`
- Environment variables: Edit service `environment:` blocks
- Restart policies: Configure `restart:` options
- Health checks: Customize `healthcheck:` settings

### Environment Configuration

File: `srcs/.env`

Contains non-sensitive configuration:
- Domain name (WP_URL)
- Database credentials (username, not password)
- WordPress metadata (title, admin email)
- User account defaults

### Secrets

Directory: `secrets/`

Sensitive files mounted to containers:
- `db_password.txt`: Database user password
- `db_root_password.txt`: MariaDB root password
- `wp_admin_password.txt`: WordPress admin password
- `wp_user_password.txt`: WordPress user password

---

## Development Workflow

### Modifying a Service

```bash
# 1. Edit configuration file
nano srcs/requirements/nginx/conf/nginx.conf

# 2. Rebuild the image
docker compose build nginx

# 3. Restart the container
docker restart nginx

# 4. Verify changes
docker logs nginx
curl -k https://svolkau.42.fr
```

### Debugging Service Issues

```bash
# 1. Check container status
docker ps | grep nginx

# 2. View logs
docker logs nginx

# 3. Inspect configuration
docker exec nginx cat /etc/nginx/nginx.conf

# 4. Test connectivity
docker exec nginx curl localhost:443

# 5. Interactive debugging
docker exec -it nginx bash
  # Inside container:
  nginx -t          # Test configuration
  ps aux | grep nginx  # Check processes
  exit
```

### Testing Database Connectivity

```bash
# From WordPress container
docker exec wordpress mysql -h mariadb -u wordpress_user -p$(cat secrets/db_password.txt) wordpress -e "SELECT 1;"

# From host (requires mysql client)
mysql -h 127.0.0.1 -u wordpress_user -p$(cat secrets/db_password.txt) wordpress -e "SELECT 1;"

# Verify network connectivity
docker exec wordpress nc -zv mariadb 3306
```

---

## Makefile Targets

| Target | Purpose |
|--------|---------|
| `make docker` | Install Docker and Docker Compose |
| `make build` | Build all Docker images |
| `make up` | Start all services |
| `make down` | Stop services (preserve data) |
| `make clean` | Stop and remove containers/images |
| `make fclean` | Complete cleanup (dangerous!) |
| `make volumes` | Create data directories |
| `make domain` | Configure `/etc/hosts` |
| `make sync-domain-ip` | Update domain → nginx IP mapping |

---

## Common Development Tasks

### Adding a New Environment Variable

1. Add to `srcs/.env`
2. Add to service `environment:` in `docker-compose.yml`
3. Update Dockerfile `ENTRYPOINT` or startup script to use it
4. Rebuild: `docker compose build <service>`
5. Restart: `docker restart <service>`

### Integrating a New Service (e.g., Redis)

1. Create `srcs/requirements/redis/Dockerfile`
2. Add service to `srcs/docker-compose.yml`
3. Update dependent services' `depends_on:` and environment variables
4. Rebuild and restart: `make build && make up`

### Changing SSL Certificate

```bash
# Current: Self-signed certificate in nginx container
# Replace in: srcs/requirements/nginx/conf/

# For production, generate or import certificates:
docker exec nginx bash
  # Inside container:
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/server.key \
    -out /etc/nginx/ssl/server.crt
  exit
```

---

## Troubleshooting

### Port Already in Use

```bash
# Check what's using port 443
sudo lsof -i :443

# Solution: Stop conflicting service or change port in docker-compose.yml
```

### Container Fails to Start

```bash
# 1. Check logs
docker logs <container_name>

# 2. Inspect container state
docker inspect <container_name> --format='{{.State}}'

# 3. Manual troubleshooting
docker run -it nginx bash
  # Try commands inside the container to debug
  exit

# 4. Rebuild from scratch
docker compose build --no-cache <service>
docker restart <service>
```

### Network Connectivity Issues

```bash
# Verify network exists
docker network ls | grep webnet

# Check service can reach other service
docker exec wordpress ping mariadb

# DNS resolution
docker exec wordpress getent hosts mariadb

# Inspect network
docker network inspect webnet | grep -A5 Containers
```

### Database Connection Refused

```bash
# Check MariaDB is running
docker ps | grep mariadb

# Check port is open
docker exec mariadb netstat -tlnp | grep 3306

# Test connection
docker exec wordpress mysql -h mariadb -u wordpress_user -p -e "SELECT VERSION();"

# Check logs
docker logs mariadb | tail -20
```

### SSL Certificate Warnings

Self-signed certificates trigger warnings in browsers. Workarounds:
- Click "Proceed" in browser warning
- Use `curl -k` to skip certificate verification
- For production: obtain a real certificate from a CA

---

## Summary

| Task | Command |
|------|---------|
| Initial setup | `make docker && make volumes && make domain && make build && make up` |
| Start services | `make up` |
| Stop services | `make down` |
| Full rebuild | `make clean && make build && make up` |
| View logs | `docker logs -f <service>` |
| Access database | `docker exec -it mariadb mariadb -u root -p` |
| Backup data | `tar -czf backup.tar.gz ~/data/` |
| Execute command in container | `docker exec <container> <command>` |
| Interactive shell | `docker exec -it <container> bash` |
| Full cleanup | `make fclean` |

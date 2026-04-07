# User Documentation

## Overview

This project provides a complete WordPress website stack deployed using Docker containers. The system includes:

- **Nginx**: Web server with secure HTTPS (TLS/SSL) access
- **WordPress**: Content management system with admin panel
- **MariaDB**: Database server storing all website and user data

All services run in isolated containers and communicate through an internal network, ensuring security and reliability.

---

## Getting Started

### Prerequisites

- Linux-based system with `sudo` privileges
- Docker and Docker Compose installed on your system
- At least 2GB of free disk space for data storage
- Internet connection for initial setup

### Starting the Project

The entire stack can be started with a single command:

```bash
make up
```

This will:
1. Build Docker images if they don't exist
2. Start all three services (Nginx, WordPress, MariaDB)
3. Configure domain routing (if needed)
4. Initialize the WordPress database

**Expected output:** All containers should be running, typically within 30-60 seconds.

### Stopping the Project

To stop all services while preserving data:

```bash
make down
```

This gracefully stops all containers without deleting data or configurations.

---

## Accessing the Website

### URL

Once the services are running, access the website at:

```
https://svolkau.42.fr
```

**Note:** The first access may show a security warning because the SSL certificate is self-signed. Click "Proceed" or "Advanced" to bypass the browser warning.

### WordPress Admin Panel

Access the WordPress administration dashboard at:

```
https://svolkau.42.fr/wp-admin
```

Or from the main page, click the admin link (if configured).

---

## Managing Credentials

### Where Credentials Are Stored

All passwords and sensitive information are stored in the `secrets/` directory at the project root:

```
secrets/
├── db_password.txt           # Database user password
├── db_root_password.txt      # MariaDB root password
├── wp_admin_password.txt     # WordPress admin password
└── wp_user_password.txt      # WordPress regular user password
```

**Important:** These files are readable only by the system. Never commit these files to version control (they are in `.gitignore`).

### Accessing Credentials

To view any credential:

```bash
cat secrets/db_password.txt
cat secrets/wp_admin_password.txt
cat secrets/wp_user_password.txt
cat secrets/db_root_password.txt
```

### Changing Credentials

To change credentials, edit the corresponding file in the `secrets/` directory:

```bash
# Edit the admin password
nano secrets/wp_admin_password.txt
```

Then restart the services for changes to take effect:

```bash
make down
make up
```

---

## Checking Service Status

### Quick Status Check

View all running containers:

```bash
docker ps
```

Look for three containers:
- `nginx` — Web server
- `wordpress` — Application server
- `mariadb` — Database server

All should show "Up" in the STATUS column.

### Detailed Service Health

Check individual service health:

```bash
# Check Nginx
docker inspect nginx --format='{{.State.Health.Status}}'

# Check WordPress
docker inspect wordpress --format='{{.State.Health.Status}}'

# Check MariaDB
docker inspect mariadb --format='{{.State.Health.Status}}'
```

Expected output for healthy services: `healthy`

### Viewing Logs

To troubleshoot issues, view logs from any service:

```bash
# Nginx logs
docker logs nginx

# WordPress logs
docker logs wordpress

# MariaDB logs
docker logs mariadb
```

For real-time log streaming:

```bash
docker logs -f nginx    # Follow Nginx logs (press Ctrl+C to exit)
```

### Checking Network Connectivity

Verify services can communicate:

```bash
# Check if WordPress can reach MariaDB
docker exec wordpress sh -c 'nc -z mariadb 3306 && echo "MariaDB: OK" || echo "MariaDB: FAILED"'

# Check if Nginx can reach WordPress
docker exec nginx sh -c 'nc -z wordpress 9000 && echo "WordPress: OK" || echo "WordPress: FAILED"'
```

---

## Common Administrator Tasks

### Backing Up Data

To back up the entire WordPress site and database:

```bash
# Create a backup directory
mkdir -p ~/backups
cp -r ~/data/wordpress ~/backups/wordpress_$(date +%Y%m%d_%H%M%S)
cp -r ~/data/mariadb ~/backups/mariadb_$(date +%Y%m%d_%H%M%S)
```

### Restarting a Service

To restart a specific service without stopping others:

```bash
docker restart nginx      # Restart Nginx
docker restart wordpress  # Restart WordPress
docker restart mariadb    # Restart MariaDB
```

### Accessing the Database

To access the MariaDB database directly:

```bash
docker exec -it mariadb mariadb -u root -p
# When prompted, enter the root password from: cat secrets/db_root_password.txt
```

### Full System Cleanup

To remove all containers and reset everything (WARNING: This deletes all data):

```bash
make fclean
```

Then rebuild:

```bash
make build
make up
```

---

## Troubleshooting

### Services Won't Start

1. Check Docker is running: `docker version`
2. Review logs: `docker logs wordpress`
3. Ensure ports are not blocked: `sudo netstat -tlnp | grep -E '(443|3306|9000)'`
4. Restart: `make down && make up`

### Can't Access Website

1. Verify all containers are running: `docker ps`
2. Check firewall: `sudo ufw allow 443`
3. Verify DNS entry: `cat /etc/hosts | grep svolkau.42.fr`
4. Check Nginx logs: `docker logs nginx`

### Database Connection Failed

1. Verify MariaDB is healthy: `docker inspect mariadb --format='{{.State.Health.Status}}'`
2. Check password consistency: Compare `secrets/db_password.txt` across containers
3. Restart MariaDB: `docker restart mariadb`
4. View MariaDB logs: `docker logs mariadb`

### WordPress Shows Blank Page

1. Check PHP-FPM process: `docker exec wordpress ps aux | grep php-fpm`
2. Review WordPress logs: `docker logs wordpress`
3. Verify database connection in logs: `docker logs wordpress | grep -i database`
4. Restart WordPress: `docker restart wordpress`

---

## Security Notes

- All passwords should be strong (mix of uppercase, lowercase, numbers, symbols)
- Never share the contents of the `secrets/` directory
- The SSL certificate is self-signed; use a real certificate in production
- Change default passwords immediately after initial setup
- Regularly back up data stored in `~/data/`

---

## Support

For technical issues, check:
- Docker logs: `docker logs <container_name>`
- Service health status: `docker ps`
- Network connectivity: `docker network inspect webnet`

---

## Summary

| Task | Command |
|------|---------|
| Start services | `make up` |
| Stop services | `make down` |
| View status | `docker ps` |
| View logs | `docker logs nginx` |
| Access website | `https://svolkau.42.fr` |
| Access admin panel | `https://svolkau.42.fr/wp-admin` |
| View password | `cat secrets/db_password.txt` |
| Full cleanup | `make fclean` |

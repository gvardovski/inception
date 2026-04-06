*This project has been created as part of the 42 curriculum by svolkau.*

# Inception

## Description
Inception is a system administration and containerization project focused on building a small production-like web stack with Docker Compose. The goal is to orchestrate multiple isolated services that work together reliably while respecting security and persistence constraints.

This repository provides a three-service architecture:
- `nginx`: TLS termination and reverse proxy on port `443`
- `wordpress`: PHP-FPM application service
- `mariadb`: relational database backend

The stack is designed around service isolation, healthchecks, restart policies, named networking, and persistent storage for application/database data.

### Project Design Choices
- One process role per container, with clear boundaries between reverse proxy, app, and database.
- Compose-level dependency management via `depends_on` and `service_healthy` checks.
- Sensitive values stored as Docker secrets (mounted files) rather than plain environment values.
- Persistent data stored under `~/data` and attached to containers through named volumes backed by bind mounts.

### Sources Included In The Project
- `Makefile`: helper targets for setup, build, run, cleanup, and host-domain synchronization.
- `srcs/docker-compose.yml`: service orchestration, networks, secrets, volumes, healthchecks, restart policies.
- `srcs/.env`: non-secret runtime configuration values (domain, DB names, usernames, site metadata).
- `srcs/requirements/nginx/`: Dockerfile, nginx configuration, startup script.
- `srcs/requirements/wordpress/`: Dockerfile, php-fpm config, WordPress startup logic.
- `srcs/requirements/mariadb/`: Dockerfile, MariaDB config, initialization/startup logic.
- `secrets/`: local secret files used by Compose secrets.

### Comparison Notes
#### Virtual Machines vs Docker
- Virtual machines emulate full OS instances with separate kernels, usually heavier in CPU/RAM/storage and slower to boot.
- Docker uses host kernel features (namespaces/cgroups), so containers are lighter, faster to start, and easier to compose as microservices.
- For this project, Docker is preferred for reproducibility and fast iteration while still preserving service isolation.

#### Secrets vs Environment Variables
- Environment variables are convenient for non-sensitive configuration, but can leak via process listings, logs, and inspection tools.
- Docker secrets are mounted as files with controlled access and are better suited for passwords and credentials.
- In this project, passwords are provided through files in `/run/secrets/*`, while non-sensitive options come from `.env`.

#### Docker Network vs Host Network
- Docker bridge networks isolate container communication and provide service discovery by container/service name.
- Host networking removes that isolation and can cause port conflicts while exposing services more broadly.
- This project uses a user-defined bridge network (`webnet`) so services can communicate internally and only required ports are published.

#### Docker Volumes vs Bind Mounts
- Named volumes are managed by Docker and simplify lifecycle handling.
- Bind mounts map explicit host paths, useful when data location is controlled manually.
- This project combines both: named volumes with bind-based `driver_opts` to keep persistent data at `~/data/wordpress` and `~/data/mariadb`.

## Instructions
### Prerequisites
- Linux host with `sudo` access
- Internet connection for image/package download
- Docker Engine + Docker Compose plugin (or use Makefile setup target)

### Setup And Run
1. Optional auto-install of Docker prerequisites and Docker packages:
   - `make docker`
2. Build images without cache:
   - `make build`
3. Start services:
   - `make up`
4. Check status:
   - `docker ps`

### Common Commands
- Stop stack: `make down`
- Remove containers/images/orphans: `make clean`
- Full cleanup (including data volumes and host data dirs): `make fclean`

### Access
- Domain expected by the project: `svolkau.42.fr`
- Main entrypoint: `https://svolkau.42.fr`

## Resources
### Classic References
- Docker docs: https://docs.docker.com/
- Docker Compose file reference: https://docs.docker.com/compose/compose-file/
- Nginx docs: https://nginx.org/en/docs/
- WordPress documentation: https://wordpress.org/documentation/
- WP-CLI docs: https://developer.wordpress.org/cli/commands/
- MariaDB docs: https://mariadb.com/kb/en/documentation/
- OWASP Secrets Management Cheat Sheet: https://cheatsheetseries.owasp.org/

### AI Usage Disclosure
AI assistance was used for:
- Drafting and refining shell/Docker configuration explanations.
- Reviewing healthcheck behavior and startup sequencing tradeoffs.
- Drafting and structuring this README according to the project checklist.

AI was not used to bypass understanding requirements; all configuration and runtime behavior were validated in the local environment through Docker commands and Makefile workflows.

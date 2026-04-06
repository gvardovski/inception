check-apt:
	@if command -v apt >/dev/null 2>&1; then \
		echo "✅ apt is installed"; \
	else \
		sudo dpkg -i apt_*.deb; \
		sudo apt-get install -f -y; \
		echo "✅ apt installed successfully."; \
	fi

install-prereqs:
	sudo apt update
	sudo apt install -y ca-certificates curl gnupg lsb-release
	@echo "✅ Prerequisites Installed!"

create-keyring:
	sudo install -m 0755 -d /etc/apt/keyrings
	@echo "✅ Keyrings directory was created!"

download-key:
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
	sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
	@echo "✅ Download Docker GPG key and store it in /etc/apt/keyrings!"

set-permissions:
	sudo chmod a+r /etc/apt/keyrings/docker.gpg
	@echo "✅ Permissions for the GPG key was set!"

add-repo:
	echo "deb [arch=$$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
	https://download.docker.com/linux/ubuntu $$(. /etc/os-release && echo $$VERSION_CODENAME) stable" | \
	sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	@echo "✅ Docker repository added to apt sources!"

install-docker:
	sudo apt update
	sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
	@echo "✅ Docker packages Installed!"
	
add-user-to-group:
	sudo usermod -aG docker $(USER)
	newgrp docker
	@echo "✅ Added $(USER) to docker group. Log out and back in to apply group changes."

volumes:
	sudo mkdir -p $(HOME)/data/wordpress
	sudo mkdir -p $(HOME)/data/mariadb
	sudo chown -R $(USER):$(USER) $(HOME)/data

domain:
	@LOCAL_IP=$$(hostname -I | awk '{print $$1}'); \
	if grep -qE "(^|[[:space:]])svolkau\.42\.fr([[:space:]]|$$)" /etc/hosts; then \
		echo "✅ Domain svolkau.42.fr is already configured in /etc/hosts"; \
	else \
		echo "$$LOCAL_IP svolkau.42.fr" | sudo tee -a /etc/hosts > /dev/null; \
		echo "✅ Added svolkau.42.fr -> $$LOCAL_IP to /etc/hosts"; \
	fi

docker: check-apt install-prereqs create-keyring download-key set-permissions add-repo install-docker add-user-to-group volumes
	@echo "✅ Docker installation complete!"

build: volumes
	cd srcs/ && docker compose build --no-cache

up: domain
	cd srcs/ && docker compose up -d
	@$(MAKE) sync-domain-ip

sync-domain-ip:
	@NGINX_IP=$$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nginx 2>/dev/null); \
	if [ -z "$$NGINX_IP" ]; then \
		exit 1; \
	fi; \
	HOSTS_IP=$$(awk '!/^[[:space:]]*#/ {for (i = 2; i <= NF; i++) if ($$i == "svolkau.42.fr") ip = $$1} END {print ip}' /etc/hosts); \
	if [ "$$HOSTS_IP" = "$$NGINX_IP" ]; then \
		exit 0; \
	else \
		sudo sed -i -E '/(^|[[:space:]])svolkau\.42\.fr([[:space:]]|$$)/d' /etc/hosts; \
		echo "$$NGINX_IP svolkau.42.fr" | sudo tee -a /etc/hosts > /dev/null; \
	fi

down:
	cd srcs/ && docker compose down

clean:
	cd srcs/ && docker compose down --rmi all --remove-orphans
	@echo "✅ Stopped and removed Docker containers and volumes."

fclean:
	cd srcs/ && docker compose down -v --rmi all --remove-orphans
	sudo rm -rf $(HOME)/data/wordpress
	sudo rm -rf $(HOME)/data/mariadb
	@echo "✅ Cleaned up Docker containers, volumes, images, and configuration files."

.PHONY: build up down docker install-docker add-repo set-permissions download-key create-keyring install-prereqs \
	check-apt add-user-to-group volumes domain sync-domain-ip

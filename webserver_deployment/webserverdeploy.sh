#!/bin/bash

# ------ Config files and variable declarations -------------------------------------------
log (){
    echo -e "[INFO] $1"
}

release_file=/etc/os-release
LOG_FILE="/var/log/server-bootstrap.log"
exec > >(tee -a "$LOG_FILE") 2>&1


nginx_base="/srv/webserver/nginx"

mkdir -p "$nginx_base/conf.d" "$nginx_base/logs"

cat > "$nginx_base/conf.d/default.conf" <<'EOF'
server {
    listen 80;
    server_name _;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    location / {
        return 200 "OK\n";
    }
}
EOF


#------------------------------------------------------------------------------------------
#Enable safemode
set -euo pipefail

#Exit if not runnning as root 
if [[ $EUID -ne 0 ]]; then 
    echo -e "This script must be run as root /a/r" >&2
    exit 1
fi

# Check OS
if grep -q "Debian" $release_file || grep -q "Ubuntu" $release_file; then
    export DEBIAN_FRONTEND=noninteractive
else
    echo -e "This script is for Debian/Ubuntu servers /a"
    exit 2
fi

# -----------------------------System updates & base hardening ---------------------------

apt update && apt upgrade -y
# install core utilities
apt install curl wget ca-certificates gnupg lsb-release unattended-upgrades
# Enable automatic security updates

# --------------------------  Time, Locale & Basics --------------------------------------

timedatectl set-timezone African/Lagos
systemctl enable systemd-timesyncd

# -------------------------- Docker install, setup & config ------------------------------
install_docker(){
    if ! command -v docker >/dev/null 2>&1; then
            curl -fsSL https://get.docker.com | sh 
    fi
}
# ------------------------------------
# install docker compose
# ------------------------------------
install_docker_compose(){
    if docker compose version >/dev/null 2>&1; then
        log "Docker compose already installed"
        return
    fi

    log "Installing docker compose plugin..."
    mkdir -p /usr/local/lib/docker/cli-plugins

    curl -SL https://github.com/docker/compose/releases/download/v2.25.0/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose

    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

}

# ---------------------------------------
# Enable docker
# ---------------------------------------
start_docker(){
    log "Starting and Enabling Docker..."
    systemctl enable docker
    systemctl start docker
}

# ----------------------------------------
# Nginx via docker compose
# ----------------------------------------
create_compose_file(){
    log "Creating docker-compose.yml..."

    cat <<'EOF' > docker-compose.yml

version: "3.8"

services:
  nginx:
    image: nginx:stable
    container_name: nginx
    restart: always
    ports:
      - "80:80"
    volumes:
      - /srv/webserver/nginx/conf.d:/etc/nginx/conf.d
      - /var/log/nginx:/var/log/nginx

EOF
}

# ---------------------------------------
# Main
# ---------------------------------------
main (){
    install_docker
    install_docker_compose
    start_docker
    create_compose_file

    log "Starting nginx container..."
    docker compose up -d

    log "Deployment complete. Nginx is running on port 80"
}

# -----------------  configure ufw ------------------

if ! command -v ufw >/dev/null 2>&1; then
    echo -e "Firewall not installed - installing ufw /a"
    apt install -y ufw
fi

ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80,443/tcp
ufw --force enable

#------------------------ install fail2ban -------------------------------------


if ! command -v fail2ban-client >/dev/null 2>&1;
then
    echo "Fail2ban not installed - Installing fail2ban...."
    apt install -y fail2ban
fi
systemctl enable --now fail2ban

cat <<'EOF' > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
backend = systemd

[sshd]
enabled = true
maxretry = 3
bantime = 24h

[nginx-http-auth]
enabled = true
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/error.log

[nginx-badbots]
enabled = true
ports = http,https
filter = nginx-badbots
logpath = /var/log/nginx/access.log
maxretry = 2

[nginx-noscript]
enabled = true
EOF

mkdir -p /var/log/nginx

for logfile in /var/log/nginx/access.log /var/log/nginx/error.log; do
    if [ ! -f "$logfile" ]; then
        log "Creating missing log file: $logfile"
        touch "$logfile"
        chmod 644 "$logfile"
    fi
done
# --------------- Bootstrap idempotency check ---------------------------

if systemctl is-active --quiet nginx; then
	log "Stopping host nginx to free port 80"
	systemctl stop nginx
	systemctl disable nginx
fi


if systemctl is-active --quiet apache2; then
	log "Stopping host apache2 to free port 80"
	systemctl stop apache2
	systemctl disable apache2
fi

# -----------------------------------------------------------------------
main
systemctl restart fail2ban
fail2ban-client status
fail2ban-client status nginx-badbots

if fail2ban-client status nginx-badbots >/dev/null 2>&1; then
    log "Bootstrap complete"
    log "Script log: /var/log/server-bootstrap.log"
    log "Nginx access log: /var/log/nginx/access.log"
    log "Nginx error log: /var/log/nginx/error.log"
    log "Fail2Ban log: /var/log/fail2ban.log"
fi



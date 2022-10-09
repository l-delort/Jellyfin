#!/usr/bin/env bash

set -o errexit

# The parent directory is supposed to be the root directory of github repository.
currdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
parentdir="$(dirname "$currdir")"
if [ ! -d "$parentdir" ]; then
  echo "ERROR : $parentdir not found."
  exit 1
fi

if ! [ -x "$(command -v dos2unix)" ]; then
  apt-get update && apt-get install -y dos2unix
fi

if [ -f .env ]; then
  dos2unix .env
  source .env
else
  echo "ERROR : .env file not found"
  exit 1
fi

# docker & docker-compose version
# Run "apt-cache madison docker-ce" to confirm the docker version.
DOCKER_VERSION=${DOCKER_VERSION:-20.10.18}
DOCKER_COMPOSE_VERSION=${DOCKER_COMPOSE_VERSION:-1.29.2}


# Install the dependency packages
install-deps() {
  apt-get update && apt-get install -y \
    curl wget htop dos2unix zip unzip jq \
    ca-certificates curl gnupg lsb-release \
    nano vim emacs less tree \
    screen screenfetch ntpdate lvm2 \
    libpam-google-authenticator \
    apticron apt-listchanges \
    msmtp msmtp-mta build-essential
}

# Docker installation
install-docker() {
  if ! [ -x "$(command -v docker)" ]; then
    echo "Installing docker ..."

    local system_id=$(. /etc/os-release; echo "$ID")
    local system_version_codename=$(. /etc/os-release; echo "$VERSION_CODENAME")
    local docker_version_full="5:${DOCKER_VERSION}~3-0~${system_id}-${system_version_codename}"


    curl -fsSL https://download.docker.com/linux/${system_id}/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/${system_id} \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update
    apt-get install -y docker-ce=${docker_version_full} docker-ce-cli=${docker_version_full} containerd.io
  fi
  docker --version
}

# Docker-compose installation
install-docker-compose() {
  if ! [ -x "$(command -v docker-compose)" ]; then
    echo "Installing docker-compose ..."
    curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-Linux-x86_64 -o /usr/bin/docker-compose
    chmod +x /usr/bin/docker-compose
  fi
  docker-compose --version
}



configure() {
  cd "$parentdir"

  find . -type f -name "*.sh" -exec dos2unix {} +
  find . -type f -name "*.sh" -exec chmod +x {} +

  ############ Create some users ############
  echo "Create some users"
  local user1=${SSH_DOCKER_USERNAME:-docker_user1}
  if id -u 2002 >/dev/null 2>&1; then
    echo "User already exists with $user1"
  else
    echo "Add a user $user1"
    # We will not set the password for docker_user1 because no need ssh login to this user.
    useradd -u 2002 $user1 -d /opt/prestashop -s /bin/bash
  fi

  
  ############ Create a backup directory ############
  if [ ! -d "/backup" ]; then
    echo "Create a backup directory : /backup"
    mkdir -p /data/backup/
    ln -s /data/backup /backup
  fi

  ############ Initialize bashrc ############
  echo "Initialize bashrc"
  local system_id=$(. /etc/os-release; echo "$ID")
  if [ ${system_id} = "debian" ]; then
    if [ -f "/home/debian/.bashrc" ]; then
      if ! grep -q "screenfetch" /home/debian/.bashrc; then
        echo "screenfetch" >> /home/debian/.bashrc
      fi
    fi

    if [ -f "/root/.bashrc" ] && [ ! -f "/root/.bashrc.org" ]; then
      cp /root/.bashrc /root/.bashrc.org
    fi
    cat > /root/.bashrc << EOF
export LS_OPTIONS='--color=auto'
alias ls='ls \$LS_OPTIONS'
alias ll='ls \$LS_OPTIONS -l'
alias l='ls \$LS_OPTIONS -lA'
alias grep='grep \$LS_OPTIONS'
PS1='\${debian_chroot:+(\$debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
EOF
  fi

  # ############ Initialize nginx.conf ############
  # if [ "$(ls -A conf/nginx/*.conf)" ]; then
  #   echo "Initialize nginx.conf"
  #   # Replace server name in the nginx conf files.
  #   sed -i "s/{{DOMAIN_NAME}}/$DOMAIN_NAME/g" conf/nginx/*.conf
  # fi

}

start-containers() {
  cd "$parentdir"

  echo
  echo "Starting containers ..."
  docker-compose up -d
  sleep 3

  # Other command to check: $ docker-compose ps -q nginx
  # But the command above return ERROR when no running such service.
  # Therefore, we use "docker ps" command.
  # local nginx_container=$(docker ps -qf name=nginx)
  # if [ ! -z "${nginx_container}" ]; then
  #   echo
  #   echo "Reloading nginx ..."
  #   docker-compose exec nginx nginx -s reload
  # fi
}

main() {
  install-deps
  install-docker
  install-docker-compose
  #configure

  start-containers

  echo
  echo "Everything installed."
}

main

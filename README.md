# Minecraft server configs

This repository holds Docker Compose and environment files for running [itzg/minecraft-server](https://hub.docker.com/r/itzg/minecraft-server/) on a host such as an AWS EC2 Ubuntu instance.

## Server setup (Ubuntu EC2)

Use the initialization script once on a fresh Ubuntu server to install OpenJDK 21, Docker, and the Docker Compose v2 plugin, then enable the Docker service and grant your SSH user permission to run Docker without `sudo`.

### Running the script

Run it as the Linux user that should manage Docker (typically `ubuntu` on Ubuntu AMIs). Do not run it as a root-only session without a normal login user, because the script must know which account to add to the `docker` group.

```bash
cd /minecraft-server-configs/scripts
chmod +x ec2-ubuntu-init.sh
./ec2-ubuntu-init.sh
```

If you prefer to invoke it with `sudo` (for example when your user lacks direct `sudo` passwordless access in some setups), use `-E` so `SUDO_USER` is preserved and the correct user is added to the `docker` group:

```bash
sudo -E ./ec2-ubuntu-init.sh
```

The script runs `apt-get update`, upgrades packages, installs `openjdk-21-jdk`, `docker.io`, and `docker-compose-v2`, enables and starts Docker, and runs `usermod -aG docker` for your user.

### After the script finishes

Group changes apply after a new login. Either disconnect your SSH session and connect again, or run:

```bash
newgrp docker
```

Then confirm Docker works:

```bash
docker ps
```

### Network

Open TCP port **25565** in your EC2 security group (and any host firewall) if clients should reach the Minecraft server from the internet.

## Running Docker Compose (Minecraft)

The Compose file lives under `survival/` and expects a `.env` file in the same directory. World and server data persist in `survival/data/` on the host, mounted to `/data` in the container.

### Steps

1. On the server, go to the `survival` directory (adjust the path if you cloned elsewhere):

```bash
cd /minecraft-server-configs/survival
```

2. Ensure `.env` exists and contains the settings you want (version, memory, `SERVER_NAME`, `RCON_PASSWORD`, and other [itzg/minecraft-server environment variables](https://docker-minecraft-server.readthedocs.io/)).

3. Start the server in the background:

```bash
docker compose up -d
```

4. Follow logs:

```bash
docker compose logs -f
```

5. Stop the server:

```bash
docker compose stop
```

6. Stop and remove the container (data under `./data` is kept on disk):

```bash
docker compose down
```

The Minecraft port **25565** is published to the host as defined in `compose.yml`. Connect with your client to `YOUR_HOST_OR_IP:25565` once the container is healthy and networking allows it.

### RCON from the EC2 host

The [itzg/minecraft-server](https://hub.docker.com/r/itzg/minecraft-server/) image enables RCON inside the container and ships `rcon-cli`. You do not need to expose RCON port 25575 on the public internet if you run commands over SSH on the server. Authentication uses `RCON_PASSWORD` from `.env`.

**Container name**

Compose sets `container_name` to `${SERVER_NAME:-Minecraft}-mc-server` (see `survival/compose.yml`). In the examples below, `Tobias-mc-server` matches `SERVER_NAME=Tobias` in `.env`. Replace it with your real container name if you changed `SERVER_NAME`, or read it from `docker ps` under the `NAMES` column. In the commands that follow, substitute `<container-name>` with that value.

**Interactive RCON shell**

`docker exec` runs a program inside a running container. `-i` keeps stdin open and `-t` allocates a terminal so you get an interactive prompt. Use this when you want to type server commands at RCON until you exit:

```bash
docker exec -it <container-name> rcon-cli
```

Example when `SERVER_NAME` is `Tobias`:

```bash
docker exec -it Tobias-mc-server rcon-cli
```

**One-shot command**

Without `-it`, `docker exec` runs a single command and exits. Here the server broadcasts a chat message (passes `say Hello from RCON` to `rcon-cli`):

```bash
docker exec <container-name> rcon-cli say Hello from RCON
```

Example:

```bash
docker exec Tobias-mc-server rcon-cli say Hello from RCON
```

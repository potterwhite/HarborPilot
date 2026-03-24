# Quick Start Guide

> **Related:** [中文版 →](quick_start_cn.md)

This guide walks you through setting up HarborPilot from scratch on a fresh Ubuntu host — from installing Docker all the way to having your development container running.

> **Platform Support**
> - ✅ **Ubuntu host** — fully supported
> - ❌ **Windows host** — support has been dropped

---

## Prerequisites

| Requirement | Notes |
|---|---|
| Ubuntu 20.04 / 22.04 host | Other Debian-based distros may work |
| Internet or LAN access | To pull the base Docker image |
| Harbor registry access | Get credentials from your administrator |
| Harbor CA certificate | `project_handover/clientside/ubuntu/harbor.crt` (included in the repo) |

---

## Step 1 — Install Docker

```bash
# Add Docker's official GPG key
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y \
    docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

# Add your user to the docker group (avoids needing sudo for every docker command)
sudo usermod -aG docker "$USER"
newgrp docker
```

---

## Step 2 — Trust the Harbor Registry Certificate

The Harbor registry uses a self-signed TLS certificate. Docker must be told to trust it, otherwise all `docker pull` / `docker push` operations will fail with a certificate error.

```bash
# Replace <registry-ip> and <registry-port> with the values in your platform .env file
# (UBUNTU_SERVER_IP and UBUNTU_SERVER_PORT)
REGISTRY_HOST="<registry-ip>:<registry-port>"

sudo mkdir -p "/etc/docker/certs.d/${REGISTRY_HOST}"
sudo cp ./project_handover/clientside/ubuntu/harbor.crt \
        "/etc/docker/certs.d/${REGISTRY_HOST}/ca.crt"

sudo systemctl restart docker
```

> **Example** (rk3588s platform):
> ```bash
> sudo mkdir -p /etc/docker/certs.d/192.168.0.19:8443
> sudo cp ./project_handover/clientside/ubuntu/harbor.crt \
>         /etc/docker/certs.d/192.168.0.19:8443/ca.crt
> sudo systemctl restart docker
> ```

---

## Step 3 — Log In to the Harbor Registry

```bash
docker login <registry-ip>:<registry-port>
# Example:
docker login 192.168.0.19:8443
```

Enter the username and password provided by your administrator. Docker will cache the credentials, so you only need to do this once per host.

---

## Step 4 — Clone the Repository

```bash
git clone <repo-url>
cd HarborPilot
```

---

## Step 5 — Build the Docker Image

Run the `harbor` entry script from the repository root. It will:
1. Ask you to pick a target platform (e.g. `rk3588s`, `rk3568`, …)
2. Set up config symlinks automatically
3. Build the multi-stage Docker image
4. Tag and push to your Harbor registry

```bash
./harbor
```

During the run, the script will detect if you are not logged in to the registry and prompt you to log in before proceeding.

> **Tip:** Press `n` at any interactive prompt to skip that optional step (e.g. build, tag, push, cleanup), or just wait for the 10-second countdown to auto-proceed.

---

## Step 6 — Start Your Development Container

Once the build is complete, the script will print a **Next Steps** banner. Follow it:

```bash
./project_handover/clientside/ubuntu/ubuntu_only_entrance.sh start
```

Available commands:

| Command | Effect |
|---|---|
| `start` | Create and start the container (pulls image from registry if local image not found) |
| `stop` | Stop the running container |
| `restart` | Restart the container |
| `recreate` | Remove and recreate the container with the current config |
| `remove` | Stop and delete the container (image is kept) |

---

## Step 7 — (Optional) Configure SSH Access

Add an entry to your `~/.ssh/config` for convenient access from your host or IDE:

```
Host container_<PRODUCT_NAME>
    Hostname 127.0.0.1
    Port <CLIENT_SSH_PORT>
    User developer
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

Replace `<PRODUCT_NAME>` and `<CLIENT_SSH_PORT>` with the values from your platform's `.env` file. For example, for `rk3588s`:

```
Host container_rk3588s
    Hostname 127.0.0.1
    Port 2109
    User developer
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

Then connect with:

```bash
ssh container_rk3588s
```

---

## Step 8 — (Optional) Pull the SDK Inside the Container

Two methods are supported, depending on how your SDK repository is managed:

### Method A — Git (single repo)

```bash
# Inside the container
pull_sdk.sh
```

### Method B — Repo (Android-style manifest)

Ask your administrator or SDK developer for the manifest URL, then run the provided script snippet (see `project_handover/clientside/ubuntu/ReadMe.md` for the full command).

---

## Platform Port Reference

| Platform | OS | CLIENT_SSH_PORT | SERVER_SSH_PORT | GDB_PORT |
|---|---|---|---|---|
| rk3588s | Ubuntu 22.04 | 2109 | 2110 | 2345 |
| rv1126bp | Ubuntu 22.04 | 2119 | 2120 | 2355 |
| rk3568 | Ubuntu 20.04 | 2129 | 2130 | 2365 |
| rv1126 | Ubuntu 22.04 | 2139 | 2140 | 2375 |
| rk3568-ubuntu22 | Ubuntu 22.04 | 2149 | 2150 | 2385 |

---

## Troubleshooting

### `pull access denied` when pulling image

You are not logged in, or your credentials have expired.

```bash
docker login <registry-ip>:<registry-port>
```

### `SSL certificate problem: self-signed certificate`

The Harbor CA certificate has not been installed for Docker.
Repeat [Step 2](#step-2--trust-the-harbor-registry-certificate).

### Container exits immediately after `start`

Check that `HOST_VOLUME_DIR` in your platform's `.env` file points to an existing directory on the host.

### `HAVE_HARBOR_SERVER` shows empty / push is skipped unexpectedly

Make sure you are running the scripts through the `harbor` entry point (which loads all three config layers in order), not by sourcing the platform `.env` directly.

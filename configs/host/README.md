# Host-Level Configuration Overrides

This directory contains **per-machine** configuration overrides.

## How It Works

The configuration system loads in this order (later overrides earlier):

```
Layer 1: configs/defaults/*.env       ← Global defaults
Layer 2: configs/platforms/<platform>  ← Platform-specific overrides
Layer 3: configs/host/<hostname>.env   ← ★ This layer (optional)
```

If `configs/host/<hostname>.env` does not exist, the system skips this layer entirely.
Only variables you explicitly set here will override the platform or default values.

## Usage

1. Find your hostname:
   ```bash
   hostname
   ```

2. Create a file named `<your-hostname>.env` in this directory:
   ```bash
   # Example: for a host named "my-desktop"
   cat > configs/host/my-desktop.env << 'EOF'
   # Override GPU setting for this machine
   USE_NVIDIA_GPU="true"
   CONTAINER_SHM_SIZE="1g"

   # Override volume path for this machine
   HOST_VOLUME_DIR="/mnt/ssd/volumes/rk3588"
   EOF
   ```

3. Done. The system auto-loads this file based on `hostname`.

## What to Put Here

- `USE_NVIDIA_GPU` — whether this machine has an NVIDIA GPU
- `CONTAINER_SHM_SIZE` — shared memory size (GPU workloads need more)
- `HOST_VOLUME_DIR` — host-specific volume mount path
- `EXTRA_VOLUMES_LIST` — additional volume mounts for this machine
- Any variable that differs between machines sharing the same platform config

## What NOT to Put Here

- Platform-specific settings (those go in `configs/platforms/`)
- Global defaults (those go in `configs/defaults/`)
- Anything that should be shared across all machines

## Git Policy

**Files in this directory are `.gitignored`.** They are local to each machine and should NOT be committed to the repository. Only `.gitkeep` and `README.md` are tracked.

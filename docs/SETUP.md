# Setup

The lab needs a real **Linux kernel** with the Open vSwitch module, **4 CPUs, 6 GB RAM and 20 GB of disk** for
the Linux machine, and internet for the one-time install. Pick your platform:

| You have | Use |
|---|---|
| Ubuntu 22.04/24.04 (laptop or lab PC) | Nothing extra: go to [Install](#install) |
| Windows 10/11 | A full Ubuntu VM with **Multipass** (simplest) or **VirtualBox**. See below |
| macOS (Apple Silicon or Intel) | An Ubuntu VM with **Lima**. See below |

> **Why not WSL2 or Docker Desktop?** The lab needs the `openvswitch` kernel module. A full Ubuntu VM always has
> it; WSL2 and Docker Desktop kernels may not. If you try WSL2 anyway, `install.sh` checks for the module and
> stops with a clear message if it is missing.

## Windows: Multipass

1. Install Multipass from https://canonical.com/multipass (free). On Windows Home it uses VirtualBox; install
   VirtualBox first if the installer asks.
2. In PowerShell:
   ```powershell
   multipass launch 24.04 --name clab --cpus 4 --memory 6G --disk 20G
   multipass shell clab
   ```
3. Continue with [Install](#install) inside the VM. For the ONOS GUI, find the VM's IP with
   `multipass info clab` and open `http://<that IP>:8181/onos/ui` in your Windows browser.

**VirtualBox instead:** create an Ubuntu 24.04 Server VM (4 CPUs, 6 GB, 20 GB) and add a port forward
(host 8181 → guest 8181) under Settings → Network → Advanced → Port Forwarding.

## macOS: Lima

```bash
brew install lima
limactl create --name=clab --cpus=4 --memory=6 --disk=20 template:ubuntu-24.04   # Intel Mac
# Apple Silicon: add  --vm-type=vz --rosetta  (ONOS is an amd64 image and runs under Rosetta)
limactl start clab
limactl shell clab
```

Lima forwards ports automatically, so the ONOS GUI opens at http://localhost:8181/onos/ui in your Mac
browser. Your Mac home folder is visible read-only inside the VM. Clone the repo inside the VM's own home
directory (`cd ~` first).

## Install

Inside Ubuntu:

```bash
cd ~
git clone https://github.com/ashokkmr1/sdn-nfv-lab.git
cd sdn-nfv-lab
bash scripts/install.sh
```

It installs Open vSwitch, Docker and containerlab, then pulls and builds the images (~1.5 GB). When it
finishes, **log out and back in** so your user can run `docker` (on Lima: `exit`, then
`limactl stop clab && limactl start clab && limactl shell clab`).

```bash
cd ~/sdn-nfv-lab
bash scripts/up.sh
```

`up.sh` creates the three OVS bridges, starts ONOS and OS-Ken, deploys both labs, and runs `preflight.sh`.
Wait for **ALL GREEN**. ONOS takes 30 s to a few minutes to start the first time.

## Everyday commands

| Command | Does |
|---|---|
| `bash scripts/up.sh` | Bring everything up. Run it after every reboot: it re-cables the containers |
| `bash scripts/preflight.sh` | Green/red checklist |
| `bash scripts/reset.sh` | Back to the start state in 2 s: empty flow tables, no controller, firewall blocking web |
| `bash scripts/demo1.sh [step]` | Guided Demo 1 (press Enter per command). `CTRL=osken bash scripts/demo1.sh 4` uses OS-Ken |
| `bash scripts/demo2.sh [step]` | Guided Demo 2 |
| `bash scripts/down.sh` | Remove all labs and bridges |

## Troubleshooting

| Symptom | Fix |
|---|---|
| `install.sh`: no openvswitch kernel module | You are on WSL2 or a container: use a full Ubuntu VM (above) |
| `docker: permission denied` | Log out and back in (or restart the VM) after `install.sh` |
| Preflight: "hosts are cabled" red | You rebooted: run `bash scripts/up.sh` |
| ONOS REST not answering | Give it a few minutes on first start; `docker logs --tail 50 clab-ctrl-onos`; or use `CTRL=osken` |
| `is_connected` false | `ping 172.20.20.20` from the VM; preflight shows whether the ONOS `openflow` app is ACTIVE |
| Ping fails with ONOS connected | The first 1–2 pings are often lost while ONOS installs rules; retry |
| No hosts in the ONOS GUI | Hosts appear only after they send traffic: ping first, then press **H** in the topology view |
| OS-Ken container exits (`osken-manager` not found) | `docker build -t osken:local images/osken` (the Dockerfile pins os-ken 3.1.1) and redeploy `labs/ctrl.clab.yml` |
| Anything else | `bash scripts/reset.sh`; if still broken, `bash scripts/down.sh && bash scripts/up.sh` |

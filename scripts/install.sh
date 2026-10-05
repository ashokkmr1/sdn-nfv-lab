#!/usr/bin/env bash
# ONE-TIME setup on Ubuntu 22.04/24.04 (native, WSL2, or a Linux VM on a Mac). Needs internet, ~10 min, ~1.5 GB.
#   cd sdn-nfv-lab && bash scripts/install.sh      (see docs/SETUP.md)
# Afterwards: log out of the machine and back in (docker group), then run scripts/up.sh
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== packages"
sudo apt-get update
sudo apt-get install -y curl jq openvswitch-switch ethtool tcpdump python3

echo "== docker-ce + containerlab"
curl -sL https://containerlab.dev/setup | sudo -E bash -s "all"
sudo usermod -aG docker "$USER" || true

echo "== open vswitch"
sudo systemctl enable --now openvswitch-switch
if ! sudo modprobe openvswitch 2>/dev/null; then
  echo "ERROR: this Linux kernel has no openvswitch module, which the labs need."
  echo "       On Windows/WSL2 use a full Ubuntu VM instead (Multipass or VirtualBox): see docs/SETUP.md"
  exit 1
fi
sudo ovs-vsctl --may-exist add-br clabtest && sudo ovs-dpctl show && sudo ovs-vsctl del-br clabtest

if [ "$(uname -m)" = aarch64 ]; then   # ARM (e.g. Apple Silicon VM): ONOS is amd64-only, so check emulation works
  echo "== amd64 emulation check (should print x86_64)"
  sudo docker run --rm --platform linux/amd64 alpine uname -m
fi

echo "== images"
sudo docker pull wbitt/network-multitool:latest
sudo docker pull nicolaka/netshoot:latest
sudo docker pull --platform linux/amd64 onosproject/onos:2.7-latest
sudo docker build -t osken:local images/osken
sudo docker build -t vnf-fw:local images/vnf-fw

chmod +x scripts/*.sh images/vnf-fw/fw.sh
containerlab version
echo
echo "Done. Now:  exit   (then re-enter the machine so the docker group applies)  and run  scripts/up.sh"

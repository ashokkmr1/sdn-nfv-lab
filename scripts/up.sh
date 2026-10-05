#!/usr/bin/env bash
# Bring the whole lab up (also after every reboot: it re-cables the containers):
#   1. OVS bridges   2. controllers (ONOS warm-up)   3. demo labs   4. preflight
set -euo pipefail
cd "$(dirname "$0")/.."
sudo modprobe openvswitch
sudo modprobe -a bridge nft_meta_bridge 2>/dev/null || true   # lets the firewall VNF use nftables (else tc fallback)
sudo systemctl start openvswitch-switch
bash scripts/bridges.sh

echo "== controllers"
if docker ps --format '{{.Names}}' | grep -q '^clab-ctrl-onos$'; then
  echo "controllers already running (keeping ONOS warm)"
else
  sudo containerlab deploy -t labs/ctrl.clab.yml --reconfigure
fi
echo "waiting for ONOS (can take several minutes under Rosetta)..."
for i in $(seq 1 120); do
  st=$(curl -s -u onos:rocks http://localhost:8181/onos/v1/applications/org.onosproject.fwd 2>/dev/null | jq -r .state 2>/dev/null || true)
  [ "$st" = "ACTIVE" ] && { echo "ONOS ready after ~$((i*5))s"; break; }
  sleep 5
done

echo "== demo labs"
sudo containerlab deploy -t labs/basics.clab.yml --reconfigure
sudo containerlab deploy -t labs/sdn.clab.yml --reconfigure
sudo containerlab deploy -t labs/nfv.clab.yml --reconfigure
bash scripts/preflight.sh

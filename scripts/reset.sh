#!/usr/bin/env bash
# Put both demos back to their starting state in ~2 seconds (labs stay deployed, ONOS stays warm).
set -uo pipefail
for b in s1 s2 br-nfv; do
  sudo ovs-vsctl del-controller "$b"
  sudo ovs-ofctl -O OpenFlow13 del-flows "$b"
done
docker exec clab-nfv-fw /fw.sh block >/dev/null 2>&1 || true
for h in clab-basics-pc1 clab-basics-pc2 clab-sdn-h1 clab-sdn-h2 clab-sdn-h3; do   # forget ARP, so it shows again
  docker exec "$h" ip neigh flush dev eth1 >/dev/null 2>&1 || true
done
echo "reset: bridges empty, no controllers, firewall VNF blocking web, ARP tables cleared"

#!/usr/bin/env bash
# LIVE DEMO 2 (NFV): insert a firewall VNF into the path of web traffic using only flow rules.
#   ./scripts/demo2.sh        ./scripts/demo2.sh 2   (start at step 2)
source "$(dirname "$0")/lib.sh"
cd "$DEMO_DIR"
CHAIN=0x5fc   # cookie that tags our service-chain rules so we can remove them in one go

if step 0; then
say "0 · The NFV lab: client, web server, and a firewall that is just a container (the VNF)"
run "sudo containerlab inspect -t labs/nfv.clab.yml"
fi

if step 1; then
say "1 · Plain path: client <-> web, straight through the switch"
run "$OF add-flow br-nfv 'priority=10,in_port=nfv-client,actions=output:nfv-web'"
run "$OF add-flow br-nfv 'priority=10,in_port=nfv-web,actions=output:nfv-client'"
run "docker exec clab-nfv-client curl -s -m3 http://10.1.0.2 | head -1"
fi

if step 2; then
say "2 · Service chaining: steer ONLY web traffic (tcp/80) through the firewall VNF"
run "$OF add-flow br-nfv 'cookie=$CHAIN,priority=200,tcp,in_port=nfv-client,tp_dst=80,actions=output:nfv-fwin'"
run "$OF add-flow br-nfv 'cookie=$CHAIN,priority=200,in_port=nfv-fwout,actions=output:nfv-web'"
run "$OF add-flow br-nfv 'cookie=$CHAIN,priority=200,tcp,in_port=nfv-web,tp_src=80,actions=output:nfv-fwout'"
run "$OF add-flow br-nfv 'cookie=$CHAIN,priority=200,in_port=nfv-fwin,actions=output:nfv-client'"
run "(docker exec clab-nfv-client curl -s -m3 http://10.1.0.2 || echo '>>> BLOCKED by the firewall VNF (no reply in 3 s)') | head -1"
note "Ping is NOT in the chain, so it still works:"
run "docker exec clab-nfv-client ping -c2 10.1.0.2"
note "The VNF counted what it dropped:"
run "docker exec clab-nfv-fw /fw.sh status"
fi

if step 3; then
say "3 · Change policy inside the VNF, with no re-cabling"
run "docker exec clab-nfv-fw /fw.sh allow"
run "docker exec clab-nfv-client curl -s -m3 http://10.1.0.2 | head -1"
note "Remove the VNF from the path by deleting the chain rules (matched by cookie):"
run "$OF del-flows br-nfv 'cookie=$CHAIN/-1'"
run "$OF --names dump-flows br-nfv"
fi

if step 4; then
say "4 · (optional) Passive VNF: mirror traffic to an IDS"
run "$OF mod-flows br-nfv 'in_port=nfv-client,actions=output:nfv-web,output:nfv-ids'"
run "(docker exec clab-nfv-ids timeout 5 tcpdump -lni eth1 -c 6 2>/dev/null &) ; sleep 1; docker exec clab-nfv-client curl -s -m3 -o /dev/null http://10.1.0.2; sleep 2"
fi
say "Demo 2 done.  Reset with: scripts/reset.sh"

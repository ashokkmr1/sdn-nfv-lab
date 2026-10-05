#!/usr/bin/env bash
# LIVE MOMENTS before the SDN demo: from a cable to a switch, then take the switch's brain out.
#   bash scripts/basics.sh 1 1   two hosts, one cable                     (slide "Why networks had to change")
#   bash scripts/basics.sh 3 3   a switch: brain + muscle in one box       (slide "Three planes inside every network device")
#   bash scripts/basics.sh 4 4   split: remove the switch's built-in brain (slide "Separate the brain from the muscle")
# Step 2 ("why a switch?") is a slide, not a demo. Start from scripts/reset.sh.
source "$(dirname "$0")/lib.sh"
cd "$DEMO_DIR"

if step 1; then
say "1 · Two Linux hosts, one cable"
run "grep -A1 endpoints labs/basics.clab.yml | tail -1"
run "docker exec clab-basics-pc1 ip -br addr show eth1"
note "Watch the wire on pc2 while pc1 pings it: first ARP (who has 10.9.0.2?), then ICMP"
run "(docker exec clab-basics-pc2 timeout 5 tcpdump -lni eth1 -c 6 2>/dev/null &) ; sleep 1; docker exec clab-basics-pc1 ping -c2 10.9.0.2; sleep 2"
note "pc1 remembers who answered: its ARP table"
run "docker exec clab-basics-pc1 ip neigh show dev eth1"
fi

if step 3; then
say "3 · A switch: control plane and data plane in one box"
run "sudo ovs-vsctl list-ports s1"
note "Give s1 its built-in, vendor-style brain: one rule, NORMAL = 'behave like an ordinary learning switch'"
run "$OF add-flow s1 'priority=0,actions=NORMAL'"
run "$OF dump-flows s1"
run "docker exec clab-sdn-h1 ping -c2 10.0.0.2"
note "CONTROL PLANE inside the box: the MAC table the switch learned by itself"
run "sudo ovs-appctl fdb/show s1"
note "DATA PLANE inside the box: the fast-path cache in the kernel that actually forwards the packets"
run "(docker exec clab-sdn-h1 ping -c3 -i 0.3 10.0.0.2 >/dev/null &) ; sleep 0.6; sudo ovs-dpctl dump-flows | grep -E 'eth_type\(0x0800\)' | cut -c1-150"
note "Both planes live in the same box, and you cannot change how it decides"
fi

if step 4; then
say "4 · Split: take the brain out of the switch"
run "$OF del-flows s1"
run "$OF dump-flows s1"
note "fail_mode=secure: with no rules and no controller, the switch drops everything"
run "sudo ovs-vsctl get-fail-mode s1; sudo ovs-vsctl get-controller s1"
run "docker exec clab-sdn-h1 ping -c2 -W1 10.0.0.2"
note "The muscle still works, but it has no instructions. Demo 1 starts from exactly this state"
fi
say "Done."

#!/usr/bin/env bash
# LIVE DEMO 1: a switch with no brain -> be the controller by hand -> firewall rule -> hand over to a controller
#   ./scripts/demo1.sh            full run         ./scripts/demo1.sh 3   start at step 3
#   CTRL=osken ./scripts/demo1.sh   use the OS-Ken backup controller instead of ONOS
source "$(dirname "$0")/lib.sh"
CTRL="${CTRL:-onos}"
if [ "$CTRL" = osken ]; then CIP=172.20.20.10; else CIP=172.20.20.20; fi
cd "$DEMO_DIR"

if step 0; then
say "0 · The lab: 3 hosts, 2 Open vSwitch switches, built from a YAML file"
run "cat labs/sdn.clab.yml | grep -v '^#' | head -40"
run "sudo containerlab inspect -t labs/sdn.clab.yml"
run "sudo ovs-vsctl show"
fi

if step 1; then
say "1 · A switch with NO BRAIN: empty flow table, fail_mode=secure"
run "$OF dump-flows s1"
note "Nothing in the table, so every packet is dropped. Watch:"
run "docker exec clab-sdn-h1 ping -c2 -W1 10.0.0.2"
fi

if step 2; then
say "2 · YOU are the control plane: write the forwarding rules by hand (OpenFlow FLOW_MOD)"
run "$OF add-flow s1 'priority=100,arp,actions=FLOOD'"
run "$OF add-flow s1 'priority=200,ip,nw_dst=10.0.0.1,actions=output:s1-h1'"
run "$OF add-flow s1 'priority=200,ip,nw_dst=10.0.0.2,actions=output:s1-h2'"
run "docker exec clab-sdn-h1 ping -c3 10.0.0.2"
note "Look at n_packets: the switch counts every packet that matched each rule"
run "$OF --names dump-flows s1"
fi

if step 3; then
say "3 · A firewall is just a higher-priority rule"
run "$OF add-flow s1 'priority=300,icmp,nw_src=10.0.0.1,nw_dst=10.0.0.2,actions=drop'"
run "docker exec clab-sdn-h1 ping -c2 -W1 10.0.0.2"
note "ICMP blocked, but web (TCP/80) is still allowed:"
run "docker exec clab-sdn-h1 curl -s -m3 http://10.0.0.2 | head -1"
note "Ask the switch WHY: trace a packet through the pipeline"
run "sudo ovs-appctl ofproto/trace s1 in_port=s1-h1,icmp,nw_src=10.0.0.1,nw_dst=10.0.0.2 | grep -E 'priority|Datapath actions'"
note "And h3 on the OTHER switch? Nobody programmed s2..."
run "docker exec clab-sdn-h1 ping -c2 -W1 10.0.0.3"
fi

if step 4; then
say "4 · Hand the brain to an SDN controller ($CTRL at $CIP:6653)"
run "$OF del-flows s1; $OF del-flows s2"
run "sudo ovs-vsctl set-controller s1 tcp:$CIP:6653 -- set-controller s2 tcp:$CIP:6653"
sudo ovs-vsctl set controller s1 connection-mode=out-of-band >/dev/null 2>&1
sudo ovs-vsctl set controller s2 connection-mode=out-of-band >/dev/null 2>&1
sleep 3
run "sudo ovs-vsctl show | grep -E 'Bridge|Controller|is_connected'"
run "docker exec clab-sdn-h1 ping -c4 10.0.0.3"
note "The controller installed these rules for us (reactive: PACKET_IN -> FLOW_MOD):"
run "$OF --names dump-flows s1"
if [ "$CTRL" = onos ]; then
  say "Northbound: ask ONOS over REST, then open the GUI  http://localhost:8181/onos/ui  (onos/rocks)"
  run "curl -s -u onos:rocks http://localhost:8181/onos/v1/devices | jq -r '.devices[] | \"\(.id)  available=\(.available)\"'"
  run "curl -s -u onos:rocks http://localhost:8181/onos/v1/links | jq -r '.links[] | \"\(.src.device)/\(.src.port) -> \(.dst.device)/\(.dst.port)\"'"
  run "curl -s -u onos:rocks http://localhost:8181/onos/v1/hosts | jq -r '.hosts[] | \"\(.ipAddresses[0])  \(.mac)  at \(.locations[0].elementId)/\(.locations[0].port)\"'"
  note "GUI tips: press H to show hosts, L for labels, / for help"
else
  run "docker logs --tail 15 clab-ctrl-osken"
fi
fi
say "Demo 1 done.  Reset any time with: scripts/reset.sh"

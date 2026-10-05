#!/usr/bin/env bash
# Green/red checklist. Run after up.sh and again 5 minutes before going on stage.
set -uo pipefail
source "$(dirname "$0")/lib.sh"
fail=0
chk() { if eval "$2" >/dev/null 2>&1; then ok "$1"; else bad "$1"; fail=1; fi; }

echo "${BOLD}Platform${RST}"
chk "openvswitch kernel module loaded"      "lsmod | grep -q '^openvswitch'"
chk "ovs-vswitchd running"                  "sudo ovs-vsctl show"
chk "bridges s1 s2 br-nfv exist"            "sudo ovs-vsctl br-exists s1 && sudo ovs-vsctl br-exists s2 && sudo ovs-vsctl br-exists br-nfv"

echo "${BOLD}Controllers${RST}"
chk "ONOS container up"                     "docker ps --format '{{.Names}}' | grep -q '^clab-ctrl-onos$'"
chk "ONOS REST answers (8181)"              "curl -sf -u onos:rocks http://localhost:8181/onos/v1/devices"
chk "ONOS app fwd ACTIVE"                   "curl -s -u onos:rocks http://localhost:8181/onos/v1/applications/org.onosproject.fwd | jq -e '.state==\"ACTIVE\"'"
chk "ONOS app openflow ACTIVE"              "curl -s -u onos:rocks http://localhost:8181/onos/v1/applications/org.onosproject.openflow | jq -e '.state==\"ACTIVE\"'"
chk "OS-Ken backup container up"            "docker ps --format '{{.Names}}' | grep -q '^clab-ctrl-osken$'"

echo "${BOLD}Basics lab (two hosts, one cable)${RST}"
chk "pc1 and pc2 up and cabled"              "docker exec clab-basics-pc1 ip -br addr show eth1 | grep -q 10.9.0.1"
chk "pc1 can ping pc2"                       "docker exec clab-basics-pc1 ping -c1 -W1 10.9.0.2"
docker exec clab-basics-pc1 ip neigh flush dev eth1 >/dev/null 2>&1; docker exec clab-basics-pc2 ip neigh flush dev eth1 >/dev/null 2>&1   # keep ARP fresh for the demo

echo "${BOLD}Demo 1 lab${RST}"
for h in h1 h2 h3; do chk "clab-sdn-$h up" "docker exec clab-sdn-$h true"; done
chk "hosts are cabled (h1 eth1 = 10.0.0.1)" "docker exec clab-sdn-h1 ip -br addr show eth1 | grep -q 10.0.0.1"
chk "s1 has ports s1-h1 s1-h2 s1-s2"        "sudo ovs-vsctl list-ports s1 | grep -q s1-h1 && sudo ovs-vsctl list-ports s1 | grep -q s1-h2"
chk "s2 has port s2-h3"                     "sudo ovs-vsctl list-ports s2 | grep -q s2-h3"
chk "s1 flow table empty (demo start)"      "[ -z \"\$($OF dump-flows s1 | grep -v -e NXST -e OFPST)\" ]"
chk "h1 cannot ping h2 yet (no brain)"      "! docker exec clab-sdn-h1 ping -c1 -W1 10.0.0.2"
chk "web server on h2 listening :80"        "docker exec clab-sdn-h2 sh -c 'netstat -ltn 2>/dev/null | grep -q :80 || ss -ltn | grep -q :80'"

echo "${BOLD}Demo 2 lab${RST}"
for h in client web fw ids; do chk "clab-nfv-$h up" "docker exec clab-nfv-$h true"; done
chk "NFV lab is cabled (client eth1 = 10.1.0.1)" "docker exec clab-nfv-client ip -br addr show eth1 | grep -q 10.1.0.1"
chk "firewall VNF has a filter backend"     "docker exec clab-nfv-fw test -s /tmp/fw.mode"
note "fw backend: $(docker exec clab-nfv-fw cat /tmp/fw.mode 2>/dev/null || echo '?')"

echo
if [ $fail -eq 0 ]; then echo "${GRN}${BOLD}ALL GREEN, ready to present${RST}"; else echo "${RED}${BOLD}Something is red. See Troubleshooting in docs/SETUP.md${RST}"; fi

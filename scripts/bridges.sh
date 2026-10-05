#!/usr/bin/env bash
# Create (idempotent) the OVS bridges the labs plug into, and put them in "no brain" state:
# OpenFlow 1.3, fail_mode=secure (no flows = no forwarding), no controller, empty flow tables.
set -euo pipefail
mk() {
  sudo ovs-vsctl --may-exist add-br "$1" -- set bridge "$1" protocols=OpenFlow13 fail_mode=secure \
       other-config:datapath-id="$2"
}
mk s1     0000000000000001
mk s2     0000000000000002
mk br-nfv 00000000000000aa
# the "cable" between s1 and s2
sudo ovs-vsctl --may-exist add-port s1 s1-s2 -- set interface s1-s2 type=patch options:peer=s2-s1
sudo ovs-vsctl --may-exist add-port s2 s2-s1 -- set interface s2-s1 type=patch options:peer=s1-s2
for b in s1 s2 br-nfv; do
  sudo ovs-vsctl del-controller "$b"
  sudo ovs-ofctl -O OpenFlow13 del-flows "$b"
done
echo "bridges ready: s1 s2 br-nfv (secure, empty, no controller)"

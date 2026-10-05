#!/usr/bin/env bash
# Firewall VNF control script.
#   /fw.sh up      bridge eth1<->eth2 and install the policy "drop tcp dport 80"
#   /fw.sh status  show the policy and its packet counter
#   /fw.sh allow   remove the drop rule (policy change, no re-cabling)
#   /fw.sh block   put the drop rule back
# Uses nftables (bridge family); falls back to tc-flower if the kernel lacks nft bridge support.
set -u
MODE_FILE=/tmp/fw.mode

nft_block() {
  nft add table bridge fw 2>/dev/null
  nft 'add chain bridge fw forward { type filter hook forward priority 0; policy accept; }' 2>/dev/null
  nft flush chain bridge fw forward && nft add rule bridge fw forward tcp dport 80 counter drop
}
tc_block() {
  tc qdisc add dev eth1 clsact 2>/dev/null
  tc filter del dev eth1 ingress 2>/dev/null
  tc filter add dev eth1 ingress protocol ip flower ip_proto tcp dst_port 80 action drop
}

case "${1:-status}" in
  up)
    sysctl -qw net.ipv6.conf.all.disable_ipv6=1
    ip link add br0 type bridge 2>/dev/null
    ip link set eth1 master br0; ip link set eth2 master br0
    ip link set eth1 up; ip link set eth2 up; ip link set br0 up
    if nft_block 2>/dev/null; then echo nft > "$MODE_FILE"; echo "fw: nftables bridge filter active"
    elif tc_block; then echo tc > "$MODE_FILE"; echo "fw: tc-flower filter active (nft bridge unsupported)"
    else echo "fw: WARNING no filtering backend available"; fi
    ;;
  status)
    if [ "$(cat $MODE_FILE 2>/dev/null)" = tc ]; then tc -s filter show dev eth1 ingress
    else nft list chain bridge fw forward; fi
    ;;
  allow)
    if [ "$(cat $MODE_FILE 2>/dev/null)" = tc ]; then tc filter del dev eth1 ingress
    else nft flush chain bridge fw forward; fi
    echo "fw: web traffic ALLOWED"
    ;;
  block)
    if [ "$(cat $MODE_FILE 2>/dev/null)" = tc ]; then tc_block; else nft_block; fi
    echo "fw: web traffic BLOCKED"
    ;;
esac

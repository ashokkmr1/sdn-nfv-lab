# Exercises

Start every lab from a clean state: `bash scripts/up.sh` (once after boot), then `bash scripts/reset.sh`.
Use this shortcut in your shell:

```bash
OF="sudo ovs-ofctl -O OpenFlow13"
```

Two commands answer most questions:

- `$OF --names dump-flows s1` shows every rule in s1's table, with packet counters.
- `sudo ovs-appctl ofproto/trace s1 in_port=s1-h1,icmp,nw_src=10.0.0.1,nw_dst=10.0.0.2` shows which rule a
  packet would hit, and why.

---

## Lab 0: From a cable to a switch

The seminar started here. Run each part and answer the question before moving on.

```bash
bash scripts/reset.sh
bash scripts/basics.sh 1 1    # two Linux hosts, one cable
```

- `tcpdump` on pc2 shows two kinds of packet before the ping replies. What are they, and why does the ARP come first?
- After the ping, `ip neigh` on pc1 lists pc2's MAC address. Where did pc1 learn it?

With four computers and direct cables you would need 6 cables and 3 ports on every PC (100 PCs: 4,950 cables).
A switch needs one cable per PC. Now look inside one:

```bash
bash scripts/basics.sh 3 3    # s1 as an ordinary switch: one rule, actions=NORMAL
```

- `ovs-appctl fdb/show s1` is the switch's **control plane** state: the MAC table it learned by itself. Which port
  is each host on?
- `ovs-dpctl dump-flows` is its **data plane**: the fast-path entries in the kernel that actually move packets.
- Both live inside the same box, and the logic (NORMAL) is fixed. Now take it out:

```bash
bash scripts/basics.sh 4 4    # delete the built-in brain
```

- The switch is still up and cabled, but ping fails. Why? (Look at `fail_mode`.) This is where Lab 1 picks up:
  you become the brain.

## Lab 1: Watch Demo 1 step by step

```bash
bash scripts/demo1.sh
```

Each command is printed first and runs when you press Enter. Before each Enter, **predict** what will happen.

- Step 1: why does `ping` fail when the switch is up and cabled? (Look at `fail_mode` in `sudo ovs-vsctl show`.)
- Step 2: the first ping is lost. Which packet type needed the ARP rule?
- Step 3: why does `curl` still work when ping is blocked?
- Step 4: which rules did ONOS install? Find `CONTROLLER` actions (PACKET_IN) and `priority=10` rules (FLOW_MODs).

## Lab 2: Be the controller for the whole network

In Demo 1 you programmed s1 by hand, but h3 on s2 stayed unreachable. **Program both switches so h1 and h2 can
ping h3.** The two switches are joined by patch ports `s1-s2` and `s2-s1`.

<details><summary>Solution</summary>

```bash
bash scripts/reset.sh
$OF add-flow s1 'priority=100,arp,actions=FLOOD'
$OF add-flow s2 'priority=100,arp,actions=FLOOD'
$OF add-flow s1 'priority=200,ip,nw_dst=10.0.0.1,actions=output:s1-h1'
$OF add-flow s1 'priority=200,ip,nw_dst=10.0.0.2,actions=output:s1-h2'
$OF add-flow s1 'priority=200,ip,nw_dst=10.0.0.3,actions=output:s1-s2'
$OF add-flow s2 'priority=200,ip,nw_dst=10.0.0.3,actions=output:s2-h3'
$OF add-flow s2 'priority=200,ip,nw_dst=10.0.0.1,actions=output:s2-s1'
$OF add-flow s2 'priority=200,ip,nw_dst=10.0.0.2,actions=output:s2-s1'
docker exec clab-sdn-h1 ping -c3 10.0.0.3
docker exec clab-sdn-h2 ping -c3 10.0.0.3
```

Eight rules for three hosts and two switches. Now imagine 1,000 switches: that is why we need a controller.
</details>

## Lab 3: Ask the switch why

With Lab 2's rules in place, add a firewall rule that drops ICMP from h1 to h3 only, then prove with
`ofproto/trace` that h2's ping still takes the forwarding rule.

<details><summary>Solution</summary>

```bash
$OF add-flow s1 'priority=300,icmp,nw_src=10.0.0.1,nw_dst=10.0.0.3,actions=drop'
sudo ovs-appctl ofproto/trace s1 in_port=s1-h1,icmp,nw_src=10.0.0.1,nw_dst=10.0.0.3 | grep -E 'priority|Datapath actions'
sudo ovs-appctl ofproto/trace s1 in_port=s1-h2,icmp,nw_src=10.0.0.2,nw_dst=10.0.0.3 | grep -E 'priority|Datapath actions'
```

The first trace ends in `drop`; the second outputs to `s1-s2`.
</details>

## Lab 4: Hand over to ONOS and explore the GUI

```bash
bash scripts/reset.sh
bash scripts/demo1.sh 4
```

Open http://localhost:8181/onos/ui (`onos` / `rocks`). In the topology view press **H** (hosts), **L** (labels)
and **A** (live traffic), and click a switch. Then visit Applications, Devices, Flows and Hosts from the ☰ menu.

Now stop the brain. In Applications, select **Reactive Forwarding** and press ■ (or run
`curl -u onos:rocks -X DELETE http://localhost:8181/onos/v1/applications/org.onosproject.fwd/active`).
Ping h1 → h3 again and look at s1's flow table. Then start it again with ▶ (or the same URL with `-X POST`).

- Which rules disappear, and which stay? Who owns the ones that stay?
- Why do the reactive rules vanish a few seconds after you stop pinging? (Hint: `idle_timeout`.)

## Lab 5: Write a northbound "app" with one REST call

With ONOS in control (Lab 4), block ICMP from h1 to h3 **through the controller's REST API**, without touching
`ovs-ofctl`.

<details><summary>Solution</summary>

```bash
curl -u onos:rocks -X POST -H 'Content-Type: application/json' \
  'http://localhost:8181/onos/v1/flows/of:0000000000000001?appId=org.student.block' -d '{
  "priority": 50000, "isPermanent": true, "timeout": 0,
  "selector": {"criteria": [
    {"type": "ETH_TYPE", "ethType": "0x0800"}, {"type": "IP_PROTO", "protocol": 1},
    {"type": "IPV4_SRC", "ip": "10.0.0.1/32"}, {"type": "IPV4_DST", "ip": "10.0.0.3/32"}]},
  "treatment": {"instructions": []}}'

docker exec clab-sdn-h1 ping -c2 -W1 10.0.0.3     # blocked
docker exec clab-sdn-h2 ping -c2 -W1 10.0.0.3     # still works
$OF dump-flows s1 | grep priority=50000           # ONOS pushed the rule as an OpenFlow FLOW_MOD

curl -u onos:rocks -X DELETE http://localhost:8181/onos/v1/flows/application/org.student.block   # undo
```

An empty instruction list means drop. This is the northbound API: your program says *what*, and ONOS works out
the OpenFlow to send to *which* switch.
</details>

## Lab 6: Watch Demo 2 (NFV)

```bash
bash scripts/reset.sh && bash scripts/demo2.sh
```

- Which four rules build the service chain? Which one sends the web server's replies back through the VNF?
- `docker exec clab-nfv-fw /fw.sh status` shows the firewall's own rule (nftables) and its counter.
- Step 3 removes the VNF from the path with one command. How does `cookie=0x5fc/-1` find the right rules?

## Lab 7: Put ping through the VNF, then block it there

Extend the chain so ICMP also passes through the firewall, check that ping still works, then block ping
**inside the VNF** (not in the switch).

<details><summary>Solution</summary>

Run `bash scripts/demo2.sh` up to the end of step 2 (or press Ctrl+C there), then:

```bash
$OF add-flow br-nfv 'cookie=0x5fc,priority=200,icmp,in_port=nfv-client,actions=output:nfv-fwin'
$OF add-flow br-nfv 'cookie=0x5fc,priority=200,icmp,in_port=nfv-web,actions=output:nfv-fwout'
docker exec clab-nfv-client ping -c2 10.1.0.2          # works, now through the VNF

docker exec clab-nfv-fw nft add rule bridge fw forward icmp type echo-request counter drop
docker exec clab-nfv-client ping -c2 -W1 10.1.0.2      # blocked by the VNF
docker exec clab-nfv-fw nft list chain bridge fw forward
```

The switch decides *which* traffic visits the function; the function decides *what happens* to it. That
split is the core idea of SDN + NFV. (`reset.sh` restores the firewall's original policy.)
</details>

---

## Challenges (no solutions: share yours as a pull request)

1. **Your own controller app.** Edit `images/osken/l2learn.py` so the controller also acts as a firewall: when a
   switch connects, install a higher-priority rule that drops ICMP to 10.0.0.3. Hint: in `on_connect`, call
   `self.add_flow(dp, 100, p.OFPMatch(eth_type=0x0800, ip_proto=1, ipv4_dst='10.0.0.3'), [])`.
   Rebuild with `docker build -t osken:local images/osken`, redeploy `labs/ctrl.clab.yml`, and test with
   `CTRL=osken bash scripts/demo1.sh 4`. Watch `docker logs -f clab-ctrl-osken`.
2. **Proactive instead of reactive.** Stop Reactive Forwarding and make all three hosts reach each other using
   only ONOS REST flows (Lab 5). How many rules do you need? What happens when you add a host?
3. **Grow the network.** Add an `h4` (10.0.0.4) on s2 in `labs/sdn.clab.yml`, redeploy, and check that ONOS
   learns it without any change to the controller.
4. **Mirror to the IDS.** Make the IDS see both directions of the web traffic, not just client → web (Demo 2
   step 4 mirrors one direction).
5. **Count, don't block.** Change the VNF into a monitor that counts HTTP requests per client with nftables
   counters instead of dropping them.
6. **Bigger fabrics.** Build a leaf-spine fabric with containerlab + OVS (see `martimy/clab_sdn_dcn` in
   [RESOURCES.md](RESOURCES.md)), or run a real switch OS with the `sonic-vs` kind.

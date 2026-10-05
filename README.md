# SDN & NFV lab: programming the network on your laptop

Everything from the **"Programming the Network"** seminar (CEG Industry Connect, Anna University, 5 October 2026):
the slides, the exact lab used in the live demos, step-by-step exercises, and where to go next.

You build a small software-defined network out of containers: **Open vSwitch** switches, hosts, the **ONOS**
SDN controller (with **OS-Ken** as a tiny Python alternative), and a **firewall VNF**. Then you program it:
first by hand with OpenFlow rules, then through a controller, then by chaining a network function into the path.
Everything is free and open source, and it runs on an ordinary laptop.

## What's here

| Folder | What |
|---|---|
| [`slides/`](slides/) | The seminar slides (PDF) |
| [`labs/`](labs/) | containerlab topologies: `basics` (two hosts, one cable), `ctrl` (controllers), `sdn` (Demo 1), `nfv` (Demo 2) |
| [`scripts/`](scripts/) | `install.sh` (once), `up.sh`, `basics.sh`, `demo1.sh`, `demo2.sh`, `reset.sh`, `preflight.sh`, `down.sh` |
| [`images/`](images/) | Dockerfiles: the OS-Ken controller app and the firewall VNF |
| [`docs/SETUP.md`](docs/SETUP.md) | Getting a Linux machine on Windows, macOS or Linux, then installing the lab |
| [`docs/EXERCISES.md`](docs/EXERCISES.md) | Eight guided labs (0–7, with solutions) and open-ended challenges |
| [`docs/RESOURCES.md`](docs/RESOURCES.md) | Free books, specs, tutorials and next projects |

## Quick start

You need Ubuntu 22.04 or 24.04 with internet access (see [docs/SETUP.md](docs/SETUP.md) for Windows and Mac).

```bash
git clone https://github.com/ashokkmr1/sdn-nfv-lab.git
cd sdn-nfv-lab
bash scripts/install.sh          # once: Docker, containerlab, Open vSwitch, images (~10 min)
# log out and back in (or reboot the VM) so your user can run docker
bash scripts/up.sh               # bridges + controllers + both labs, ends with a green/red checklist
bash scripts/basics.sh           # from a cable to a switch: press Enter to run each command
bash scripts/demo1.sh            # Demo 1: you become the controller, then ONOS takes over
bash scripts/reset.sh && bash scripts/demo2.sh   # Demo 2
```

The ONOS GUI is at http://localhost:8181/onos/ui (user `onos`, password `rocks`).
Run `bash scripts/up.sh` again after every reboot, and `bash scripts/down.sh` to remove everything.

## How the seminar ran it

Before any SDN, three short live moments built up from a cable to a switch (`bash scripts/basics.sh 1 1`, then
`3 3`, then `4 4`): two hosts on one cable, a switch with its control plane (MAC table) and data plane (kernel fast
path) in one box, and then the switch with its built-in brain removed. Demo 1 starts from exactly that state, and
Demo 2 follows the NFV section. Every script takes a step range, e.g. `bash scripts/demo1.sh 2 3`.

## The two demos

```
Demo 1 (SDN)                                   Demo 2 (NFV)
                ONOS 172.20.20.20                 client 10.1.0.1 ──┐            ┌── web 10.1.0.2
            (or OS-Ken 172.20.20.10)                                └── br-nfv ──┘
                       │ OpenFlow                                     │    │    │
  h1 10.0.0.1 ──┐      │      ┌── h3 10.0.0.3                      fwin  fwout  ids (mirror)
                s1 ─────────── s2                                     └─ fw ─┘   firewall VNF
  h2 10.0.0.2 ──┘                                                     (container: bridge + nftables)
```

1. **Demo 1:** a switch with an empty flow table forwards nothing. You become the controller and write
   OpenFlow rules by hand. A firewall turns out to be just a higher-priority rule. Then ONOS takes over and
   programs both switches reactively (PACKET_IN → FLOW_MOD).
2. **Demo 2:** web traffic, and only web traffic, is steered through a firewall container by four
   OpenFlow rules. That is service function chaining. You change the policy inside the VNF, or take it out of
   the path, without touching a cable.

The commands in `scripts/demo1.sh` and `scripts/demo2.sh` are plain `ovs-ofctl`, `ovs-vsctl`, `docker` and
`curl`. Read them, change them, break things, and watch the flow tables.

## License

Lab code and scripts: [MIT](LICENSE). Slides and docs: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
ONOS, OS-Ken, Open vSwitch and containerlab are separate projects under their own licenses.

Questions or fixes: open an issue or a pull request. — Ashok Kumar Murthy

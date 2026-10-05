# Resources

Everything here is free unless marked otherwise.

## Read first

- **Software-Defined Networks: A Systems Approach** (free book): L. Peterson, C. Cascone, B. O'Connor,
  T. Vachuska, B. Davie. https://sdn.systemsapproach.org/
- **Textbook for the syllabus** (not free): W. Stallings, *Foundations of Modern Networking: SDN, NFV, QoE,
  IoT, and Cloud*, Pearson. Chapters 2–5 (SDN) and 7–8 (NFV).

## The papers and specs behind the slides

- N. McKeown et al., "OpenFlow: Enabling Innovation in Campus Networks", ACM SIGCOMM CCR, 2008
- S. Jain et al., "B4: Experience with a Globally-Deployed Software Defined WAN", ACM SIGCOMM 2013
- OpenFlow Switch Specification 1.3.5: https://opennetworking.org/wp-content/uploads/2014/10/openflow-switch-v1.3.5.pdf
- OpenFlow Switch Specification 1.5.1: https://opennetworking.org/wp-content/uploads/2014/10/openflow-switch-v1.5.1.pdf
- ETSI NFV introductory white paper (2012): https://portal.etsi.org/nfv/nfv_white_paper.pdf
- ETSI GS NFV 002, the NFV architectural framework: https://www.etsi.org/deliver/etsi_gs/nfv/001_099/002/01.02.01_60/gs_nfv002v010201p.pdf

## Tools used in this lab

| Tool | Docs |
|---|---|
| containerlab | https://containerlab.dev/ · OVS bridges: https://containerlab.dev/manual/kinds/ovs-bridge/ |
| Open vSwitch | Tutorials: https://docs.openvswitch.org/en/latest/tutorials/ · OpenFlow FAQ: https://docs.openvswitch.org/en/latest/faq/openflow/ |
| ONOS | https://github.com/opennetworkinglab/onos · tutorial: https://arnotroch.github.io/ONOS-Tutorial/ |
| OS-Ken | https://docs.openstack.org/os-ken/latest/ · https://pypi.org/project/os-ken/ |
| nftables | https://wiki.nftables.org/ |
| Lima (macOS VMs) | https://lima-vm.io/docs/ |
| Multipass (Ubuntu VMs) | https://canonical.com/multipass |

## Next labs and projects

- **Mininet:** a whole SDN network in one command. https://mininet.org/ (Ubuntu: `sudo apt install mininet`)
- **Faucet:** a production-grade OpenFlow controller with an OVS tutorial: https://docs.faucet.nz/ and
  https://docs.openvswitch.org/en/latest/tutorials/faucet/
- **containerlab + OVS leaf-spine fabric:** https://github.com/martimy/clab_sdn_dcn
- **SONiC,** the open-source switch OS used in large data centres: https://sonicfoundation.dev/ ; run it in
  containerlab with the `sonic-vs` kind: https://containerlab.dev/manual/kinds/sonic-vs/

## Skills worth building alongside

Networking fundamentals (TCP/IP, routing, switching, VLANs, BGP basics) · Linux (shell, namespaces, iproute2,
tcpdump) · Python and REST APIs · containers (Docker, then Kubernetes) · automation (Git, Ansible,
YANG/gNMI/OpenConfig) · open source (read code, file issues, send a first pull request).

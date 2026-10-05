"""Minimal OpenFlow 1.3 learning switch for OS-Ken (a compact simple_switch_13).

On connect: install a table-miss rule that sends unknown packets to the controller.
On PACKET_IN: learn src MAC -> port; if dst is known install a flow, else flood.
"""
from os_ken.base import app_manager
from os_ken.controller import ofp_event
from os_ken.controller.handler import CONFIG_DISPATCHER, MAIN_DISPATCHER, set_ev_cls
from os_ken.ofproto import ofproto_v1_3
from os_ken.lib.packet import packet, ethernet, ether_types


class L2Learn(app_manager.OSKenApp):
    OFP_VERSIONS = [ofproto_v1_3.OFP_VERSION]

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.mac_to_port = {}

    def add_flow(self, dp, priority, match, actions, idle=0):
        p = dp.ofproto_parser
        inst = [p.OFPInstructionActions(dp.ofproto.OFPIT_APPLY_ACTIONS, actions)]
        dp.send_msg(p.OFPFlowMod(datapath=dp, priority=priority, match=match,
                                 instructions=inst, idle_timeout=idle))

    @set_ev_cls(ofp_event.EventOFPSwitchFeatures, CONFIG_DISPATCHER)
    def on_connect(self, ev):
        dp = ev.msg.datapath
        p, o = dp.ofproto_parser, dp.ofproto
        self.logger.info("SWITCH CONNECTED dpid=%016x -> installing table-miss rule", dp.id)
        self.add_flow(dp, 0, p.OFPMatch(), [p.OFPActionOutput(o.OFPP_CONTROLLER, o.OFPCML_NO_BUFFER)])

    @set_ev_cls(ofp_event.EventOFPPacketIn, MAIN_DISPATCHER)
    def on_packet_in(self, ev):
        msg = ev.msg
        dp = msg.datapath
        p, o = dp.ofproto_parser, dp.ofproto
        in_port = msg.match['in_port']
        eth = packet.Packet(msg.data).get_protocols(ethernet.ethernet)[0]
        if eth.ethertype == ether_types.ETH_TYPE_LLDP or eth.dst.startswith('33:33'):
            return  # ignore discovery and IPv6 multicast noise
        table = self.mac_to_port.setdefault(dp.id, {})
        table[eth.src] = in_port
        out = table.get(eth.dst, o.OFPP_FLOOD)
        self.logger.info("PACKET_IN  dpid=%s  %s -> %s  in_port=%s  => %s",
                         dp.id, eth.src, eth.dst, in_port, 'FLOOD' if out == o.OFPP_FLOOD else f'FLOW_MOD out:{out}')
        actions = [p.OFPActionOutput(out)]
        if out != o.OFPP_FLOOD:
            self.add_flow(dp, 1, p.OFPMatch(in_port=in_port, eth_dst=eth.dst), actions, idle=30)
        dp.send_msg(p.OFPPacketOut(datapath=dp, buffer_id=o.OFP_NO_BUFFER,
                                   in_port=in_port, actions=actions, data=msg.data))

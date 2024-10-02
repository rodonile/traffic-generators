from scapy.all import *
import logging
import struct
from datetime import datetime

log = logging.getLogger(__name__)

TH_FIN = 0b1
TH_SYN = 0b10
TH_RST = 0b100
TH_PUSH = 0b1000
TH_ACK = 0b10000
TH_URG = 0b100000
TH_ECE = 0b1000000
TH_CWR = 0b10000000


def get_timestamp(meta, format="pcap"):
    """Get timestamp for a specific packet

    Args:
        meta: meta data from current packet
        format (str, optional): type of trace, pcap (default) or pcapng

    Returns:
        float: timestamp of packet
    """

    if format == "pcap":
        return meta.sec + meta.usec/1000000000.
    elif format == "pcapng":
        return ((meta.tshigh << 32) | meta.tslow) / float(meta.tsresol)


def pcap_reader(in_file, packets_to_process=0, packets_to_skip=0):
    """Reads pcap file

    Args:
        in_file (str): filename of pcap file
        packets_to_process (int, optional): number of packets to process
            0 means all the packets (default)

    Yields:
        tuple: packet timestamp, source ip, source port, destination IP
               destination port, protocol, TCP SYN flag, TCP ACK flag,
               TCP FIN flag, packet length, TCP sequence number,
               TCP ACK number, TCP timestamp tsval, TCP timestamp tsecr, IP identification
    """

    log.info("pcap reader start: %s", datetime.now())

    # constants
    IP_LEN = 20
    # IPv6_LEN = 40
    TCP_LEN = 20

    # variables
    packet_count = 0
    ipv6_packets = 0
    udp_packets = 0
    icmp_packets = 0
    tcp_packets = 0
    other_packets = 0

    # helper to read PCAP files (or pcapng)
    with RawPcapReader(in_file) as _pcap_reader:

        first_packet = True
        default_packet_offset = 0
        try:
            for packet, meta in _pcap_reader:

                if first_packet:
                    first_packet = False

                    # check if the metadata is for pcap or pcapng
                    if hasattr(meta, 'usec'):
                        pcap_format = "pcap"
                        link_type = _pcap_reader.linktype

                    elif hasattr(meta, 'tshigh'):
                        pcap_format = "pcapng"
                        link_type = meta.linktype

                    # check first layer
                    if link_type == DLT_EN10MB:
                        default_packet_offset += 14
                    elif link_type == DLT_RAW_ALT:
                        default_packet_offset += 0
                    elif link_type == DLT_PPP:
                        default_packet_offset += 2
                    elif link_type == DLT_LINUX_SLL:
                        default_packet_offset += 16

                # limit the number of packets we process
                if packet_count == packets_to_process and packets_to_process != 0:
                    break

                packet_count += 1
                
                if packet_count % 10000000 == 0:
                    log.info("%s packets parsed (%s)", packet_count, datetime.now())

                if packet_count < packets_to_skip:
                    continue
                #else:
                #    log.info("%d" %packet_count)
                #     wrpcap('morning_problem.pcap',packet[:], append=True)
                #     with RawPcapWriter("morning_problem.pcap",append=True) as pwriter:
                #        pwriter._write_header(None)
                #        pwriter.write(packet)              

                # remove bytes until IP layer (this depends on the linktype)
                packet = packet[default_packet_offset:]

                # IP LAYER Parsing
                packet_offset = 0

                version = packet[0]
                ip_version = version >> 4

                protocol = 0

                if ip_version == 4:
                    # filter if the packet does not even have 20 bytes
                    if len(packet) < IP_LEN:
                        log.debug("Packet %s: not large enough for IP header (%s)",
                                 packet_count, len(packet))
                        continue

                    # get the normal ip fields
                    ip_header = struct.unpack("!BBHHHBBHBBBBBBBB", packet[:IP_LEN])

                    # increase offset by layer length
                    # IHL: Internet Header Length in 32-bit words.
                    # times 4 to get size in bytes
                    ip_header_length = (ip_header[0] & 0x0f) * 4
                    packet_offset += ip_header_length

                    # Total length of the entire packet in bytes
                    ip_length = ip_header[2]

                    identification = ip_header[3]

                    protocol = ip_header[6]

                    # format ips
                    ip_src = '{0:d}.{1:d}.{2:d}.{3:d}'.format(ip_header[8],
                                                              ip_header[9],
                                                              ip_header[10],
                                                              ip_header[11])

                    ip_dst = '{0:d}.{1:d}.{2:d}.{3:d}'.format(ip_header[12],
                                                              ip_header[13],
                                                              ip_header[14],
                                                              ip_header[15])

                # parse ipv6 headers
                elif ip_version == 6:
                    # skipped for now!
                    ipv6_packets += 1
                    log.debug("Packet %s: is IPv6, skipped!", packet_count)
                    continue

                else:
                    log.debug("Packet %s: no IP header", packet_count)
                    continue

                # parse TCP header
                if protocol == 6 and len(packet) >= (packet_offset + TCP_LEN):
                    tcp_packets += 1
                    tcp_header = struct.unpack("!HHLLBBHHH", packet[packet_offset:packet_offset+TCP_LEN])
                    sport = str(tcp_header[0])
                    dport = str(tcp_header[1])
                    pkt_seq = tcp_header[2]
                    pkt_ack = tcp_header[3]

                    # Size of the TCP header in 32-bit words
                    # times 4 to get size in bytes
                    tcp_header_length = ((tcp_header[4] & 0xf0) >> 4) * 4
                    flags = tcp_header[5]
                    syn_flag = flags & TH_SYN != 0
                    ack_flag = flags & TH_ACK != 0
                    fin_flag = flags & TH_FIN != 0

                    # Payload size of tcp segment
                    # Formula: [IP Total Length] - ( ([IP IHL] + [TCP Data offset]) * 4 )
                    # Thanks to: https://stackoverflow.com/questions/6639799/calculate-size-and-start-of-tcp-packet-data-excluding-header
                    tcp_payload = ip_length - ( ip_header_length + tcp_header_length )

                    # TODO: could also parse:
                    #   window (tcp_header[6])
                    #   checksum (tcp_header[7])
                    #   urgent pointer (tcp_header[8])

                    # parsing TCP options
                    option_size = tcp_header_length - TCP_LEN
                    position = 0

                    # default values
                    option_length = 1
                    tsval = 0
                    tsecr = 0

                    #log.info(">> pos %d opt_size %d len %d offset+header_len %d" %(position, option_size, len(packet), packet_offset + tcp_header_length ) )

                    while position < option_size and len(packet) >= (packet_offset + tcp_header_length):

                        kind = packet[packet_offset + TCP_LEN + position]

                        # end of option list
                        if kind == 0:
                            break

                        # no-operation (1 byte long)
                        if kind == 1:
                            option_length = 1

                        # TCP timestamp options
                        elif kind == 8:
                            timestamp_start = packet_offset + TCP_LEN + position + 2

                            # cannot parse timestamps
                            if len(packet) - timestamp_start < 8:
                                log.info("Packet %s: cannot parse timestamps "
                                         "(remaining packet size: %s)", packet_count,
                                         len(packet) - timestamp_start)
                                break

                            tsval, tsecr = struct.unpack("!LL", packet[timestamp_start: timestamp_start + 8])
                            option_length = 10

                        else:
                            if len(packet) <= packet_offset + TCP_LEN + position + 1:
                                log.info("Packet %s: cannot parse next option size)", packet_count)
                                break

                            # other options which could be parsed in the future
                            option_length = packet[packet_offset + TCP_LEN + position + 1]

                            # strange TCP option
                            if option_length == 0:
                                break

                        position += option_length

                else:
                    # parse other protocols in the future (most importantly UDP)
                    # but how to compute e.g., the RTT for these protocols
                    log.debug("Packet %s: not a TCP packet (protocol %s)", packet_count, protocol)
                    if protocol == 1:
                        icmp_packets += 1
                    elif protocol == 17:
                        udp_packets += 1
                    else:
                        other_packets += 1

                    continue

                # compute timestamps
                packet_ts = get_timestamp(meta, pcap_format)

                yield ((packet_ts, ip_src, sport, ip_dst, dport, protocol,
                        syn_flag, ack_flag, fin_flag, ip_length, pkt_seq,
                        pkt_ack, tsval, tsecr, identification, tcp_payload,
                        packet_count))

        except Exception:
            # for debugging
            import traceback
            traceback.print_exc()

    log.info("total packets parsed: %s", packet_count)
    log.info("total IPv6 packets: %s", ipv6_packets)
    log.info("total TCP packets: %s", tcp_packets)
    log.info("total UDP packets: %s", udp_packets)
    log.info("total ICMP packets: %s", icmp_packets)
    log.info("total packets with other protocol number: %s", other_packets)

    log.info("pcap reader end: %s", datetime.now())

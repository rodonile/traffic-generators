# Find 20 syn packets
from parser import pcap_reader
from datetime import datetime
from helper_functions import find_sinack
import sys

if __name__ == '__main__':
    pcap_file = 'traces/first_100m.pcap'
    print(datetime.now(), 'starting...')

    i = 0
    count = 0
    FLAG = 0
    
    for (packet_ts, ip_src, sport, ip_dst, dport, protocol,
            syn_flag, ack_flag, fin_flag, ip_length, pkt_seq,
            pkt_ack, tsval, tsecr, identification, tcp_payload, packet_count) in pcap_reader(pcap_file):
        
        if i > 1000000:
            if syn_flag == True and ack_flag == False:
                # Print syn packet
                print("syn packet found")
                print(i, ip_src, sport, ip_dst, dport, protocol, syn_flag, ack_flag, pkt_seq, tcp_payload)
                
                count += 1

        if count == 20:
            break
            
        i += 1
        
        
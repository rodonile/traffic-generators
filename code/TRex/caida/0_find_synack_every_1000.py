# Print synack packet every 1000
from parser import pcap_reader
from datetime import datetime
from helper_functions import find_sinack
import sys

if __name__ == '__main__':
    pcap_file = 'traces/first_100m.pcap'
    print(datetime.now(), 'starting, look for random synack every 1000 packets in pcap...')

    i = 0
    count = 0
    print_count = 0
    
    for (packet_ts, ip_src, sport, ip_dst, dport, protocol,
            syn_flag, ack_flag, fin_flag, ip_length, pkt_seq,
            pkt_ack, tsval, tsecr, identification, tcp_payload, packet_count) in pcap_reader(pcap_file):
        
        count += 1
        
        if count >= 1000:
            if syn_flag == True and ack_flag == True:
                # Print synack packet
                #print("synack packet found")
                print(i, ip_src, sport, ip_dst, dport, protocol, syn_flag, ack_flag, pkt_seq, tcp_payload)
                
                count = 0
                print_count += 1
            
            #else:
            #    print("looking for synack")
            
        i += 1
        
        if print_count == 100:
            break
        
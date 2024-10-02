# Print syn packet every 1000
from parser import pcap_reader
from datetime import datetime
from helper_functions import find_sinack
import sys

if __name__ == '__main__':
    pcap_file = 'traces/first_100m.pcap'
    print(datetime.now(), 'starting...')

    i = 0
    count = 0
    print_count = 0
    
    for (packet_ts, ip_src, sport, ip_dst, dport, protocol,
            syn_flag, ack_flag, fin_flag, ip_length, pkt_seq,
            pkt_ack, tsval, tsecr, identification, tcp_payload, packet_count) in pcap_reader(pcap_file):
        
        count += 1
        
        if count >= 1000:
            if syn_flag == True and ack_flag == False:
                # Print syn packet
                #print("syn packet found")
                print(i, ip_src, sport, ip_dst, dport, protocol, syn_flag, ack_flag, pkt_seq, tcp_payload)
                
                count = 0
                print_count += 1
            
            #else:
            #    print("looking for syn")
            
        i += 1
        
        if print_count == 100:
            break
        
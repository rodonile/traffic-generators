# Find 10 complete flows
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
            pkt_ack, tsval, tsecr, identification, tcp_payload) in pcap_reader(pcap_file):
        
        if i > 100000:
            if syn_flag == True and ack_flag == False:
                # Print syn packet
                print("syn packet found")
                print(i, ip_src, sport, ip_dst, dport, protocol, syn_flag, ack_flag, pkt_seq, tcp_payload)
                
                # Look for respective sinack packet
                sinack = find_sinack(ip_src, sport, i)
                
                if sinack == 1:         # if sinack returns 0, no syn ack packet was found
                    count += 1
                    # Append syn packets for which we found a syn ack to a file
                    print(i, ip_src, sport, ip_dst, dport, protocol, syn_flag, ack_flag, pkt_seq, tcp_payload, file=open("syn_packets_with_synack_found.txt", "a"))
                
            

        if count == 10:
            break
            
        i += 1
        
        
from parser import pcap_reader
from datetime import datetime

def find_sinack(sIP, sPORT, index):
    pcap_file = 'traces/first_100m.pcap'
    print('looking for correspective sin+ack')

    i = 0
    FLAG = 0
    
    for (packet_ts, ip_src, sport, ip_dst, dport, protocol,
            syn_flag, ack_flag, fin_flag, ip_length, pkt_seq,
            pkt_ack, tsval, tsecr, identification, tcp_payload, packet_count) in pcap_reader(pcap_file):
        
        # Only check after the syn packets in file
        if i > index:
  
            if ip_dst == sIP and dport == sPORT and syn_flag == True and ack_flag == True:
                print('sinack found')
                print(i, ip_src, sport, ip_dst, dport, protocol, syn_flag, ack_flag, pkt_seq, tcp_payload)
                FLAG = 1
                return FLAG
            
            if ip_src == sIP and sport == sPORT and syn_flag == False and ack_flag == True:
                print("synack not found (found handshake's ack of the client first)")
                return FLAG
            
            if i == index + 1000000:
                print("synack not found (looked 1 million packets after syn)")
                return FLAG
            
        i += 1



def create_flow_id_list(sIP, sPORT, dIP, dPORT):
    pcap_file = 'traces/first_100m.pcap'
    print('looking for required flow')

    i = 0
    last_update = 0
    list = []
    
    # Flags for termination
    FIN = 0
    FINACK = 0
    ACKED_FINACK = 0
    
    for (packet_ts, ip_src, sport, ip_dst, dport, protocol,
            syn_flag, ack_flag, fin_flag, ip_length, pkt_seq,
            pkt_ack, tsval, tsecr, identification, tcp_payload, packet_count) in pcap_reader(pcap_file):
        
        # Check for client-->server direction packets
        if ip_src == sIP and sport == sPORT and ip_dst == dIP and dport == dPORT:
            print(packet_count, ip_src, sport, ip_dst, dport, syn_flag, ack_flag, pkt_seq,ip_length, tcp_payload)
            list.append(packet_count)
            last_update = i
            
            # look for proper termination (faster exit condition)
            if fin_flag == True:
                print('--------------FIN')
                FIN = 1
            if ack_flag == True and FINACK == 1:
                print('--------------ACK')
                print('TCP session terminated, exiting')
                ACKED_FINACK = 1
            
        
        # Check for server-->client direction packets
        if ip_src == dIP and dport == sPORT and ip_dst == sIP and sport == dPORT:
            print(packet_count, ip_src, sport, ip_dst, dport, syn_flag, ack_flag, pkt_seq,ip_length, tcp_payload)
            list.append(packet_count)
            last_update = i
            
            # look for proper termination (faster exit condition)
            if fin_flag == True:
                print('--------------FINACK')
                FINACK = 1
        
        # exit condition
        if i > last_update + 10000000 or ACKED_FINACK == 1:
            print("exited on condition")
            return list
            
        
        i += 1
    
    # Consider the case that pcap finished before exit condition elapsed
    print("exited on finished pcap file")
    return list































# Extract flows from big pcap files and fill payload with zeros
#
# A flow can be either directly defined here or passed to this function as arguments
# --> see README.md for example
#
# COMMENTS: 
# - this function is optimized to extract complete flows (looks for correct TCP termination)
# - for uncomplete or one-directional flows takes a long time (exit condition is traversing whole
#   pcap or not finding packet of the flow for 10mio packets after last one found)
#
# Display flow in output and create pcap with that flow only
from parser import pcap_reader
from datetime import datetime
from helper_functions import create_flow_id_list
import sys
import os
import argparse
from scapy.all import *
from scapy.utils import PcapWriter      # need this to process .pcap files
from scapy.packet import Packet,Raw

if __name__ == '__main__':
    pcap_file = 'traces/first_100m.pcap'
    print(datetime.now(), 'starting...')
    
    ###########################
    # Flow identifier
    # (uncomment only one selected flow or the parser arguments)
    ###########################
    
    # One-sided flow 1 (sequence of acks without flow start recorded)
    #flow_list = create_flow_id_list('138.233.237.211', '54185', '197.115.78.84', '443')
    #pcap_name = 'one_sided_flow1'
    
    # One sided flow 2
    #flow_list = create_flow_id_list('', '', '', '')
    #pcap_name = 'one_sided_flow_2'
    
    # 2-sided flow 1 (33 packets, incomplete)
    #flow_list = create_flow_id_list('198.247.243.248', '56008', '224.115.19.221', '443')
    #pcap_name = '2-sided_flow_1_incomplete'
    
    # 2-sided flow 2 (7 packets)
    #flow_list = create_flow_id_list('105.179.192.250', '1093', '50.65.138.179', '445')
    #pcap_name = '2-sided_flow_2_complete'
    
    # 2-sided flow 3 (6 packets)
    #flow_list = create_flow_id_list('69.51.203.204', '53494', '73.165.89.153', '445')
    #pcap_name = '2-sided_flow_3_complete'
    
    # 2-sided flow 4 (42 packets)
    #flow_list = create_flow_id_list('205.71.47.209', '24898', '231.148.131.144', '443')
    #pcap_name = '2-sided_flow_4_complete'
    
    # 2-sided flow 5 (15 packets)
    flow_list = create_flow_id_list('237.42.73.95', '29034', '237.42.94.139', '443')
    pcap_name = '2-sided_flow_5_complete'
    
    # Uncomment if want to parse arguments from outside
    #parser = argparse.ArgumentParser()
    #parser.add_argument('--ip_src', type=str)
    #parser.add_argument('--sport', type=str)
    #parser.add_argument('--ip_dst', type=str)
    #parser.add_argument('--dport', type=str)
    #parser.add_argument('--pcap_name', type=str)
    #args = vars(parser.parse_args())
    #pcap_name = args['pcap_name']
    #flow_list = create_flow_id_list(args['ip_src'], args['sport'], args['ip_dst'], args['dport'])
    
    
    
    print('Pcap_name: ', pcap_name) 
    print(flow_list)
    
    
    ###########################
    # Extract pcap
    ###########################
    #Parse list as right editcap input
    print('extracting flow from pcap')
    string = ''
    for item in flow_list:
       string = string + str(item) + ' ' 
    
    # call editcap to extract flow packets from pcap
    command = 'editcap -r traces/first_100m.pcap ' + pcap_name + '.pcap ' + string
    os.system(command)
    
    
    ###########################
    # Fill payload (with scapy)
    ###########################
    
    print('filling payload with  0s')
    packets = rdpcap(pcap_name + '.pcap')
    new_pcap_name = pcap_name + '_with_payload.pcap'
    new_cap = PcapWriter(new_pcap_name) #, append=True removed
    # and modify each packet
    for p in packets:
        # p.show()          # debug
        
        # add random payload to packet
        payload_length = p[IP].len - 40
        if payload_length > 0:
            payload_string = '0' * payload_length           # add random 0's
            p = p/bytes(payload_string, encoding='utf-8')
        
        # write modified packet to new pcap file
        new_cap.write(p)
    
    #command2 = 'rm ' + pcap_name + '.pcap'
    #os.system(command2)












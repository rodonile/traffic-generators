#!/bin/bash
# Send udp packets from interface p1p1 to interface p1p2
#default Bandwidth in Mbps
RATE=10000
if [[ "$1" == "--rate" || "$1" == "-r" ]]
then
	shift
	RATE=$1
    shift
else
	echo "If desired give bandwith in Mbps as -r or --rate"
fi

#default packet size (payload) in bytes
PACKET_SIZE=60
if [[ "$1" == "--bytesize" || "$1" == "-b" ]]
then
    shift
    PACKET_SIZE=$1
    shift
else
	echo "If desired give packet_size in Bytes as -b or --bytesize"
fi

TIMESTAMP='no'
if [[ "$1" == "--latency" || "$1" == "-l" ]]
then
    shift
    TIMESTAMP=$1
    shift
else
	echo "To capture PTP packets give --latency cap argument"
fi


# Latency measurement cannot succeed with only one dpdk-binded interface (sure?)
# tshark tool already adds timestamps on all packets
# Only useful to capture PTP packets
if [[ "$TIMESTAMP" == "cap" || "$TIMESTAMP" == "cap" ]]
then
    echo "--------------------Only timestamper task and capture PTP packets at p1p2"
    sudo ./build/MoonGen ./scripts/pcap_files/udp_only_timestamp_for_tshark.lua -r $RATE -s $PACKET_SIZE 0
    
else
	echo "--------------------Packet generation from p1p1-dpdk to p1p2-kernel started"
    sudo ./build/MoonGen ./scripts/pcap_files/udp_no_timestamp_for_tshark.lua -r $RATE -s $PACKET_SIZE 0
fi


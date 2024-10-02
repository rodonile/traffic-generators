#!/bin/bash
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

FILE=capture.pcap
if [[ "$1" == "--file" || "$1" == "-f" ]]
then
	shift
	FILE=$1
    shift
else
	echo "Output .pcap file name with --file or -f"
fi

TIMESTAMP='no'
if [[ "$1" == "--latency" || "$1" == "-l" ]]
then
    shift
    TIMESTAMP=$1
    shift
else
	echo "If desired set -l yes or --latency yes if want to enable dpdk-latency measurements"
    echo "If desired set -l cap or --latency cap to capture the PTP packets (note that this disrupts latency measurement)"
fi

##############
# Need to modify commands below if want to enablesnaplen (set --snap-len $SNAPLEN flag to ./build/MoonGen command)
# Anyway there is no need as packet capturer manages to capture whole packets without performance or packet loss
# (tested with up to 500bytes packets, maybe could be userful for >500 packets...)
##############
SNAPLEN=84
if [[ "$1" == "--snap-len" || "$1" == "-s" ]]
then
	shift
	SNAPLEN=$1
    shift
else
	echo "If desired give packet capture snap length (not to capture all payload) with --snap-len"
fi
##############


if [[ "$TIMESTAMP" == "yes" || "$TIMESTAMP" == "yes" ]]
then
	echo "With latency measurements (will be saved in histogram_dpdk.csv)"
    echo "Capturing packets on interface p1p2"
    sudo ./build/MoonGen ./scripts/pcap_files/dump-udp-pkts.lua 0 1 --rate $RATE --size $PACKET_SIZE --file $FILE   
    
elif [[ "$TIMESTAMP" == "cap" || "$TIMESTAMP" == "cap" ]]
then
    echo "Only latency measurement task (via precise dpdk-packet-timestamping on interface registers)"
    echo "Capturing only PTP packets on interface p1p2"
    sudo ./build/MoonGen ./scripts/pcap_files/dump-udp-pkts_only_timestamped.lua 0 1 --rate $RATE --size $PACKET_SIZE --file $FILE

else
    echo "No latency measurement"
    echo "Capturing packets on interface p1p2"
    sudo ./build/MoonGen ./scripts/pcap_files/dump-udp-pkts_not_timestamped.lua 0 1 --rate $RATE --size $PACKET_SIZE --file $FILE
fi



FILEOUT=histogram_udp_load.csv
if test -f "$FILEOUT"; then
    echo '[INFO]  moving histogram_dpdk.csv in pcap_files folder'
    sudo mv -f histogram_udp_load.csv scripts/pcap_files/histogram_dpdk.csv
fi

FILEOUT2=histogram_tutorial_udp.csv
if test -f "$FILEOUT2"; then
    echo '[INFO]  moving histogram_dpdk_not_correct.csv in pcap_files folder'
    sudo mv -f histogram_tutorial_udp.csv scripts/pcap_files/histogram_dpdk_not_correct.csv
fi

#move also pcap file to pcap_files folder
#move output file to pcap_files folder
echo '[INFO]  moving capture file in pcap_files folder'
sudo mv -f $FILE scripts/pcap_files/$FILE


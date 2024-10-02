#!/bin/bash

# Bind interface p1p2 to kernel driver

BUFFERSIZE=500
if [[ "$1" == "--buffer" || "$1" == "-B" ]]
then
	shift
	BUFFERSIZE=$1
    shift
else
	echo "If desired give buffer size (default 50MBytes)"
fi

FILENAME=capture_tshark_warp_packets.pcap
if [[ "$1" == "--filename" || "$1" == "-w" ]]
then
	shift
	FILENAME=$1
    shift
else
	echo "If desired give output filename with -w"
fi

touch tests/outputs/$FILENAME
chmod o=rw tests/outputs/$FILENAME

echo "ctrl+c to stop capture"
# set to 500Mbytes buffer (default was 2MBytes)
# ev add --snapshot-length 100
sudo tshark -i p1p2 -w tests/outputs/$FILENAME -B $BUFFERSIZE 

# Rebind interface to dpdk

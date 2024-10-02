#!/bin/bash
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

# choose which lua script to execute (default ethernet_load_no_timestamps.lua)
SCRIPT=ethernet_load_no_latency.lua
if [[ "$1" == "--script" || "$1" == "-s" ]]
then
    shift
    SCRIPT=$1
    shift
else
	echo "If desired can change script from test1_files (default ethernet_load_no_latency.lua, l2 load without latency measurement)"
fi


echo 'need to interrupt manually with ctrl+c!!'

# run moongen with lua script from interface 0 to interface 1
sudo ./build/MoonGen ./scripts/test1_files/$SCRIPT -r $RATE -s $PACKET_SIZE 0 1


# copy output files to current path
FILE=histogram_first.csv
if test -f "$FILE"; then
    echo '[INFO]  moving histogram_first.csv in test1_files folder'
    sudo mv -f histogram_first.csv scripts/test1_files/histogram_first.csv
fi
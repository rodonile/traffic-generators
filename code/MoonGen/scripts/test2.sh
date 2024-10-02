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

#default flows:4
FLOWS=4
if [[ "$1" == "--flows" || "$1" == "-f" ]]
then
    shift
    FLOWS=$1
    shift
else
	echo "If desired give number of flows as -f or --flows"
fi

#default execution time of moongen(60 seconds)
TIME=60
if [[ "$1" == "--time" || "$1" == "-t" ]]
then
    shift
    TIME=$1
    shift
else
	echo "If desired set execution time in seconds with -t or --time (default 1min)"
fi

# choose which lua script to execute (default udp_load_no_timestamps.lua with timestamps)
SCRIPT=udp_load_no_latency_4core.lua
if [[ "$1" == "--script" || "$1" == "-s" ]]
then
    shift
    SCRIPT=$1
    shift
else
	echo "If desired can change script from test2_files (default udp_load_no_latency_4core.lua, udp load without latency measurement)"
fi

echo 'Need to interrupt manually with ctrl+c!!'

# run moongen with lua script from interface 0 to interface 1
sudo ./build/MoonGen ./scripts/test2_files/$SCRIPT -r $RATE -s $PACKET_SIZE -f $FLOWS -t $TIME 0 1

# copy output files to current path
FILE=histogram_udp_load.csv
if test -f "$FILE"; then
    echo '[INFO]  moving histogram_udp_load.csv in test2_files folder'
    sudo mv -f histogram_udp_load.csv scripts/test2_files/histogram_udp_load.csv
fi

BUFFERSIZE=2000
if [[ "$1" == "--buffer" || "$1" == "-B" ]]
then
	shift
	BUFFERSIZE=$1
    shift
else
	echo "If desired give buffer size (default 50MBytes)"
fi

FILENAME=capture_tshark_udp.pcapng
if [[ "$1" == "--filename" || "$1" == "-w" ]]
then
	shift
	FILENAME=$1
    shift
else
	echo "If desired give output filename with -w"
fi

touch scripts/pcap_files/$FILENAME
chmod o=rw scripts/pcap_files/$FILENAME

echo "ctrl+c to stop capture"
# set to 50Mbytes buffer (default was 2MBytes) and 100bytes snapshot length (don't capture payload of big packets)
# ev add --snapshot-length 100
sudo tshark -i p1p2 -w scripts/pcap_files/$FILENAME -B $BUFFERSIZE 


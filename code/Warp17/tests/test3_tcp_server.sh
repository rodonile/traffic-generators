# tcp server that simply accepts connection and receives files acknowledging them (whithout sending sth back)

# Temporarily copy config files in tests folder
cp tests/config_files/test3_server_config.cfg tests/test3_server_config.cfg

CONFIGFILE='tests/test3_server_config.cfg'

# Cores that we want to use (default 3)
CORES=1F
if [ "$1" == "--cores" ]
then
    shift
    CORES=$1
    shift
    echo "--------Starting with allocated core mask: ${CORES} (FF=all, 1F=cores 1 to 5, other see warp17 docs)"
else
    echo "--------Starting with all cores! Change with --cores (FF=all, 1F=cores 1 to 5, other see warp17 docs)"
fi

# Memory (GB)
MEMORY=16384
if [ "$1" == "--memory" ]
then
    shift
    MEMORY=$1
    shift
    # Convert memory to MBytes
    if [ $MEMORY == 32 ]
    then
        MEMORY=32768
    elif [ $MEMORY == 24 ]
    then
        MEMORY=24576
    elif [ $MEMORY == 16 ]
    then
        MEMORY=16384
    fi
    echo "--------Starting with allocated ${MEMORY} Mbytes of memory"
else
	echo "Can change memory allocation (16GB default) with --memory option (Mbytes)"
    echo "Simplified standard values in GB that can be passed: --memory 16, 24, 32 --> will be recognized as GB!"
fi

TCB_POOL=$MEMORY

# Request size (bytes)
REQUEST=500
if [ "$1" == "--request" ]
then
	shift
	REQUEST=$1
    shift
else
	echo "Pass request size with --request (default 500 bytes)"
fi

# Response size (bytes)
RESPONSE=0
if [ "$1" == "--response" ]
then
    shift
    RESPONSE=$1
    shift
else
	echo "Pass response size with --response (default 0 bytes, i.e. server doesn't send anything back other than acks)"
fi


sed -i "/set tests server raw port 1 test-case-id 0 data-req-plen 500 data-resp-plen 0/c\set tests server raw port 1 test-case-id 0 data-req-plen ${REQUEST} data-resp-plen ${RESPONSE}" $CONFIGFILE

./build/warp17 -c $CORES -m $MEMORY -- --qmap-default max-q --tcb-pool-sz $TCB_POOL --cmd-file $CONFIGFILE

rm tests/test3_server_config.cfg
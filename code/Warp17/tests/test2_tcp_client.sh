#!/bin/bash

################################
# Copy config files (from tests/config_files)
################################
cp tests/config_files/test2_1_tcp_session.cfg tests/test2_1_tcp_session.cfg
cp tests/config_files/test2_100_tcp_sessions.cfg tests/test2_100_tcp_sessions.cfg
cp tests/config_files/test2_1k_tcp_sessions.cfg tests/test2_1k_tcp_sessions.cfg
cp tests/config_files/test2_10k_tcp_sessions.cfg tests/test2_10k_tcp_sessions.cfg

# Cores that we want to use (default all)
CORES=FF
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
MEMORY=32768
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
	echo "Can change memory allocation (32GB default) with --memory option (Mbytes)"
    echo "Simplified standard values in GB that can be passed: --memory 16, 24, 32 --> will be recognized as GB!"
fi

TCB_POOL=$MEMORY
#if [ "$1" == "--tcb" ]
#then
#    shift
#    TCB_POOL=$1
#    shift
#    echo "Allocated $((TCB_POOL>>10)) million POOLS to TCB --> max achievable $(((TCB_POOL>>10)/2)) TCP sessions"
#else
#	#echo "Can change number of TCB pools allocated with --tcb (e.g. 200 --> allocate ~200k pools, see documentation if needed)"
#    #echo "--------->The software needs 16M pools for 8M TCP sessions (8M clients and 8M server sessions need to be maintained in memory)"
#    echo "--------->Default allocated TCB pools: max nr of pools according to allocated memory"
#fi

# Max number of sessions
SESSIONS="100"
if [ "$1" == "--sessions" ]
then
    shift
    SESSIONS=$1
    shift
    echo "--------Max number of TCP sessions that can be built = ${SESSIONS}. Change with --sessions, possible values: 1, 100(default), 1k, 10k"
else
    echo "--------Max number of TCP sessions that can be built = ${SESSIONS} (default value applied). Change with --sessions, possible values: 1, 100, 200k(default), 10M"
fi

# Request size (bytes)
REQUEST=100
if [ "$1" == "--request" ]
then
	shift
	REQUEST=$1
    shift
else
	echo "Pass request size with --request (default 100 bytes)"
fi

# Response size (bytes)
RESPONSE=200
if [ "$1" == "--response" ]
then
    shift
    RESPONSE=$1
    shift
else
	echo "Pass response size with --response (default 200 bytes)"
fi

# Execution time
TIME=180
if [ "$1" == "--time" ]
then
    shift
    TIME=$1
    shift
else
	echo "Pass execution time with --time (default 180 seconds)"
fi

# Uptime the setup connections stay up
UPTIME=infinite
if [ "$1" == "--uptime" ]
then
    shift
    UPTIME=$1
    shift
else
	echo "Pass uptime with --uptime (default infinite)"
fi

# Downtime the closed connection stay down before being reopened
DOWNTIME=infinite
if [ "$1" == "--downtime" ]
then
    shift
    DOWNTIME=$1
    shift
else
	echo "Pass downtime with --downtime (default infinite)"
fi

# Number of session that are setup per second
SETUP=10000
if [ "$1" == "--setup" ]
then
    shift
    SETUP=$1
    shift
else
	echo "Pass number of sessions setup per second during execution time with --setup (default=10000)"
fi

# Number of session that are setup per second
TEARDOWN=10000
if [ "$1" == "--teardown" ]
then
    shift
    TEARDOWN=$1
    shift
else
	echo "Pass number of sessions tore down per second when sessions uptime has expired with --teardown (default=10000)"
fi

# Number of session that send data per second
RATE=0
if [ "$1" == "--rate" ]
then
    shift
    RATE=$1
    shift
else
	echo "Pass sending sessions per second with --rate (default 0 sess/s)"
fi


################################
# Set configfile and adjust it with respect to user input
################################
if [ "$SESSIONS" == "1" ]
then
    CONFIGFILE='tests/test2_1_tcp_session.cfg'
    sed -i "/set tests client raw port 0 test-case-id 0 data-req-plen 100 data-resp-plen 200/c\set tests client raw port 0 test-case-id 0 data-req-plen ${REQUEST} data-resp-plen ${RESPONSE}" $CONFIGFILE
    sed -i "/set tests criteria port 0 test-case-id 0 run-time 180/c\set tests criteria port 0 test-case-id 0 run-time ${TIME}" $CONFIGFILE
    sed -i "/set tests timeouts port 0 test-case-id 0 uptime 30/c\set tests timeouts port 0 test-case-id 0 uptime ${UPTIME}" $CONFIGFILE
    sed -i "/set tests timeouts port 0 test-case-id 0 downtime 10/c\set tests timeouts port 0 test-case-id 0 downtime ${DOWNTIME}" $CONFIGFILE
    sed -i "/set tests rate port 0 test-case-id 0 send 1/c\set tests rate port 0 test-case-id 0 send ${RATE}" $CONFIGFILE
elif [ "$SESSIONS" == "100" ]
then
    CONFIGFILE='tests/test2_100_tcp_sessions.cfg'
    sed -i "/set tests client raw port 0 test-case-id 0 data-req-plen 100 data-resp-plen 200/c\set tests client raw port 0 test-case-id 0 data-req-plen ${REQUEST} data-resp-plen ${RESPONSE}" $CONFIGFILE
    sed -i "/set tests criteria port 0 test-case-id 0 run-time 180/c\set tests criteria port 0 test-case-id 0 run-time ${TIME}" $CONFIGFILE
    sed -i "/set tests timeouts port 0 test-case-id 0 uptime 60/c\set tests timeouts port 0 test-case-id 0 uptime ${UPTIME}" $CONFIGFILE
    sed -i "/set tests timeouts port 0 test-case-id 0 downtime 30/c\set tests timeouts port 0 test-case-id 0 downtime ${DOWNTIME}" $CONFIGFILE
    sed -i "/set tests rate port 0 test-case-id 0 open 10/c\set tests rate port 0 test-case-id 0 open ${SETUP}" $CONFIGFILE
    sed -i "/set tests rate port 0 test-case-id 0 close 10/c\set tests rate port 0 test-case-id 0 close ${TEARDOWN}" $CONFIGFILE
    sed -i "/set tests rate port 0 test-case-id 0 send infinite/c\set tests rate port 0 test-case-id 0 send ${RATE}" $CONFIGFILE
elif [ "$SESSIONS" == "1k" ]
then
    CONFIGFILE='tests/test2_1k_tcp_sessions.cfg'
    sed -i "/set tests client raw port 0 test-case-id 0 data-req-plen 100 data-resp-plen 200/c\set tests client raw port 0 test-case-id 0 data-req-plen ${REQUEST} data-resp-plen ${RESPONSE}" $CONFIGFILE
    sed -i "/set tests criteria port 0 test-case-id 0 run-time 180/c\set tests criteria port 0 test-case-id 0 run-time ${TIME}" $CONFIGFILE
    sed -i "/set tests timeouts port 0 test-case-id 0 uptime 60/c\set tests timeouts port 0 test-case-id 0 uptime ${UPTIME}" $CONFIGFILE
    sed -i "/set tests timeouts port 0 test-case-id 0 downtime 30/c\set tests timeouts port 0 test-case-id 0 downtime ${DOWNTIME}" $CONFIGFILE
    sed -i "/set tests rate port 0 test-case-id 0 open 10000/c\set tests rate port 0 test-case-id 0 open ${SETUP}" $CONFIGFILE
    sed -i "/set tests rate port 0 test-case-id 0 close 10000/c\set tests rate port 0 test-case-id 0 close ${TEARDOWN}" $CONFIGFILE
    sed -i "/set tests rate port 0 test-case-id 0 send 10000/c\set tests rate port 0 test-case-id 0 send ${RATE}" $CONFIGFILE
elif [ "$SESSIONS" == "10k" ]
then
    CONFIGFILE='tests/test2_10k_tcp_sessions.cfg'
    sed -i "/set tests client raw port 0 test-case-id 0 data-req-plen 100 data-resp-plen 200/c\set tests client raw port 0 test-case-id 0 data-req-plen ${REQUEST} data-resp-plen ${RESPONSE}" $CONFIGFILE
    sed -i "/set tests criteria port 0 test-case-id 0 run-time 180/c\set tests criteria port 0 test-case-id 0 run-time ${TIME}" $CONFIGFILE
    sed -i "/set tests timeouts port 0 test-case-id 0 uptime infinite/c\set tests timeouts port 0 test-case-id 0 uptime ${UPTIME}" $CONFIGFILE
    sed -i "/set tests timeouts port 0 test-case-id 0 downtime infinite/c\set tests timeouts port 0 test-case-id 0 downtime ${DOWNTIME}" $CONFIGFILE
    sed -i "/set tests rate port 0 test-case-id 0 open 100000/c\set tests rate port 0 test-case-id 0 open ${SETUP}" $CONFIGFILE
    sed -i "/set tests rate port 0 test-case-id 0 close 100000/c\set tests rate port 0 test-case-id 0 close ${TEARDOWN}" $CONFIGFILE
    sed -i "/set tests rate port 0 test-case-id 0 send 0/c\set tests rate port 0 test-case-id 0 send ${RATE}" $CONFIGFILE
fi


################################
# Run WARP17
################################
./build/warp17 -c $CORES -m $MEMORY -- --qmap-default max-q --tcb-pool-sz $TCB_POOL --cmd-file $CONFIGFILE

################################
# Remove modified config files
################################
rm tests/test2_1_tcp_session.cfg
rm tests/test2_100_tcp_sessions.cfg
rm tests/test2_1k_tcp_sessions.cfg
rm tests/test2_10k_tcp_sessions.cfg
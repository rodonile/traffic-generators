#!/bin/bash

################################
#Copy config_files (from tests/config_files)
################################
cp tests/config_files/test1_1_tcp_session.cfg tests/test1_1_tcp_session.cfg
cp tests/config_files/test1_100_tcp_sessions.cfg tests/test1_100_tcp_sessions.cfg
cp tests/config_files/test1_200k_tcp_sessions.cfg tests/test1_200k_tcp_sessions.cfg
cp tests/config_files/test1_10M_tcp_sessions.cfg tests/test1_10M_tcp_sessions.cfg

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
SESSIONS="200k"
if [ "$1" == "--sessions" ]
then
    shift
    SESSIONS=$1
    shift
    echo "--------Max number of TCP sessions that can be built = ${SESSIONS}. Change with --sessions, possible values: 1, 100, 200k(default), 10M"
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

########
# File for dumping stats
STAT=no
if [ "$1" == "--statsfile" ]
then
    shift
    STAT=$1
    shift
    echo "---------------------> Collecting warp's output in output_stats/${STAT}"
fi
# Scraping period (default: 30 seconds)
PERIOD=30
if [ "$1" == "--period" ]
then
    shift
    PERIOD=$1
    shift
    echo "---------------------> Scraping approximately every ${PERIOD} seconds"
fi

################################
# Set configfile and adjust it with respect to user input
################################
if [ "$SESSIONS" == "1" ]
then
    CONFIGFILE='tests/test1_1_tcp_session.cfg'
    sed -i "/set tests client raw port 0 test-case-id 0 data-req-plen 100 data-resp-plen 200/c\set tests client raw port 0 test-case-id 0 data-req-plen ${REQUEST} data-resp-plen ${RESPONSE}" $CONFIGFILE
    sed -i "/set tests server raw port 1 test-case-id 0 data-req-plen 100 data-resp-plen 200/c\set tests server raw port 1 test-case-id 0 data-req-plen ${REQUEST} data-resp-plen ${RESPONSE}" $CONFIGFILE
    sed -i "/set tests criteria port 0 test-case-id 0 run-time 180/c\set tests criteria port 0 test-case-id 0 run-time ${TIME}" $CONFIGFILE
    sed -i "/set tests timeouts port 0 test-case-id 0 uptime 30/c\set tests timeouts port 0 test-case-id 0 uptime ${UPTIME}" $CONFIGFILE
    sed -i "/set tests timeouts port 0 test-case-id 0 downtime 10/c\set tests timeouts port 0 test-case-id 0 downtime ${DOWNTIME}" $CONFIGFILE
    sed -i "/set tests rate port 0 test-case-id 0 send 1/c\set tests rate port 0 test-case-id 0 send ${RATE}" $CONFIGFILE
elif [ "$SESSIONS" == "100" ]
then
    CONFIGFILE='tests/test1_100_tcp_sessions.cfg'
    sed -i "/set tests client raw port 0 test-case-id 0 data-req-plen 100 data-resp-plen 200/c\set tests client raw port 0 test-case-id 0 data-req-plen ${REQUEST} data-resp-plen ${RESPONSE}" $CONFIGFILE
    sed -i "/set tests server raw port 1 test-case-id 0 data-req-plen 100 data-resp-plen 200/c\set tests server raw port 1 test-case-id 0 data-req-plen ${REQUEST} data-resp-plen ${RESPONSE}" $CONFIGFILE
    sed -i "/set tests criteria port 0 test-case-id 0 run-time 180/c\set tests criteria port 0 test-case-id 0 run-time ${TIME}" $CONFIGFILE
    sed -i "/set tests timeouts port 0 test-case-id 0 uptime 60/c\set tests timeouts port 0 test-case-id 0 uptime ${UPTIME}" $CONFIGFILE
    sed -i "/set tests timeouts port 0 test-case-id 0 downtime 30/c\set tests timeouts port 0 test-case-id 0 downtime ${DOWNTIME}" $CONFIGFILE
    sed -i "/set tests rate port 0 test-case-id 0 open 10/c\set tests rate port 0 test-case-id 0 open ${SETUP}" $CONFIGFILE
    sed -i "/set tests rate port 0 test-case-id 0 close 10/c\set tests rate port 0 test-case-id 0 close ${TEARDOWN}" $CONFIGFILE
    sed -i "/set tests rate port 0 test-case-id 0 send infinite/c\set tests rate port 0 test-case-id 0 send ${RATE}" $CONFIGFILE
elif [ "$SESSIONS" == "200k" ]
then
    CONFIGFILE='tests/test1_200k_tcp_sessions.cfg'
    sed -i "/set tests client raw port 0 test-case-id 0 data-req-plen 100 data-resp-plen 200/c\set tests client raw port 0 test-case-id 0 data-req-plen ${REQUEST} data-resp-plen ${RESPONSE}" $CONFIGFILE
    sed -i "/set tests server raw port 1 test-case-id 0 data-req-plen 100 data-resp-plen 200/c\set tests server raw port 1 test-case-id 0 data-req-plen ${REQUEST} data-resp-plen ${RESPONSE}" $CONFIGFILE
    sed -i "/set tests criteria port 0 test-case-id 0 run-time 180/c\set tests criteria port 0 test-case-id 0 run-time ${TIME}" $CONFIGFILE
    sed -i "/set tests timeouts port 0 test-case-id 0 uptime 60/c\set tests timeouts port 0 test-case-id 0 uptime ${UPTIME}" $CONFIGFILE
    sed -i "/set tests timeouts port 0 test-case-id 0 downtime 30/c\set tests timeouts port 0 test-case-id 0 downtime ${DOWNTIME}" $CONFIGFILE
    sed -i "/set tests rate port 0 test-case-id 0 open 10000/c\set tests rate port 0 test-case-id 0 open ${SETUP}" $CONFIGFILE
    sed -i "/set tests rate port 0 test-case-id 0 close 10000/c\set tests rate port 0 test-case-id 0 close ${TEARDOWN}" $CONFIGFILE
    sed -i "/set tests rate port 0 test-case-id 0 send 10000/c\set tests rate port 0 test-case-id 0 send ${RATE}" $CONFIGFILE
elif [ "$SESSIONS" == "10M" ]
then
    CONFIGFILE='tests/test1_10M_tcp_sessions.cfg'
    sed -i "/set tests client raw port 0 test-case-id 0 data-req-plen 100 data-resp-plen 200/c\set tests client raw port 0 test-case-id 0 data-req-plen ${REQUEST} data-resp-plen ${RESPONSE}" $CONFIGFILE
    sed -i "/set tests server raw port 1 test-case-id 0 data-req-plen 100 data-resp-plen 200/c\set tests server raw port 1 test-case-id 0 data-req-plen ${REQUEST} data-resp-plen ${RESPONSE}" $CONFIGFILE
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
if [ "$STAT" == "no" ]
then
    ./build/warp17 -c $CORES -m $MEMORY -- --qmap-default max-q --tcb-pool-sz $TCB_POOL --cmd-file $CONFIGFILE
else
    sed -i "/show tests ui/c\#show tests ui" $CONFIGFILE
    
    /usr/bin/expect <<EOD
    spawn sh -c {
        ./build/warp17 -c ${CORES} -m ${MEMORY} -- --qmap-default max-q --tcb-pool-sz ${TCB_POOL} --cmd-file ${CONFIGFILE} 2>&1 | tee tests/output_stats/${STAT}
    }
    # Initial test-information outputs
    sleep 5
    expect "warp17>\r"
    send -- "show port info\r"
    send -- "show tests config port 0\r"
    sleep 5
    
    # Periodic statistics outputs
    while { true } {
    expect "warp17>\r"
    sleep $(($PERIOD-5))
    # add here statistics that you want to periodically output in text file (see warp's user guide to know which tests exist)
    send -- "show tests state port 0\r"
    send -- "show tcp statistics\r"
    send -- "show tsm statistics\r"
    sleep 5
    }
EOD
fi

################################
# Remove modified config files
################################
rm tests/test1_1_tcp_session.cfg
rm tests/test1_100_tcp_sessions.cfg
rm tests/test1_200k_tcp_sessions.cfg
rm tests/test1_10M_tcp_sessions.cfg
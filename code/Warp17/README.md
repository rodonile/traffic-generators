# Usage
## Setup
- build warp17 (common-branch)
- place *tests* folder in warp17 folder
<!-- end of the list -->

## How to run testing scripts
- Navigate to warp17 folder: `cd /home/rodonile/warp17`
- Run desired test: `./tests/test1_tcp_sessions.sh --some_parameter ecc....`
- see *warp17_cheatsheet.txt* for examples on how to run scripts
<!-- end of the list -->

## Available tests
- *test1_tcp_sessions.sh*: setup tcp sessions and send tcp data packets from interface 0000:05:00.0 (p1p1) to interface 0000:05:00.1 (p1p2). Both interfaces need to be dpdk-binded. Arguments(following order required):
    - **--cores** bitmask specifying physical cores to be used (default: FF i.e. all cores used)
    - **--memory** memory to allocate to warp's execution (in hugepages of 1GB)
    - **--sessions** max number of tcp sessions that can be built. Choose amongst 1, 100, 200k(default) and 10M
    - **--request** tcp request size in bytes. Default 100bytes (max 4096 bytes, otherwise need to change also warp's tcp-windows-size and MTU!)
    - **--response** tcp response size in bytes (can also be 0 if we want that warp server only acks the receiving packets without sending back a response to every request). Default 200bytes (max 4096 bytes, otherwise need to change also warp's tcp-windows-size and MTU!)
    - **--time** execution time after which warp will stop sending packets. Default 180seconds.
    - **--uptime** amount of time (in seconds) the client should keep the connection up (and send application traffic) before initiating a close. Default: infinite.
    - **--downtime** amount of time (in seconds) the client should keep the connection down after a closebefore initiating a reconnect (infinite allows the clients to stay down forever).
    - **--setup** number of connections that the clients in the test are allowed to initiate per second. Default: 10000.
    - **--teardown** number of connections that the clients in the test are allowed to close per second. Default: 10000.
    - **--rate** number of connections that the clients in the test are allowed to send traffic on per second. If number of open connections < RATE, then warp will send more requests per second from the open connections. Default: 0 (don't send data other than TCP session setup packets).
    - **--statsfile** output file-name where we want the statistics to be written, e.g. --stat statistics.txt. Default --stat no (normal warp execution where no statiscics are collected).
    - **--period** scraping period for stats (only useful if statistics are enabled, default 30 seconds)
<br/><br/>
- *test2_tcp_client.sh*: setup tcp sessions and send tcp data packets from dpdk-binded interface 0000:05:00.0 (p1p1) to kernel binded interface 0000:05:00.1 (p1p2). A tcp server needs to run at interface p1p2 (e.g. *tcpserver.py* or *tcpserver_only_ack.py*). <br/> Arguments are the same as in test1 (other than --stat which is not implemented here yet).
<br/><br/>
- *test3_tcp_server.sh*: warp17 only listens as server on interface p1p2 at address 10.0.0.253. Another tcp client that will attempt to setup the connections is required (e.g. trex). <br/> Arguments (following order required):
    - **--cores** bitmask specifying physical cores to be used (default: 1F i.e. cores 1 to 5, 3 effectively used for packet processing!)
    - **--memory** memory to allocate to warp's execution (in hugepages of 1GB, default=16GB)
    - **--request** tcp request size in bytes. Default 500bytes.
    - **--response** tcp response size in bytes. Default 0 bytes. 
<br/><br/>
- *test4_multiple_tests.sh*: creates 8 tcp tests with different configuration to simulate real-life internet traffic (TODO: ev. increase number of tests). Runs for 10min
<br/><br/>
- *test5_imix.sh*: same as warp's test_14_imix.cfg (refer to github docs)
- *test6_udp.sh*: send udp packets from interface 0000:05:00.0 (p1p1) to interface 0000:05:00.1 (p1p2). Both interfaces need to be dpdk-binded. Arguments(following order required):
    - **--cores** bitmask specifying physical cores to be used (default: FF i.e. all cores used)
    - **--rate** number of source (src_ip & src_port) and destination (dst_ip & dst_port) pairs that need to exchange udp packets
    - **--memory** memory to allocate to warp's execution (in hugepages of 1GB, default=16GB)
    - **--request** udp request size in bytes. Default 100bytes.
    - **--response** udp response size in bytes (default 200bytes, can also be 0, this way we will have one-way udp traffic). 
    - **--time** execution time after which warp will stop sending packets. Default 180seconds.
    - **--uptime** time you want to keep up "udp sessions"
    - **--downtime** time warp should sleep until resuming sending from connection
    - **--rate** number of connections that the clients in the test are allowed to send traffic on per second. If number of open connections < RATE, then warp will send more requests per second from the open connections. Default: 0 (don't send data other than TCP session setup packets).
    - **--statsfile** output file-name where we want the statistics to be written, e.g. --stat statistics.txt. Default --stat no (normal warp execution where no statiscics are collected).
    - **--period** scraping period for stats (only useful if statistics are enabled, default 30 seconds)
- *test7_udp_client.sh*: send udp packets from interface 0000:05:00.0 (p1p1) to interface 0000:05:00.1 (p1p2). p1p1 dpdk-binded and p1p2 kernel-binded (for debugging / capture packets). Arguments are the same as for *test6_udp.sh*
<!-- end of the list -->


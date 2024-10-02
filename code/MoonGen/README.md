# Usage
## Setup
- place *scripts* folder in Moongen folder
<!-- end of the list -->

## How to run testing scripts
- Navigate to Moongen folder: `cd /home/rodonile/moongen/MoonGen/`
- Run desired test: `./scripts/test1.sh --some_parameter ecc....`
- see *Moongen_cheatsheet.txt* for examples on how to run scripts
<!-- end of the list -->

## Available tests
- *test1.sh*: simply send layer 2 ethernet packets from interface 0000:05:00.0 (p1p1) to interface 0000:05:00.1 (p1p2). Optional arguments(in following order):
    - **-r / --rate** bandwidth in Mbps (default: 10000)
    - **-b / --bytesize** packet size in bytes (default: 60)
    - **-s / --script** .lua script to use: 
        - **ethernet_load_no_latency.lua (default):** one-directional traffic from p1p1 to p1p2 with 2 threads and 2 queues
        - **ethernet_load_latency.lua:** one-directional traffic from p1p1 to p1p2 with 2 threads and 2 queues with latency measurement
        - **ethernet_load.lua:** same as l2_load_latency example from MoonGen github repo, traffic sent from both interfaces (duplex) with one thread and one queue per interface
        - **ethernet_load_duplex_4cores:** duplex traffic with 2 threads per interface
- *test2.sh*: send udp packets from interface 0000:05:00.0 (p1p1) to interface 0000:05:00.1 (p1p2). Optional arguments(in following order):
    - **-r / --rate** bandwidth in Mbps (default: 10000)
    - **-b / --bytesize** packet size in bytes (default: 60)
    - **-f / --flows** number of flows (default: 4)
    - **-t / --time** execution time of moongen (default: 60)
    - **-s / --script** .lua script to use:
        - **udp_load_no_latency_xcore.lua (default):** one-directional traffic from p1p1 to p1p2 with x threads and x queues (up to 4 threads/cores)
        - **udp_load_latency_xcore.lua:** one-directional traffic from p1p1 to p1p2 with x threads and x queues (up to 4 threads/cores) with latency measurement
        - **udp_load_duplex.lua:** duplex traffic p1p1 <--> p1p2 with 3 threads per interface (6 threads in total)
        - **udp_load_duplex_2cores.lua:** duplex traffic p1p1 <--> p1p2 with 1 thread per interface (2 threads in total)
        - **ethernet_load.lua:** same as udp_load_latency example from MoonGen github repo, traffic sent from both interfaces with one thread and one queue per interface
- *test_timestamping.sh*: runs dpdk hardware timestamping tests and gives feedback results for dpdk-installed interfaces.

- *dpdk_pcap.sh*: packet capture with built in moongen pcap software. This script starts packet capture tool (dump-pkts.lua) on interface p1p2 and also start udp traffic flow from interface 1 to interface 2. Timestamps are automatically added to each packet (in software). Optional arguments (in following order):
    - **-r / --rate** bandwidth in Mbps (default: 10000)
    - **-b / --bytesize** packet size in bytes (default: 60)
    - **-f / --file** .pcap output capture file (default capture.pcap), which will be placed in *scripts/pcap_files* folder
    - **-l / --latency** Either --latency no (default option)  or --latency yes or --latency only (captures PTP packets, just for debugging --> disrupts correct functionality of latency measurements). Results of latency measurements are saved in /pcap_files/histogram_dpdk.csv
- *start_tshark*: Start tshark-packet-capturer on interface p1p2 (interface needs to be binded to kernel driver --> see cheatsheet). Optional arguments(in following order):
    - **-B / --buffer** dimension of tshark buffer (where tshark stores packets before writing them in output file), in Mbytes (default: 2000)
    - **-w / --filename** output .pcap capture file (default: capture_tshark_udp.pcapng)
- *tshark_pcap_traffic*: generate moongen traffic from dpdk-binded interface p1p1 directed towards kernel-binded interface p1p2. Optional arguments(in following order):
    - **-r / --rate** bandwidth in Mbps (default: 10000)
    - **-b / --bytesize** packet size in bytes (default: 60)
    - **-l / --latency** Give --latency cap argument if want to only start latency measurement task (no packet generation) and to capture PTP packets on p1p2
<!-- end of the list -->






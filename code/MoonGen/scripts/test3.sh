#!/bin/bash
# send tcp flood towards 10.0.0.253
# TO TEST WHAT WARP DOES IF TCP FLOOD ARRIVES

echo 'Need to interrupt manually with ctrl+c!!'

# run moongen with lua script from interface 0 to interface 1
#sudo ./build/MoonGen ./scripts/test2_files/test3_files/tcp_flood.lua -r $RATE -s $PACKET_SIZE -f $FLOWS -t $TIME 0

# using default values in lua scritp
sudo ./build/MoonGen ./scripts/test3_files/test3_files/tcp_flood.lua 0

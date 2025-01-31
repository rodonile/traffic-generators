from trex_stl_lib.api import *
import os

# stream from pcap file. continues pps 10 in sec 

CP = os.path.join(os.path.dirname(__file__))

class STLS1(object):

    def get_streams (self, direction = 0, **kwargs):
        return [STLStream(packet = STLPktBuilder(pkt = os.path.join(CP, "udp_164bytes.pcap")),                      # WTF around 150bytes there is enormous overhead
                         mode = STLTXCont(pps=10)) ] #rate continues, could be STLTXSingleBurst,STLTXMultiBurst     # and I have no idea why??


# dynamic load - used for trex console or simulator
def register():
    return STLS1()
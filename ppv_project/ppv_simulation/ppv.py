#!/usr/bin/env python3

import argparse
import sys
import socket
import random
import struct
import re

from scapy.all import sendp, send, srp1
from scapy.all import Packet, hexdump
from scapy.all import Ether, IntField
from scapy.all import bind_layers
import readline

class P4ppv(Packet):
    name = "P4ppv"
    fields_desc = [
                    IntField("ppv", 0),
                    IntField("zero", 0),
                    IntField("one", 0),
                    IntField("two", 0),
                    IntField("three", 0)]

bind_layers(Ether, P4ppv, type=0x1234)

class NumParseError(Exception):
    pass

class OpParseError(Exception):
    pass

class Token:
    def __init__(self,type,value = None):
        self.type = type
        self.value = value

def main():
    iface = 'eth0'
    while True:
        s = random.randint(0,3)
        try:
            pkt = Ether(dst='00:04:00:00:00:00', type=0x1234) / P4ppv(ppv=int(s),
                                              zero=0,
                                              one=0,
                                              two=0,
                                              three=0)
            pkt = pkt/' '

            #pkt.show()
            resp = srp1(pkt, iface=iface, timeout=1, verbose=False)
            if resp:
                p4ppv=resp[P4ppv]
                if p4ppv:
                    print("Current rates: ")
                    print("[%2d b/s, %2d b/s, %2d b/s, %2d b/s ]"%(p4ppv.zero,p4ppv.one,p4ppv.two,p4ppv.three))
                else:
                    print("cannot find P4ppv header in the packet")
            else:
                print("Didn't receive response")
        except Exception as error:
            print(error)


if __name__ == '__main__':
    main()

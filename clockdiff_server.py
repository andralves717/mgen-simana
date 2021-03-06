#!/usr/bin/env python3

'''
Clockdiff Server
@author: Vitor Cunha (vitorcunha@av.it.pt)
'''

import time
import threading
import socket

HOST = ''                 # Symbolic name meaning all available interfaces
PORT = 31048              # Arbitrary non-privileged port
RTT_ITERS = 1000

def main():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.bind((HOST, PORT))

    # Measuring RTT
    i = RTT_ITERS

    while i > 0:
        data, addr = s.recvfrom(4096)
        s.sendto(data, addr)
        i = i - 1

    # Measuring Clock offset
    while True:
        data, addr = s.recvfrom(4096)

        if (data == b'S'):
            s.close()
            break
        
        local_ts     = int(time.time() * 1000000)
        remote_ts    = int.from_bytes(data, byteorder='big', signed=False)
        delta        = (local_ts - remote_ts)                                   # server timestamp - client timestamp
        # data         = delta.to_bytes(128 // 8, byteorder='big', signed=True)
        # data2        = local_ts.to_bytes(128 // 8,  byteorder='big', signed=False)
        data = str([delta, local_ts]).encode()
        s.sendto(data, addr)
        
if __name__ == "__main__":
    main()
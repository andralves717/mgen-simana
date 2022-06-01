#!/usr/bin/env python3

'''
Calculate Clock Offset between two hosts

v1 -- very simply approach

@author: Vitor Cunha (vitorcunha@av.it.pt)
'''

import time
import socket
import statistics
import sys

# HOST = '68.183.74.132'
HOST = sys.argv[1]
PORT = 31048

EXECEUTION_TIME = int(sys.argv[2])
INITIAL_TIME = time.time()

RTT_ITERS = 1000
SLEEP_T   = 0.0001

def __remove_outliers(values):
    values.sort()

    avg = statistics.mean(values)
    sigma = statistics.stdev(values)
    two_sigma = 2 * sigma

    lower_thr = avg - (2 * sigma)
    higher_thr = avg + (2 * sigma)
    out = list()
    for i in values:
        if i < lower_thr or i > higher_thr:
            continue
        out.append(i)
    return out

def __measure_rtt(s):
    rtt = list()
    for i in range(0, RTT_ITERS):
        time.sleep(SLEEP_T)
        try:
            s.sendto(int(time.time() * 1000000).to_bytes(128 // 8, byteorder='big'), (HOST, PORT))
            s.settimeout(2)

            data, address = s.recvfrom(4096)
            rcv_ts        = int(time.time() * 1000000)
            send_ts       = int.from_bytes(data, byteorder='big', signed=False)

            delta = (rcv_ts - send_ts)
            #print(f"{delta}")
            rtt.append(delta)
        except:
            print(f"F")

    rtt = __remove_outliers(rtt)
    return statistics.mean(rtt) 

def __clockdiff(s, rtt):
    while True:
        time.sleep(SLEEP_T)
        try:
        # if True:
            s.sendto(int(time.time() * 1000000).to_bytes(128 // 8, byteorder='big'), (HOST, PORT))
            s.settimeout(2)

            data, address = s.recvfrom(4096)
            delta = int.from_bytes(data, byteorder='big', signed=True)
            print(f"{time.time()*1000000} {delta - (rtt / 2)}")

            if(time.time() - INITIAL_TIME >= EXECEUTION_TIME):
                s.sendto(b'S', (HOST, PORT))
                break

            #print(f"{delta},{rtt}")
        except:
            print(f"FUCK")

def main():
    s   = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0)
    rtt = __measure_rtt(s)
    __clockdiff(s, rtt)
    s.close()

if __name__ == "__main__":
    main()
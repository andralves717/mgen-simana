#!/usr/bin/env python3

import sys

OFFSETS_FILENAME = sys.argv[1]
MGEN_FILENAME = sys.argv[2]
MGEN_NEW_FILENAME = sys.argv[3]

def closest(lst, K):
      
    return lst[min(range(len(lst)), key = lambda i: abs(lst[i]-K))]

def main():
    offsets = dict()

    wf = open(MGEN_NEW_FILENAME, "wt", encoding="utf-8")

    with open(OFFSETS_FILENAME, "rt", encoding="utf-8") as f:
        for line in f.readlines():
            l = line.split()
            ts = int(l[1])
            offset = int(l[2])
            idx = int(ts/10000)
            if idx not in offsets.keys():
                offsets[idx] = dict()
            offsets[idx][ts] = offset

    with open(MGEN_FILENAME, "rt", encoding="utf-8") as f:
        for line in f.readlines():
            l = line.split()
            sent = int(l[1])
            idx = int(sent/10000)
            if idx in offsets.keys():
                timestamps = list(offsets[idx].keys())

                ts = closest(timestamps, sent)

                offset = offsets[idx][ts]

                wf.write(f"MGEN {sent - offset} {l[2]} {l[3]} {l[4]}\n")
            else:
                print(f"Server timestamp: {sent}\t ")

    wf.close()

if __name__ == "__main__":
    main()
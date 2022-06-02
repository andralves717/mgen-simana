#!/usr/bin/env bash

INSTALL_PATH=$HOME/.local/bin

if [ "$EUID" -eq 0 ]; then
    INSTALL_PATH=/bin
fi

if [[ ! ":$PATH:" == *":$INSTALL_PATH:"* ]]; then
    mkdir -p $INSTALL_PATH
    echo "Relog and the rerun ./mgen-simulator-install.sh"

fi

[[ ! -d "$INSTALL_PATH" ]] && mkdir -p "$INSTALL_PATH"

chmod +x mgen-simulator.sh
chmod +x diffclock.sh
chmod +x clockdiff_client.py
chmod +x clockdiff_server.py
chmod +x analyze_latency_jitter_mgen.awk
chmod +x analyze_latency_jitter_mgen_seq.awk
chmod +x analyze_latency_jitter_mgen_seg.awk
chmod +x analyze_latency_jitter_mgen_clockdiff_seq.awk
chmod +x remove_extras.sh
chmod +x correct_sent_timestamp.py

cp mgen-simulator.sh $INSTALL_PATH/mgen-simulator
cp diffclock.sh $INSTALL_PATH/diffclock
cp clockdiff_client.py $INSTALL_PATH/clockdiff_client
cp clockdiff_server.py $INSTALL_PATH/clockdiff_server
cp analyze_latency_jitter_mgen.awk $INSTALL_PATH/analyze_latency_jitter_mgen
cp analyze_latency_jitter_mgen_seq.awk $INSTALL_PATH/analyze_latency_jitter_mgen_seq
cp analyze_latency_jitter_mgen_seg.awk $INSTALL_PATH/analyze_latency_jitter_mgen_seg
cp analyze_latency_jitter_mgen_clockdiff_seq.awk $INSTALL_PATH/analyze_latency_jitter_mgen_clockdiff_seq
cp remove_extras.sh $INSTALL_PATH/remove_extras
cp correct_sent_timestamp.py $INSTALL_PATH/correct_sent_timestamp

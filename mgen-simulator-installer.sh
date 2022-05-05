#!/usr/bin/env bash

INSTALL_PATH=$HOME/.local/bin

if [ "$EUID" -eq 0 ]; then
    INSTALL_PATH=/bin
fi

if [[ ! ":$PATH:" == *":$INSTALL_PATH:"* ]]; then
    touch $HOME/.pam_environment
    mkdir -p $INSTALL_PATH
    echo "Relog and the rerun ./mgen-simulator-install.sh"

fi
    [[ ! -d "$INSTALL_PATH" ]] && mkdir -p "$INSTALL_PATH"

    chmod +x mgen-simulator.sh
    chmod +x analyze_latency_jitter_mgen.awk
    chmod +x analyze_latency_jitter_mgen_seq.awk
    chmod +x analyze_latency_jitter_mgen_seg.awk

    cp mgen-simulator.sh $INSTALL_PATH/mgen-simulator
    cp analyze_latency_jitter_mgen.awk $INSTALL_PATH/analyze_latency_jitter_mgen
    cp analyze_latency_jitter_mgen_seq.awk $INSTALL_PATH/analyze_latency_jitter_mgen_seq
    cp analyze_latency_jitter_mgen_seg.awk $INSTALL_PATH/analyze_latency_jitter_mgen_seg

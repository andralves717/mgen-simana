#!/usr/bin/env bash

if [[ ! ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
    touch $HOME/.pam_environment
    echo "PATH DEFAULT=\${PATH}:/home/@{PAM_USER}/.local/bin" >> $HOME/.pam_environment
    echo "Relog and the rerun ./mgen-simulator-install.sh"

else
    [[ ! -d "$HOME/.local/bin" ]] && mkdir -p "$HOME/.local/bin"


    chmod +x mgen-simulator.sh
    chmod +x analyze_latency_jitter_mgen.awk
    chmod +x analyze_latency_jitter_mgen_seq.awk
    chmod +x analyze_latency_jitter_mgen_seg.awk

    cp mgen-simulator.sh $HOME/.local/bin/mgen-simulator
    cp analyze_latency_jitter_mgen.awk $HOME/.local/bin/analyze_latency_jitter_mgen
    cp analyze_latency_jitter_mgen_seq.awk $HOME/.local/bin/analyze_latency_jitter_mgen_seq
    cp analyze_latency_jitter_mgen_seg.awk $HOME/.local/bin/analyze_latency_jitter_mgen_seg
fi
#! /usr/bin/gawk -f

# remove extra info not used

# convert MGEN timestamp to seconds
function mgen_ts_to_microseconds(ts) {
  split(ts, ts_parts, /:/);
  return (3600 * ts_parts[1] + 60 * ts_parts[2] + ts_parts[3])*1000000;
}

# put received packet data into variables
$2 ~ /RECV/ {
  recv_time = mgen_ts_to_microseconds($1);
  split($4, flow, />/);
  split($5, seq, />/);
  split($8, sent, />/);
  sent_time = mgen_ts_to_microseconds(sent[2]);

# SENT RECV FLOW SEQ
  printf "MGEN %d %d %d %d\n", sent_time, recv_time, flow[2], seq[2];
}

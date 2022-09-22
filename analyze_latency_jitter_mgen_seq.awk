#! /usr/bin/gawk -f

# used with -v nflows= -v pps= -v dur= -v size=
# to get number of flows, packet per second, duration and packet size. 

# based on https://github.com/fg-networking/mgen-tools flow-latency-analyzer


# convert MGEN timestamp to seconds
function mgen_ts_to_microseconds(ts) {
  split(ts, ts_parts, /:/);
  return (3600 * ts_parts[1] + 60 * ts_parts[2] + ts_parts[3])*1000000;
}

function abs(v) {return v < 0 ? -v : v}

BEGIN {
  for (i = 1; i< nflows; i++){
    first[i]=1;
  }
  # time_to_wait = 10000000;
  seq_init = pps * 10;
}

# put received packet data into variables
$2 ~ /RECV/ {
  recv_time = mgen_ts_to_microseconds($1);
  split($4, flow, />/);
  split($5, seq, />/);
  split($8, sent, />/);
  sent_time = mgen_ts_to_microseconds(sent[2]);

  if( seq[2] >= seq_init) {
    # keep package count to be independent of reordered packets
    count[flow[2]]++;


    latency = recv_time - sent_time;
  

    if (min_latency[flow[2]] == "") {
      min_latency[flow[2]] = latency;
    } else if (min_latency[flow[2]] > latency) {
      min_latency[flow[2]] = latency;
    }

    if (max_latency[flow[2]] == "") {
      max_latency[flow[2]] = latency;
    } else if (max_latency[flow[2]] < latency) {
      max_latency[flow[2]] = latency;
    }

    # keep running average latency
    if (avg_latency[flow[2]] == "") {
      avg_latency[flow[2]] = latency;
    } else {
    # new avg latency = (old avg latency * (n-1) + latency) / n
      avg_latency[flow[2]] = (avg_latency[flow[2]] * (count[flow[2]] - 1) + latency) / count[flow[2]];
    }

    if (first[flow[2]] == 0) {
      jitter = abs(latency - prev_latency[flow[2]]);
    

      if (min_jitter[flow[2]] == "") {
        min_jitter[flow[2]] = jitter;
      } else if (min_jitter[flow[2]] > jitter) {
        min_jitter[flow[2]] = jitter;
      }

      if (max_jitter[flow[2]] == "") {
        max_jitter[flow[2]] = jitter;
      } else if (max_jitter[flow[2]] < jitter) {
        max_jitter[flow[2]] = jitter;
      }

      if (avg_jitter[flow[2]] == "") {
        avg_jitter[flow[2]] = jitter;
      } else {
        avg_jitter[flow[2]] = (avg_jitter[flow[2]] * (count[flow[2]] - 2) + jitter) / (count[flow[2]]-1);
      }

    }
    if (last_flow == ""){
      last_flow = flow[2];
    } else if (last_flow < flow[2]) {
      last_flow = flow[2];
    }

    if (flows[flow[2]] == "") {
      min[flow[2]] = seq[2];
      max[flow[2]] = seq[2];
    } else {
      if (seq[2] < min[flow[2]]) {
        min[flow[2]] = seq[2];
      }
      if (seq[2] > max[flow[2]]) {
        max[flow[2]] = seq[2];
      }
    }
    flows[flow[2]]++;
    first[flow[2]] = 0;
    prev_latency[flow[2]] = latency;
  }
}

# print statistics
END {
  for (i = 1; i <= nflows; i++) {
    total_avg_latency += avg_latency[i];
    total_avg_jitter += avg_jitter[i];

    if(min_lat == ""){
	    min_lat = min_latency[i];
    } else if (min_latency[i] < min_lat){
    	min_lat = min_latency[i];
    }

    if(max_lat == ""){
	    max_lat = max_latency[i];
    } else if (max_latency[i] > max_lat){
    	max_lat = max_latency[i];
    }

    if(min_jitt == ""){
	    min_jitt = min_jitter[i];
    } else if (min_jitter[i] < min_jitt){
    	min_jitt = min_jitter[i];
    }

    if(max_jitt == ""){
	    max_jitt = max_jitter[i];
    } else if (max_jitter[i] > max_jitt){
    	max_jitt = max_jitter[i];
    }
  }

  total_avg_latency = total_avg_latency/nflows;
  total_avg_jitter  = total_avg_jitter/nflows; 
  if (nflows != "" && pps != "" && dur != ""){
    total = (nflows * (pps*(dur-10)+1) );
  } else {
    total_en = 1;
  }
  for (i in flows) {
    received += flows[i];
    if (total_en == 1){
      total += max[i]-min[i]+1;
    }
  }

  if (nflows != "" && pps != "" && size != "" && dur != ""){
    printf "%s, %s, %d, %d, %d, %d, %10.2f, %10.2f, %10.2f, %10.2f, %10.2f, %10.2f, %2.2f, %d, %d\n", src, dest, nflows, pps, size, dur, total_avg_latency, min_lat, max_lat, total_avg_jitter, min_jitt, max_jitt, (1-(received/total)), received, total;
  } else {
    printf "Latency:\nAvg: %11.9f, Min: %11.9f, Max: %11.9f\n", total_avg_latency, min_lat, max_lat;
    printf "Jitter:\nAvg: %11.9f, Min: %11.9f, Max: %11.9f\n", total_avg_jitter, min_jitt, max_jitt;
    printf "Packets received: %d, Packets expected: %d, lost_packets: %d, packet_loss: %d %\n", received, total, total-received, (total-received)*100/total;
  }
}


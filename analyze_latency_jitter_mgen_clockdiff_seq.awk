#! /usr/bin/gawk -f

# used with -v nflows= -v pps= -v dur= -v size=
# to get number of flows, packet per second, duration and packet size. 

# based on https://github.com/fg-networking/mgen-tools flow-latency-analyzer

function abs(v) {return v < 0 ? -v : v}

BEGIN {
  first = 1;
  # time_to_wait = 10000000;
  seq_init = pps * 10;
}

# put received packet data into variables
$1 ~ /MGEN/ {

  if( $5 >= seq_init) {

    # maybe split this into a function with problem handling
    if (first == 0) {
      prev_latency[$4] = latency;
    } 

    # keep package count to be independent of reordered packets
    count[$4]++;


    latency = $3 - $2;
  

    if (min_latency[$4] == "") {
      min_latency[$4] = latency;
    } else if (min_latency[$4] > latency) {
      min_latency[$4] = latency;
    }

    if (max_latency[$4] == "") {
      max_latency[$4] = latency;
    } else if (max_latency[$4] < latency) {
      max_latency[$4] = latency;
    }

    # keep running average latency
    if (avg_latency[$4] == "") {
      avg_latency[$4] = latency;
    } else {
    # new avg latency = (old avg latency * (n-1) + latency) / n
      avg_latency[$4] = (avg_latency[$4] * (count[$4] - 1) + latency) / count[$4];
    }

    if (first == 0) {
      jitter = abs(latency - prev_latency[$4]);
    

      if (min_jitter[$4] == "") {
        min_jitter[$4] = jitter;
      } else if (min_jitter[$4] > jitter) {
        min_jitter[$4] = jitter;
      }

      if (max_jitter[$4] == "") {
        max_jitter[$4] = jitter;
      } else if (max_jitter[$4] < jitter) {
        max_jitter[$4] = jitter;
      }

      if (avg_jitter[$4] == "") {
        avg_jitter[$4] = jitter;
      } else {
        avg_jitter[$4] = (avg_jitter[$4] * (count[$4] - 2) + jitter) / (count[$4]-1);
      }

    }
    if (last_flow == ""){
      last_flow = $4;
    } else if (last_flow < $4) {
      last_flow = $4;
    }

    if (flows[$4] == "") {
      min[$4] = $5;
      max[$4] = $5;
    } else {
      if ($5 < min[$4]) {
        min[$4] = $5;
      }
      if ($5 > max[$4]) {
        max[$4] = $5;
      }
    }
    flows[$4]++;
    first = 0;
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


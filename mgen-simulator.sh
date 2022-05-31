#!/usr/bin/env bash

CurVer='version 0.6, 2022-05-18'

NUM_FLOWS=50
sec=30
pack_per_second=10
bytes_per_packet=256
destination=127.0.0.1
source=127.0.0.1
port_src=5000
port_dst=5000
server=true
client=true
keep_drc=false

ulimit -n 65536

Usage() {
	while read; do
		printf '%s\n' "$REPLY"
	done <<-EOF
		Usage: ${0##*/} [[OPTS] ...]
		  -h, --help                    - Display this help information.
		  -v, --version                 - Output the version datestamp.
		  --type <s|c|b>				- Select if is server, client or both.
		  --keep-log					- Save listen mgen files in client.
		  --flows <Number of Flows>     - Set the number of flows.
		  --duration <time in sec>      - Set the duration of the program.
		  --pps <Packets per second>    - Set the number of packets per second.
		  --bytes <Number of bytes>     - Set the number of bytes per packet.
		  --source <IP address>			- Set the source IP of the packet.
		  --destination <IP address>	- Set the destination IP of the packet.
		  --port_src <port>				- Set the source port.
		  --port_dst <port>				- Set the destination port.
		  --outfile <Filename>			- Set the output file name.
	EOF
}

Err() {
	printf 'Err: %s\n' "$2" 1>&2
	(( $1 > 0 )) && exit "$1"
}


while [[ -n $1 ]]; do
	case $1 in
		--help|-h|-\?)
			Usage; exit 0 ;;
		--version|-v)
			printf "%s\n" "$CurVer"
			exit 0 ;;

		--type)
			shift
			case $1 in
				c)
					client=true
					server=false;;
				s)
					client=false
					server=true;;
				b)
					client=true
					server=true;;
				*)
					Err 1 'Incorrect type of server. Must be Client, Server or Both.';;
			esac ;;

		--keep-log)
			keep_drc=true ;;

		--flows)
			shift
			case $1 in
				''|*[!0-9]*)
					Err 1 'Incorrect number of flows type provided, must be an integer.' ;;
				*)
                    NUM_FLOWS=$1 ;;
			esac ;;
        --duration)
			shift
			case $1 in
				''|*[!0-9]*)
					Err 1 'Incorrect duration type provided, must be an integer.' ;;
				*)
                    sec=$1 ;;
			esac ;;
		--pps)
			shift
			case $1 in
				''|*[!0-9]*)
					Err 1 'Incorrect match type provided, must be an integer.' ;;
				*)
                    pack_per_second=$1 ;;
			esac ;;
        --bytes)
			shift
			case $1 in
				''|*[!0-9]*)
					Err 1 'Incorrect match type provided, must be an integer.' ;;
				*)
					bytes_per_packet=$1 ;;
			esac ;;
		--outfile)
			shift
			outfile=$1;;
		--source)
			shift
			source=$1;;
		--destination)
			shift
			destination=$1;;
		--port_src)
			shift
			case $1 in
				''|*[!0-9]*)
					Err 1 'Incorrect match type provided, must be an integer.' ;;
				*)
					port_src=$1 ;;
			esac ;;
		--port_dst)
			shift
			case $1 in
				''|*[!0-9]*)
					Err 1 'Incorrect match type provided, must be an integer.' ;;
				*)
					port_dst=$1 ;;
			esac ;;
		-*)
			Err 1 'Incorrect argument(s) specified.' ;;
		*)
			break ;;
	esac
	shift
done

if [[ "$client" = true ]]; then

	if [[ -z $outfile ]]; then
		outfile="./out_f${NUM_FLOWS}_pps${pack_per_second}_b${bytes_per_packet}_s${sec}.drc"
	fi

	if [[ $outfile == */* ]]; then
		if ! cd "${outfile%/*}" 2> /dev/null ; then
			Err 1 "Failed to change directory into '${outfile%/*}'."
		fi
	fi

	echo -e "0.0 LISTEN UDP ${port_dst}\n$((sec+60)).0 IGNORE UDP ${port_dst}\n" > script_listen_t.mgn

	# diffclock --source "$source" --duration "$((sec+60))" &> /dev/null &

	clockdiff_client "$source" >> /data/clockdiff.csv &

	if [[ "$server" = true ]]; then
		mgen input script_listen_t.mgn output "$outfile" &> /dev/null &
	else 
		mgen input script_listen_t.mgn output "$outfile" &> /dev/null
	fi

	
	# mgen input script_listen_t.mgn

fi

if [[ "$server" = true ]]; then

	clockdiff_server &

	for i in $(seq "${NUM_FLOWS}")
	do
		echo -e "30.0 ON $i UDP SRC ${port_src} DST $destination/${port_dst} PERIODIC [$pack_per_second $bytes_per_packet]\n$((sec+30)).0 OFF $i" >> script_send_t.mgn
	done

	mgen input script_send_t.mgn &> /dev/null

fi

if [[ "$client" = true ]]; then

	rm script_listen_t.mgn

	analyze_latency_jitter_mgen_seq -v nflows="$NUM_FLOWS" -v pps="$pack_per_second" -v dur="$sec" -v size="$bytes_per_packet" -v src="$source" -v dest="$destination" "$outfile"

	if [[ "$keep_drc" = false ]]; then
		rm "$outfile"
	fi
fi

if [[ "$server" = true ]]; then
	rm script_send_t.mgn
fi
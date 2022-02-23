#!/usr/bin/env bash

CurVer='version 0.5, 2022-02-23'

NUM_FLOWS=50
sec=30
pack_per_second=10
bytes_per_packet=256
destination=127.0.0.1
port=5000
server= true
client= true
keep_drc= false

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
		  --destination <IP address>	- Set the destination of the packet.
		  --port <port>					- Set the port.
		  --outfile <Filename>			- Set the output file name.
	EOF
}

Err() {
	printf 'Err: %s\n' "$2" 1>&2
	(( $1 > 0 )) && exit $1
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
					client= true
					server= false
				s)
					client= false
					server= true
				b)
					client= true
					server= true
				*)
					Err 1 'Incorrect type of server. Must be Client, Server or Both.'
			esac ;;

		--keep-log)
			keep_drc = true ;;

		--flows)
			shift
			case $1 in
				''|*[!0-9]*)
                # ! [[ $1 =~ ^[[:digit:]]+$ ]];
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
		--destination)
			shift
			destination=$1;;
		--port)
			shift
			case $1 in
				''|*[!0-9]*)
					Err 1 'Incorrect match type provided, must be an integer.' ;;
				*)
					port=$1 ;;
			esac ;;
		-*)
			Err 1 'Incorrect argument(s) specified.' ;;
		*)
			break ;;
	esac
	shift
done

if [[ client ]]; then

	if [[ -z $outfile]]; then
		outfile="./out_f${NUM_FLOWS}_pps${pack_per_second}_b${bytes_per_packet}_s${sec}.drc"
	fi

	if [[ $outfile == */* ]]; then
		if ! cd "${outfile%/*}" 2> /dev/null ; then
			Err 1 "Failed to change directory into '${outfile%/*}'."
		fi
	fi

	echo -e "0.0 LISTEN UDP $port\n$(($sec+100)).0 IGNORE UDP $port\n" > script_listen_t.mgn

	mgen input script_listen_t.mgn output ${outfile} &> /dev/null &

fi

sleep 10

if [[ server ]]; then

	for i in $(seq ${NUM_FLOWS})
	do
		echo -e "60.0 ON $i UDP SRC 5001 DST $destination/$port PERIODIC [$pack_per_second $bytes_per_packet]\n$(($sec+60)).0 OFF $i" >> script_send_t.mgn
	done

	mgen input script_send_t.mgn &> /dev/null

fi

sleep 40

rm script_send_t.mgn script_listen_t.mgn

if [[ client ]]; then

	analyze_latency_jitter_mgen_seq -v nflows=$NUM_FLOWS -v pps=$pack_per_second -v dur=$sec -v size=$bytes_per_packet $outfile

	rm $outfile

fi
#!/usr/bin/env bash

CurVer='version 0.1, 2022-01-08'

NUM_FLOWS=50
sec=30
pack_per_second=10
bytes_per_packet=256

Usage() {
	while read; do
		printf '%s\n' "$REPLY"
	done <<-EOF
		Usage: ${0##*/} [[OPTS] [OPTS_ARGS] ...]
		  -h, --help                    - Display this help information.
		  -v, --version                 - Output the version datestamp.
		  --flows <Number of Flows>     - Set the number of flows.
		  --duration <time in sec>      - Set the duration of the program.
		  --pps <Packets per second>    - Set the number of packets per second.
		  --bytes <Number of bytes>     - Set the number of bytes per packet.
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
		-*)
			Err 1 'Incorrect argument(s) specified.' ;;
		*)
			break ;;
	esac
	shift
done


echo -e "0.0 LISTEN UDP 5000\n$(($sec+10)).0 IGNORE UDP 5000\n" > script_listen_t.mgn

mgen input script_listen_t.mgn output out_f${NUM_FLOWS}_pps${pack_per_second}_b${bytes_per_packet}_s${sec}.drc &> /dev/null &

sleep 5

for i in $(seq ${NUM_FLOWS})
do
    echo -e "0.0 ON $i UDP SRC 5001 DST 127.0.0.1/5000 PERIODIC [$pack_per_second $bytes_per_packet]\n$sec.0 OFF $i" >> script_send_t.mgn
done



mgen input script_send_t.mgn &> /dev/null

sleep 8

rm script_send_t.mgn script_listen_t.mgn

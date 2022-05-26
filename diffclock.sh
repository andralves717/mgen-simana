#!/usr/bin/env bash

CurVer='version 0.1, 2022-05-18'

sec=30
outfile="/data/clockdiff.csv"
source=127.0.0.1

Usage() {
	while read; do
		printf '%s\n' "$REPLY"
	done <<-EOF
		Usage: ${0##*/} [[OPTS] ...]
		  -h, --help                    - Display this help information.
		  -v, --version                 - Output the version datestamp.
		  --source <IP address>			- Set the source IP of the packet.
		  --duration <time in sec>      - Set the duration of the program.
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

		--source)
			shift
			source=$1;;

        --duration)
			shift
			case $1 in
				''|*[!0-9]*)
					Err 1 'Incorrect duration type provided, must be an integer.' ;;
				*)
                    sec=$1 ;;
			esac ;;
		--outfile)
			shift
			outfile=$1;;
		-*)
			Err 1 'Incorrect argument(s) specified.' ;;
		*)
			break ;;
	esac
	shift
done

while (( sec > 0 ))
do
    nice -n -19 clockdiff -o "$source" &>> "$outfile" &
    ((sec -= 1))
    sleep 1
done

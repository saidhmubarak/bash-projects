#!/bin/bash
short=d:,e:,o:,h
long=dork:,engine:,out-put:,help
args=$@
options=$(getopt -a -n error -o $short -l $long -- "$@")
eval set -- $options
usage() {
	cat <<- _EOF_
	Usage $(basename $0)
	-d, --dork	specify a dork
	-e, --engine	specify a search engine (optional)
	-o, --out-put	specify a file name for save results(optional)
	-h, --help	show this help menu and exit
	_EOF_
	echo "eg: ./gdork.sh -d <dork> -e google -o file.txt"
	exit
}
while :
do
	case $1 in
		-d | --dork)
		dork=$2
		shift 2
		;;
		-e | --engine)
		engine=$2
		shift 2
		;;
		-o | --out-put)
		file=$2
		shift 2
		;;
		-h | --help)
		usage
		;;
		--)	
		shift
		break
		;;
		*)
		usage
	esac
done


google() {
	g_results=$(mktemp XXXXXX.txt)
	lynx -dump "https://www.google.com/search?q=$dork&num=200" > "$g_results"
}

regex() {
	f_results=$(mktemp XXXXXX.txt)	
	reg='http.?://[w]{3}\.[[:alnum:]].[[:alpha:]]{2,3}'
	while read line; do
		echo "$line" | cut -d ' ' -f2 | cut -d= -f2- >> "$f_results"
	done < "$g_results"
}

form_out(){
	while read line; do
		if [[ $line =~ $reg ]]; then
			echo "[+] $line" | grep -v "google.com" | grep -v "youtube.com" | tee $file
		sleep 0.5
		fi
	done < "$f_results"
}

output_file() {
	if [[ -e $file ]]; then
		read -p "File already exist, do you want to overwrite (y/n) " respns
		while true; do
			case $respns in
				y | Y)
				touch $file
				break
				;;
				n | N)
				echo "bye !!!"
				exit 
				;;
				*)
				continue
			esac
		done
	else
		touch $file
	fi
}
if [[ -z $args || $args == [a-zA-Z0-9] ]]; then
	usage
else
	if [[ -n $file ]]; then
		output_file
		google
		regex
		form_out
	else
		google
		regex
		form_out
	fi
fi
rm "$g_results"
rm "$f_results"


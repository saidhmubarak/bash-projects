#!/bin/bash
short=d:,e:,o:,h
long=dork:,engine:,out-put:,help
args=$@
options=$(getopt -a -n error -o $short -l $long -- "$@")
eval set -- $options

#check for current user
user_check() {
	if [[ ($(echo $UID) = 0) ]]; then
		echo "you are root, so going on..."
	else
		echo "Please execute as root user"
		exit
	fi
}

#check for internet connection
check_internet() {
	if [[ $(ping -c 1 google.com 2> /dev/null) ]]; then
		echo "internet is up and running, good to go..."
	else
		echo "internet is down, shuttingdown now!!!"
		exit
	fi
}

#respond to the keybord int signal
exit_sig() {
	echo "ctrl+c detected, cleaning up"
	rm -rf $g_results $f_results
	echo "shutting down!!!"
	exit
}

trap exit_sig SIGINT

#show usage and exit
usage() {
	cat <<- _EOF_
	Usage $(basename $0)
	-d, --dork	specify a dork
	-e, --engine	specify a search engine (optional)
	-o, --out-put	specify a file name for save results(optional)
	-h, --help	show this help menu and exit
	_EOF_
	echo "eg: sudo ./gdork.sh -d <dork> -e google -o file.txt"
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

#receve data from google and write it to a file
google() {
	g_results=$(mktemp XXXXXX.txt)
	lynx -dump "https://www.google.com/search?q=$dork&num=200" > "$g_results"
}

#regular expression to extract data
regex() {
	f_results=$(mktemp XXXXXX.txt)	
	reg='http.?://[w]{3}\.[[:alnum:]].[[:alpha:]]{2,3}'
	while read line; do
		echo "$line" | cut -d ' ' -f2 | cut -d= -f2- >> "$f_results"
	done < "$g_results"
}

#print out put to terminal
form_out(){
	while read line; do
		if [[ $line =~ $reg ]]; then
			echo "[+] $line" | grep -v "google.com" | grep -v "youtube.com" | tee $file
		sleep 0.5
		fi
	done < "$f_results"
}

#check for existing file
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
		check_internet
		output_file
		google
		regex
		form_out
	else
		check_internet
		google
		regex
		form_out
	fi
fi
rm "$g_results"
rm "$f_results"


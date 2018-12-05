#!/bin/bash
echo "--------------------------------"
echo "WiFi Access Point crating script"
echo "--------------------------------"

echo "Your syetem need internet"
echo "Is internet connection OK: y/n"

while true:
do
	read net
		if [ "$net" == "n" ];
		then
			echo "No internet so installtion will be cancled"
			break
		fi
done

echo "Installing hostapd and dnsmansq"
	sudo apt-get install hostapd dnsmasq


echo "Creating hostapd config file"
	sudo cp hostapd.conf /etc/hostapd/hostapd.conf


echo "Creating dnsmansq config file"
	sudo cp dnsmasq.conf /etc/dnsmasq.conf
	
	
echo "Creating intetface"
	sudo echo "allow-hotplug wlan0" >> /etc/network/interfaces
	sudo echo "iface  wlan0 inet manual"  >> /etc/network/interfaces

echo "Configuring dhcpcd"
	sudo echo "interface wlan0" >> /etc/dhcpcd.conf
	sudo echo "static ip_address=192.168.0.10/24" >> /etc/dhcpcd.conf
	
echo "Creating path to hostapd config"
	sudo echo "DAEMON_CONF=\"/etc/hostapd/hostapd.conf\"" >> /etc/default/hostapd

echo "kernel-headers and other dependencies"
	sudo apt-get update
	sudo apt-get dist-upgrade
	sudo apt-get install raspberrypi-kernel-headers build-essential
	sudo apt-get install bc
	sudo apt-get update

echo "Installing rtl8821AU chipset driver"
	cd rtl8821AU
	sudo make clean
	sudo make all
	sudo make install


cd ..

echo "Writing udev rules....."
	echo 'SUBSYSTEM=="net", ACTION=="add", DRIVERS=="rtl8812au", ATTR{type}=="1", NAME="wlan0"' >> /lib/udev/rules.d/70-persistent-network.rules
	sudo modprob rtl8821au


echo "Allow hostapd in ufw rules"	
	sudo ufw allow to any port 53
	sudo ufw allow to any port 67 proto udp
	sudo ufw allow to any port 68 proto udp

echo "Creating iptabele rules"
	sudo iptables -t nat -A POSTROUTING -o ppp0 -j MASQUERADE
	sudo iptables -A FORWARD -i ppp0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
	sudo iptables -A FORWARD -i wlan0 -o ppp0 -j ACCEPT
	sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"



echo "WiFi AP creation done"
echo "Now connect your device and enjoy browing...."
echo "***********    	End		***************"
echo "Rebooting Now"
sudo reboot




#!/bin/bash
echo "--------------------------------"
echo "WiFi Access Point crating script"
echo "--------------------------------"

echo "Your syetem need internet"
echo "Is internet connection OK"


echo "Installing hostapd and dnsmansq"
	sudo apt-get install hostapd dnsmasq


echo "Creating hostapd config file"
	sudo cp hostapd.conf /etc/hostapd/hostapd.conf

echo "Creating path to hostapd config"
	#sudo echo "DAEMON_CONF=\"/etc/hostapd/hostapd.conf\"" >> /etc/default/hostapd
	sudo sed -i "/DAEMON_CONF/c\ DAEMON_CONF=\"/etc/hostapd/hostapd.conf\""  /etc/default/hostapd
	
echo "Creating dnsmansq config file"
	if [ ! -f /etc/dnsmasq.conf.orig ]; then
		sudo mv dnsmansq.conf /etc/dnsmasq.conf.orig
	fi
	sudo cp dnsmansq.conf /etc/dnsmasq.conf
	
echo "forwarding  ipv4"	
	sudo sed -i "/net.ipv4.ip_forward/c\net.ipv4.ip_forward=1"  /etc/sysctl.conf
	
echo "Creating intetface"
	sudo echo "" >> /etc/network/interfaces
	sudo echo "allow-hotplug wlan0" >> /etc/network/interfaces
	sudo echo "iface  wlan0 inet manual"  >> /etc/network/interfaces

echo "Configuring dhcpcd"
	sudo echo "" >> /etc/dhcpcd.conf
	sudo echo "interface wlan0" >> /etc/dhcpcd.conf
	sudo echo "static ip_address=192.168.0.10/24" >> /etc/dhcpcd.conf
	sudo echo "nohook wpa_supplicant" >> /etc/dhcpcd.conf
	


echo "kernel-headers and other dependencies"
	sudo apt-get update
	sudo apt-get dist-upgrade
	sudo apt-get install raspberrypi-kernel-headers build-essential
	sudo apt-get install bc
	sudo apt-get update

echo "Installing rtl8812AU chipset driver"
	cd rtl8812AU
	sudo make clean
	sudo make all
	sudo make install


cd ..

echo "Writing udev rules....."
	#echo 'SUBSYSTEM=="net", ACTION=="add", DRIVERS=="rtl8812au", ATTR{type}=="1", NAME="wlan0"' >> /lib/udev/rules.d/70-persistent-network.rules
	sudo sed -i "/rtl8812au/c\ \"SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"rtl8812au\", ATTR{type}==\"1\", NAME=\"wlan0\""  /lib/udev/rules.d/70-persistent-network.rules
	if [ $? == 0 ];
	then
		echo "Dev Rule exist"
	else
  		sudo echo 'SUBSYSTEM=="net", ACTION=="add", DRIVERS=="rtl8812au", ATTR{type}=="1", NAME="wlan0"' >> /lib/udev/rules.d/70-persistent-network.rules
	fi
	sudo modprobe rtl8812au


echo "Allow hostapd in ufw rules"	
	sudo ufw allow to any port 53
        sudo ufw allow to any port 67 proto udp
        sudo ufw allow to any port 68 proto udp

        sudo ufw allow out on wlan0 to 192.168.0.0/24
        sudo ufw allow out from 192.168.0.10/24
        sudo ufw allow  from 192.168.0.10/24

        sudo ufw allow 67
        sudo ufw allow 68
        sudo ufw allow 53

        sudo ufw allow out 67
        sudo ufw allow out 68
        sudo ufw allow out 53

echo "Creating iptabele rules"
	sudo iptables -t nat -A POSTROUTING -o ppp0 -j MASQUERADE
	sudo iptables -A FORWARD -i ppp0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
	sudo iptables -A FORWARD -i wlan0 -o ppp0 -j ACCEPT
	sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
	sudo iptables-restore < /etc/iptables.ipv4.nat



echo "WiFi AP creation done"
echo "Now connect your device and enjoy browing...."
echo "***********    	End		***************"
echo "Rebooting Now"
sudo reboot




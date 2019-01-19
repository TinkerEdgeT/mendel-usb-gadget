#!/bin/bash

# Remove the aiy ethernet connection
nmcli connection delete usb0 || true

# Setup the USB Gadget device
CONFIGFS_PATH=/sys/kernel/config
USB_GADGET_PATH=$CONFIGFS_PATH/usb_gadget
AIY_GADGET_PATH=$USB_GADGET_PATH/g1
mkdir -p $AIY_GADGET_PATH

echo 0x0106 > $AIY_GADGET_PATH/idProduct
echo 0x04e8 > $AIY_GADGET_PATH/idVendor
mkdir -p $AIY_GADGET_PATH/strings/0x409
hostname > $AIY_GADGET_PATH/strings/0x409/serialnumber
echo Google,LLC > $AIY_GADGET_PATH/strings/0x409/manufacturer
echo "Mendel" > $AIY_GADGET_PATH/strings/0x409/product

mkdir -p $AIY_GADGET_PATH/configs/c.1
echo 500 > $AIY_GADGET_PATH/configs/c.1/MaxPower
mkdir -p $AIY_GADGET_PATH/configs/c.1/strings/0x409
echo "Conf 1" > $AIY_GADGET_PATH/configs/c.1/strings/0x409/configuration

mkdir $AIY_GADGET_PATH/functions/acm.0
ln -s  $AIY_GADGET_PATH/functions/acm.0 $AIY_GADGET_PATH/configs/c.1

mkdir $AIY_GADGET_PATH/functions/ecm.0
ln -s $AIY_GADGET_PATH/functions/ecm.0 $AIY_GADGET_PATH/configs/c.1
echo "02:22:78:0d:f6:df" > $AIY_GADGET_PATH/functions/ecm.0/dev_addr

UDC=$(echo -n $(ls /sys/class/udc/|head -c -1 -n 1))
echo $UDC

sleep 1
echo $UDC > $AIY_GADGET_PATH/UDC

# Setup the ttyGS0 terminal
systemctl enable usb-gadget-getty@ttyGS0.service
systemctl start usb-gadget-getty@ttyGS0.service

sleep 3

# Set a static ip for the gadget ethernet
$(nmcli con show | grep -q usb0)
aiy_conn_exist=$?
if [[ "$aiy_conn_exist" -eq 0 ]]; then
  echo "usb0 connection already exists"
else
  nmcli con add con-name usb0 ifname usb0 type ethernet ip4 192.168.100.2/24
fi

nmcli con up id usb0

# Setup the dhcp server and ssh

cat << EOF > /etc/dnsmasq.conf
# Configuration file for dnsmasq.
port=0
interface=usb0
domain=local
dhcp-range=192.168.100.50,192.168.100.99,255.255.255.0,12h
dhcp-lease-max=150
log-dhcp
EOF

systemctl restart dnsmasq
systemctl restart sshd

#!/bin/bash

$(nmcli con show | grep -q usb0)
aiy_conn_exist=$?
if [[ "$aiy_conn_exist" -eq 0 ]]; then
  nmcli con delete usb0
else
  echo "aiy-usb0 does not exist"
fi

systemctl disable usb-gadget-getty@ttyGS0.service
systemctl stop usb-gadget-getty@ttyGS0.service

CONFIGFS_PATH=/sys/kernel/config
USB_GADGET_PATH=$CONFIGFS_PATH/usb_gadget
AIY_GADGET_PATH=$USB_GADGET_PATH/g1

echo "" > $AIY_GADGET_PATH/UDC
rm -rf $AIY_GADGET_PATH/configs/c.1/acm.0
rm -rf $AIY_GADGET_PATH/configs/c.1/ecm.0

rmdir $AIY_GADGET_PATH/configs/c.1/strings/0x409
rmdir $AIY_GADGET_PATH/configs/c.1
rmdir $AIY_GADGET_PATH/functions/acm.0
rmdir $AIY_GADGET_PATH/functions/ecm.0

rmdir $AIY_GADGET_PATH/strings/0x409
rmdir $AIY_GADGET_PATH

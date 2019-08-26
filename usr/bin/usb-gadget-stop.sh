#!/bin/bash

delete_connection() {
	$(nmcli con show | grep -q "gadget${1}")
	mendel_conn_exist=$?
	if [[ "$mendel_conn_exist" -eq 0 ]]; then
	  nmcli con delete "gadget${1}"
	else
	  echo "gadget${1} connection does not exist"
	fi
}
delete_connection 0
delete_connection 1

CONFIGFS_PATH=/sys/kernel/config
USB_GADGET_PATH=$CONFIGFS_PATH/usb_gadget
MENDEL_GADGET_PATH=$USB_GADGET_PATH/g1

echo "" > "${MENDEL_GADGET_PATH}/UDC"

MENDEL_CONFIG1_PATH=${MENDEL_GADGET_PATH}/configs/c.1
rmdir "${MENDEL_CONFIG1_PATH}/strings/0x409"
rm -f "${MENDEL_CONFIG1_PATH}/acm.0"
rm -f "${MENDEL_CONFIG1_PATH}/ecm.0"
rmdir "${MENDEL_CONFIG1_PATH}"

MENDEL_CONFIG2_PATH=${MENDEL_GADGET_PATH}/configs/c.2
rmdir "${MENDEL_CONFIG2_PATH}/strings/0x409"
rm -f "${MENDEL_CONFIG2_PATH}/rndis.0"
rm -f "${MENDEL_CONFIG2_PATH}/acm.0"
rm -f "${MENDEL_GADGET_PATH}/os_desc/c.2"
rmdir "${MENDEL_CONFIG2_PATH}"

FUNCTION_RNDIS0="${MENDEL_GADGET_PATH}/functions/rndis.0"
rmdir "${FUNCTION_RNDIS0}"
FUNCTION_ECM0="${MENDEL_GADGET_PATH}/functions/ecm.0"
rmdir "${FUNCTION_ECM0}"
FUNCTION_ACM0="${MENDEL_GADGET_PATH}/functions/acm.0"
rmdir "${FUNCTION_ACM0}"


rmdir "${MENDEL_GADGET_PATH}/strings/0x409"
rmdir "${MENDEL_GADGET_PATH}"

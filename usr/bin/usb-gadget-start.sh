#!/bin/bash

KERNEL_VERSION="$(uname -r)"
if [[ "${KERNEL_VERSION}" =~ imx ]]; then
  PRODUCT_ID="0x9303"
elif [[ "${KERNEL_VERSION}" =~ mtk ]]; then
  PRODUCT_ID="0x9304"
else
  echo "Unknown device, not setting up gadget."
  exit 1
fi

PRODUCT_STRING="Mendel"
MANUFACTURER_STRING="Google,LLC"
VENDOR_ID="0x18d1"
USB_VER="0x0200"
DEV_CLASS="2"
SERIAL_NUMBER=$(hostname)
ECM_MAC_ADDR="02:22:78:0d:f6:df"
RNDIS_DEV_MAC_ADDR="02:22:78:0d:f6:de"
RNDIS_HOST_MAC_ADDR="02:22:78:0d:f6:dd"

USB_VER="0x0200" # USB 2.0
DEV_CLASS="2"
ATTR="0x80" # Bus Powered
MAX_POWER="500"
CFG1_NAME="RNDIS"
CFG2_NAME="CDC"

MS_VENDOR_CODE="0xcd" # Microsoft
MS_QW_SIGN="MSFT100" # Microsoft
MS_COMPAT_ID="RNDIS"
MS_SUBCOMPAT_ID="5162001"

# Remove the mendel ethernet connection
remove_mendel_connection() {
	nmcli connection delete "gadget${1}" || true
}
remove_mendel_connection 0
remove_mendel_connection 1

# Setup the USB Gadget device
CONFIGFS_PATH=/sys/kernel/config
USB_GADGET_PATH=$CONFIGFS_PATH/usb_gadget
MENDEL_GADGET_PATH=$USB_GADGET_PATH/g1
mkdir -p ${MENDEL_GADGET_PATH}

echo "${USB_VER}" > ${MENDEL_GADGET_PATH}/bcdUSB
echo "${DEV_CLASS}" > ${MENDEL_GADGET_PATH}/bDeviceClass
echo "${PRODUCT_ID}" > ${MENDEL_GADGET_PATH}/idProduct
echo "${VENDOR_ID}" > ${MENDEL_GADGET_PATH}/idVendor
mkdir -p ${MENDEL_GADGET_PATH}/strings/0x409
echo "${SERIAL_NUMBER}" > ${MENDEL_GADGET_PATH}/strings/0x409/serialnumber
echo "${MANUFACTURER_STRING}" > ${MENDEL_GADGET_PATH}/strings/0x409/manufacturer
echo "${PRODUCT_STRING}" > ${MENDEL_GADGET_PATH}/strings/0x409/product

# Create Config 1 for CDC
MENDEL_CONFIG1_PATH="${MENDEL_GADGET_PATH}/configs/c.1"
mkdir -p "${MENDEL_CONFIG1_PATH}"
echo "${ATTR}" > "${MENDEL_CONFIG1_PATH}/bmAttributes"
echo "${MAX_POWER}" > ${MENDEL_CONFIG1_PATH}/MaxPower
mkdir -p ${MENDEL_CONFIG1_PATH}/strings/0x409
echo "${CFG1_NAME}" > ${MENDEL_CONFIG1_PATH}/strings/0x409/configuration

# Create Config 2 for RNDIS
MENDEL_CONFIG2_PATH="${MENDEL_GADGET_PATH}/configs/c.2"
mkdir -p "${MENDEL_CONFIG2_PATH}"
echo "${ATTR}" > "${MENDEL_CONFIG2_PATH}/bmAttributes"
echo "${MAX_POWER}" > ${MENDEL_CONFIG2_PATH}/MaxPower
mkdir -p ${MENDEL_CONFIG2_PATH}/strings/0x409
echo "${CFG2_NAME}" > ${MENDEL_CONFIG2_PATH}/strings/0x409/configuration

# Windows Specific Configuration
echo "1" > "${MENDEL_GADGET_PATH}/os_desc/use"
echo "${MS_VENDOR_CODE}" > "${MENDEL_GADGET_PATH}/os_desc/b_vendor_code"
echo "${MS_QW_SIGN}" > "${MENDEL_GADGET_PATH}/os_desc/qw_sign"

# Create RNDIS Function
FUNCTION_RNDIS0="${MENDEL_GADGET_PATH}/functions/rndis.0"
mkdir "${FUNCTION_RNDIS0}"
echo "${RNDIS_DEV_MAC_ADDR}" > "${FUNCTION_RNDIS0}/dev_addr"
echo "${RNDIS_HOST_MAC_ADDR}" > "${FUNCTION_RNDIS0}/host_addr"
echo "${MS_COMPAT_ID}" > "${FUNCTION_RNDIS0}/os_desc/interface.rndis/compatible_id"
echo "${MS_SUBCOMPAT_ID}" > "${FUNCTION_RNDIS0}/os_desc/interface.rndis/sub_compatible_id"
echo "RNDIS" > "${FUNCTION_RNDIS0}/os_desc/interface.rndis/compatible_id"

FUNCTION_ACM0="${MENDEL_GADGET_PATH}/functions/acm.0"
mkdir "${FUNCTION_ACM0}"

# Create the ECM0 Function
FUNCTION_ECM0="${MENDEL_GADGET_PATH}/functions/ecm.0"
mkdir "${FUNCTION_ECM0}"
echo "${ECM_MAC_ADDR}" > "${FUNCTION_ECM0}/dev_addr"
find ${FUNCTION_ECM0}


ln -s "${FUNCTION_RNDIS0}" "${MENDEL_CONFIG2_PATH}"
ln -s "${FUNCTION_ACM0}" "${MENDEL_CONFIG1_PATH}"
ln -s "${FUNCTION_ACM0}" "${MENDEL_CONFIG2_PATH}"
ln -s "${FUNCTION_ECM0}" "${MENDEL_CONFIG1_PATH}"
ln -s "${MENDEL_CONFIG2_PATH}" "${MENDEL_GADGET_PATH}/os_desc"

UDC=$(echo -n $(ls /sys/class/udc/|head -c -1 -n 1))
echo $UDC
sleep 1
echo $UDC > "${MENDEL_GADGET_PATH}/UDC"

# Set a static ip for the gadget ethernet
configure_network() {
	GADGET_CON_NAME="gadget${1}"
	INTERFACE_NAME="usb${1}"
	$(nmcli con show | grep -q "${GADGET_CON_NAME}")
	mendel_conn_exist=$?
	if [[ "$mendel_conn_exist" -eq 0 ]]; then
	  echo "${GADGET_CON_NAME} connection already exists"
	else
	  nmcli con add con-name "${GADGET_CON_NAME}" ifname "${INTERFACE_NAME}" type ethernet ip4 "192.168.10${1}.2/24"
	fi
	nmcli con up id "${GADGET_CON_NAME}"
}

configure_network 0
configure_network 1

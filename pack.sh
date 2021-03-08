#!/bin/bash

echo "========================================================================"
echo "please enter the target block device name"
echo "    e.g. /dev/sdb2"
read DEVNAME

echo "========================================================================"
echo "preparing before mounting..."
rm -rf mnt
mkdir mnt
mount $DEVNAME mnt
rm -rf mnt/*
fspath=mnt

echo "========================================================================"
echo "uncompressing the ubuntu base..."
tar -xf ubuntu-base-16.04.6-base-armhf.tar.gz -C mnt

echo "========================================================================"
echo "preparing the tty..."
cat>$fspath/etc/init/ttyS0.conf<<EOF
start on stopped rc or RUNLEVEL=[12345]
stop on RUNLEVEL [!12345]
respawn
exec /sbin/getty -L 115200 ttyS0 vt102
EOF

echo "========================================================================"
echo "Please enter your WIFI AP name:"
read apname
echo "Please enter your WIFI AP password:"
read appassword

# preparing the RTL8723BS firmware
if [ ! -d $fspath/lib/firmware/rtlwifi/ ]; then
    mkdir -p $fspath/lib/firmware/rtlwifi/
fi
cp rtl8723bs_nic.bin $fspath/lib/firmware/rtlwifi/

# preparing the RTL8723BS module
if [ ! -d $fspath/lib/modules/rtl ]; then
	mkdir -p $fspath/lib/modules
fi
cp r8723bs.ko $fspath/lib/modules

# setting up the WIFI config
rm -f $fspath/etc/wpa_supplicant.conf
cat>$fspath/etc/wpa_supplicant.conf<<EOF
#############################################
# for wifi rtl8723bs
#############################################
ctrl_interface=/var/run/wpa_supplicant
ctrl_interface_group=0
ap_scan=1
network={
    ssid="$apname"
    scan_ssid=1
    key_mgmt=WPA-EAP WPA-PSK IEEE8021X NONE
    pairwise=TKIP CCMP
    group=CCMP TKIP WEP104 WEP40
    psk="$appassword"
    priority=5
}
EOF

# setting up the init script for RTL8723BS
sed -i 's/^exit 0//' $fspath/etc/rc.local
cat>>$fspath/etc/rc.local<<EOF
#############################################
# for wifi rtl8723bs
#############################################
insmod /lib/modules/r8723bs.ko
ifconfig wlan0 up
wpa_supplicant -B -d -i wlan0 -c /etc/wpa_supplicant.conf
udhcpc -i wlan0
EOF
echo "" >> $fspath/etc/rc.local
echo "exit 0" >> $fspath/etc/rc.local

echo "========================================================================"
echo "installing qemu-user-static..."
apt-get -y --force-yes install qemu-user-static
cp /usr/bin/qemu-arm-static $fspath/usr/bin/

echo "========================================================================"
echo "installing essential softwares..."
cp /etc/resolv.conf $fspath/etc/resolv.conf
mv $fspath/etc/apt/sources.list $fspath/etc/apt/sources.list.bak
cat > $fspath/etc/apt/sources.list << EOF
deb http://mirrors.ustc.edu.cn/ubuntu-ports/ xenial main multiverse restricted universe
deb http://mirrors.ustc.edu.cn/ubuntu-ports/ xenial-backports main multiverse restricted universe
deb http://mirrors.ustc.edu.cn/ubuntu-ports/ xenial-proposed main multiverse restricted universe
deb http://mirrors.ustc.edu.cn/ubuntu-ports/ xenial-security main multiverse restricted universe
deb http://mirrors.ustc.edu.cn/ubuntu-ports/ xenial-updates main multiverse restricted universe
deb-src http://mirrors.ustc.edu.cn/ubuntu-ports/ xenial main multiverse restricted universe
deb-src http://mirrors.ustc.edu.cn/ubuntu-ports/ xenial-backports main multiverse restricted universe
deb-src http://mirrors.ustc.edu.cn/ubuntu-ports/ xenial-proposed main multiverse restricted universe
deb-src http://mirrors.ustc.edu.cn/ubuntu-ports/ xenial-security main multiverse restricted universe
deb-src http://mirrors.ustc.edu.cn/ubuntu-ports/ xenial-updates main multiverse restricted universe
EOF

echo "========================================================================"
echo "doing apt installing..."
echo "now you should enter these command manually:"
echo "    /apt.sh && exit"
cp apt.sh $fspath
./ch-mount.sh -m $fspath/
# enter your command here
./ch-mount.sh -u $fspath/
rm $fspath/apt.sh

echo "========================================================================"
echo "setting up SSH..."
sed -i 's/^PermitRootLogin prohibit-password/#PermitRootLogin prohibit-password/' $fspath/etc/ssh/sshd_config
echo "PermitRootLogin yes" >> $fspath/etc/ssh/sshd_config
echo "PermitEmptyPasswords yes" >> $fspath/etc/ssh/sshd_config

echo "========================================================================"
echo "setting up users..."
echo "ubuntu" > $fspath/etc/hostname
echo "127.0.0.1 localhost" >> $fspath/etc/hosts
echo "127.0.0.1 ubuntu" >> $fspath/etc/hosts

echo "========================================================================"
echo "umounting $DEVNAME..."
sync
umount $DEVNAME
rm -rf mnt

echo OK

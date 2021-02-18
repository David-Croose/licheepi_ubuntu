#!/bin/bash

fspath=mnt

apt-get update
passwd
adduser sam

apt-get -y --force-yes install \
  language-pack-en-base \
  sudo \
  ssh \
  net-tools \
  ethtool \
  wireless-tools \
  ifupdown \
  network-manager \
  iputils-ping \
  rsyslog \
  bash-completion \
  htop \
  vim \
  kmod \
  wpasupplicant \
  udhcpc \
  --no-install-recommends

### echo "setting up others..."
### dpkg-reconfigure resolvconf		# auto update DNS
### dpkg-reconfigure tzdata			# setting time zone

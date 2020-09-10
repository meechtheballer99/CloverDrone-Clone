#! /usr/bin/env bash

#
# Script for installing software to the image.
#
# Copyright (C) 2018 Copter Express Technologies
#
# Author: Artem Smirnov <urpylka@gmail.com>
#
# Distributed under MIT License (available at https://opensource.org/licenses/MIT).
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#

set -e # Exit immidiately on non-zero result

echo_stamp() {
  # TEMPLATE: echo_stamp <TEXT> <TYPE>
  # TYPE: SUCCESS, ERROR, INFO

  # More info there https://www.shellhacks.com/ru/bash-colors/

  TEXT="$(date '+[%Y-%m-%d %H:%M:%S]') $1"
  TEXT="\e[1m${TEXT}\e[0m" # BOLD

  case "$2" in
    SUCCESS)
    TEXT="\e[32m${TEXT}\e[0m";; # GREEN
    ERROR)
    TEXT="\e[31m${TEXT}\e[0m";; # RED
    *)
    TEXT="\e[34m${TEXT}\e[0m";; # BLUE
  esac
  echo -e ${TEXT}
}

# https://gist.github.com/letmaik/caa0f6cc4375cbfcc1ff26bd4530c2a3
# https://github.com/travis-ci/travis-build/blob/master/lib/travis/build/templates/header.sh
my_travis_retry() {
  local result=0
  local count=1
  while [ $count -le 3 ]; do
    [ $result -ne 0 ] && {
      echo -e "\n${ANSI_RED}The command \"$@\" failed. Retrying, $count of 3.${ANSI_RESET}\n" >&2
    }
    # ! { } ignores set -e, see https://stackoverflow.com/a/4073372
    ! { "$@"; result=$?; }
    [ $result -eq 0 ] && break
    count=$(($count + 1))
    sleep 1
  done

  [ $count -gt 3 ] && {
    echo -e "\n${ANSI_RED}The command \"$@\" failed 3 times.${ANSI_RESET}\n" >&2
  }

  return $result
}

echo_stamp "Increase apt retries"

echo "APT::Acquire::Retries \"3\";" > /etc/apt/apt.conf.d/80-retries

echo_stamp "Install apt keys & repos"

# TODO: This STDOUT consist 'OK'
curl http://deb.coex.tech/aptly_repo_signing.key 2> /dev/null | apt-key add -
apt-get update \
&& apt-get install --no-install-recommends -y dirmngr > /dev/null \
&& apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654

echo "deb http://packages.ros.org/ros/ubuntu buster main" > /etc/apt/sources.list.d/ros-latest.list
echo "deb http://deb.coex.tech/opencv3 buster main" > /etc/apt/sources.list.d/opencv3.list
echo "deb http://deb.coex.tech/ros buster main" > /etc/apt/sources.list.d/rpi-ros-melodic.list
echo "deb http://deb.coex.tech/clover buster main" > /etc/apt/sources.list.d/clover.list

echo_stamp "Update apt cache"

# TODO: FIX ERROR: /usr/bin/apt-key: 596: /usr/bin/apt-key: cannot create /dev/null: Permission denied
apt-get update
# && apt upgrade -y

# Let's retry fetching those packages several times, just in case
echo_stamp "Software installing"
my_travis_retry apt-get install --no-install-recommends -y \
unzip \
zip \
ipython \
ipython3 \
screen \
byobu  \
nmap \
lsof \
git \
dnsmasq  \
tmux \
vim \
cmake \
tcpdump \
libpoco-dev \
libzbar0 \
python-rosdep \
python-rosinstall-generator \
python-wstool \
python-rosinstall \
build-essential \
libffi-dev \
monkey \
pigpio python-pigpio python3-pigpio \
i2c-tools \
espeak espeak-data python-espeak \
ntpdate \
python-dev \
python3-dev \
python-systemd \
mjpg-streamer \
python3-opencv

# Deny byobu to check available updates
sed -i "s/updates_available//" /usr/share/byobu/status/status
# sed -i "s/updates_available//" /home/pi/.byobu/status

echo_stamp "Installing pip"
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3 get-pip.py
python get-pip.py
rm get-pip.py
#my_travis_retry pip install --upgrade pip
#my_travis_retry pip3 install --upgrade pip

echo_stamp "Make sure both pip and pip3 are installed"
pip --version
pip3 --version

echo_stamp "Install and enable Butterfly (web terminal)"
echo_stamp "Workaround for tornado >= 6.0 breaking butterfly"
my_travis_retry pip3 install tornado==5.1.1
my_travis_retry pip3 install butterfly
my_travis_retry pip3 install butterfly[systemd]
systemctl enable butterfly.socket

echo_stamp "Install ws281x library"
my_travis_retry pip3 install --prefer-binary rpi_ws281x

echo_stamp "Setup Monkey"
mv /etc/monkey/sites/default /etc/monkey/sites/default.orig
mv /root/monkey /etc/monkey/sites/default
systemctl enable monkey.service

echo_stamp "Install Node.js"
cd /home/pi
wget https://nodejs.org/dist/v10.15.0/node-v10.15.0-linux-arm64.tar.gz
tar -xzf node-v10.15.0-linux-arm64.tar.gz
cp -R node-v10.15.0-linux-arm64/* /usr/local/
rm -rf node-v10.15.0-linux-arm64/
rm node-v10.15.0-linux-arm64.tar.gz

echo_stamp "Installing ptvsd"
my_travis_retry pip install ptvsd
my_travis_retry pip3 install ptvsd

echo_stamp "Installing pyzbar"
my_travis_retry pip install pyzbar
my_travis_retry pip3 install pyzbar

echo_stamp "Add .vimrc"
cat << EOF > /home/pi/.vimrc
set mouse-=a
syntax on
autocmd BufNewFile,BufRead *.launch set syntax=xml
EOF

echo_stamp "Change default keyboard layout to US"
sed -i 's/XKBLAYOUT="gb"/XKBLAYOUT="us"/g' /etc/default/keyboard

echo_stamp "Attempting to kill dirmngr"
gpgconf --kill dirmngr
# dirmngr is only used by apt-key, so we can safely kill it.
# We ignore pkill's exit value as well.
pkill -9 -f dirmngr || true

echo_stamp "End of software installation"

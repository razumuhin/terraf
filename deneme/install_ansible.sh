#!/bin/bash
apt-get update
apt-get -y install python3-pip
pip3 install ansible
# ansible-galaxy collection install community.kubernetes --- optional

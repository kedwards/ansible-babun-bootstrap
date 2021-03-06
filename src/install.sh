#!/usr/bin/env zsh

if [ ! -d ~/workspace/abb ]
then
  git clone -b master --single-branch https://github.com/kedwards/ansible-babun-bootstrap.git ~/workspace/abb
else
  cd ~/workspace/abb
  git pull
  cd ~/workspace
fi

source ~/workspace/abb/src/abb.sh

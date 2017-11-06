#!/usr/bin/env zsh

if [ ! -d ~/workspace/abb ]
then
  git clone https://github.com/kedwards/ansible-babun-bootstrap.git ~/workspace/abb &> /dev/null
else
  cd ~/workspace/abb
  git pull --rebase &> /dev/null
fi

source ~/workspace/abb/src/abb.sh

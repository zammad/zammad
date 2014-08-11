#!/bin/bash
get_distro(){
  arch=$(uname -m)
  kernel=$(uname -r)
  if [ -f /etc/lsb-release ]; then
    os=$(lsb_release -s -d)
  elif [ -f /etc/debian_version ]; then
    os="Debian $(cat /etc/debian_version)"
  elif [ -f /etc/redhat-release ]; then
    os=`cat /etc/redhat-release`
  else
    os="$(uname -s) $(uname -r)"
  fi
}


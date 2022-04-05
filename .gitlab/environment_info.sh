#!/bin/bash

date -u --rfc-3339=seconds
echo
top -b -n1 -w240
echo
ps aux --width 240
echo
free -m
echo
mount
echo
df -h
echo
echo "Last 100 lines from kernel log"
dmesg | tail -n 100
echo
echo "Last 1000 lines from system log (journalctl)"
journalctl -n 1000

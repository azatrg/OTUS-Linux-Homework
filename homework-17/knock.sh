#!/bin/bash
telnet 192.168.255.1 8881 &
telnet 192.168.255.1 7777 &
telnet 192.168.255.1 9991 &
ssh vagrant@192.168.255.1

#!/bin/bash
/root/double_master/set_slave.sh
#if it is ms, do not ssh set slave
ssh 121.201.125.74 "/root/double_master/set_slave.sh"

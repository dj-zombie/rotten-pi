#!/bin/bash
set -x

server=$1
tunnel=2222
my_ssh_port=22
remote_ssh_port=9991

autossh $server -p $remote_ssh_port -f -N -R "$tunnel":localhost:"$my_ssh_port" -o LogLevel=error -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
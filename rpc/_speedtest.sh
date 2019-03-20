#!/bin/bash -e

user=$1
address=$2


ssh $user@$address << EOF
curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -
EOF

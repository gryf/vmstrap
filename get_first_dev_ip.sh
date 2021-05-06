#!/bin/bash

for i in $(seq 0 3); do
    ifname=$(ip -j a|jq -r .[$i].ifname)
    if [[ "${ifname}" = "lo" ]]; then
        continue
    fi
    echo $(ip -j a|jq -r \
        ".[$i].addr_info[] | select(.family == \"inet\") | .local")
    break;
done

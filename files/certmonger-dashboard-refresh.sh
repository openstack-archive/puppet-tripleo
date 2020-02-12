#!/bin/bash

# Get mgr systemd unit
mgr_unit=$(systemctl list-units | awk '/ceph-mgr/ {print $1}')

# Restart the mgr systemd unit
if [ -n "$mgr_unit" ]; then
    systemctl restart "$mgr_unit"
fi


#!/bin/bash

# Get ceph rgw systemd unit
rgw_unit=$(systemctl list-unit-files | awk '/radosgw/ {print $1}')

# Restart the rgw systemd unit
if [ -n "$rgw_unit" ]; then
    systemctl restart "$rgw_unit"
fi

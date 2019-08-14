#!/bin/bash

# Get grafana systemd unit
grafana_unit=$(systemctl list-unit-files | awk '/grafana/ {print $1}')

# Restart the grafana systemd unit
if [ -z "$grafana_unit" ]; then
    systemctl restart "$grafana_unit"
fi

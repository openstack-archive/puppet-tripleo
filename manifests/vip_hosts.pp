# Copyright 2016 Red Hat, Inc.
# All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: tripleo::vip_hosts
#
# Write the overcloud VIPs into /etc/hosts
#
# === Parameters
#
# [*hosts_spec*]
#   The specification of the hosts that will be added to the /etc/hosts file.
#   These come in the form of a hash that will be consumed by create_resources.
#   e.g.:
#   tripleo::hosts_spec:
#     host-1:
#       name: host1.domain
#       ip: 127.0.0.1
#     host-2:
#       name: host2.domain
#       ip: 127.0.0.2
#
class tripleo::vip_hosts (
  $hosts_spec
) {
  create_resources('host', $hosts_spec)
}


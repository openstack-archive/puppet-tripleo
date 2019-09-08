# Copyright 2017 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: tripleo::profile::base::ironic_inspector
#
# Ironic inspector profile for TripleO
#
# === Parameters
#
# [*inspection_subnets*]
#   IP ranges that will be given to nodes during the inspection
#   process. Either a list of ip ranged or a dictionary with $::hostname as
#   key to enable HA deployments using disjoint address pools served by the
#   DHCP instances.
#
#    Example for Non-HA deployment, a list of ip-ranges:
#               - ip_range: 192.168.0.100,192.168.0.120
#               - ip_range: 192.168.1.100,192.168.1.200
#                 netmask: 255.255.255.0
#                 gateway: 192.168.1.254
#                 tag: subnet1
#
#    Example for HA deployment using disjoint address pools:
#               overcloud-ironic-0:
#                 - ip_range: 192.168.24.100,192.168.24.119
#                 - ip_range: 192.168.25.100,192.168.25.119
#                   netmask: 255.255.255.0
#                   gateway: 192.168.25.254
#                   tag: subnet1
#               overcloud-ironic-1:
#                 - ip_range: 192.168.24.120,192.168.24.139
#                 - ip_range: 192.168.25.120,192.168.25.139
#                   netmask: 255.255.255.0
#                   gateway: 192.168.25.254
#                   tag: subnet1
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('ironic_inspector_short_bootstrap_node_name')
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')

class tripleo::profile::base::ironic_inspector (
  $inspection_subnets = [],
  $bootstrap_node     = hiera('ironic_inspector_short_bootstrap_node_name', undef),
  $step               = Integer(hiera('step')),
) {

  include ::tripleo::profile::base::ironic_inspector::authtoken

  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  if is_hash($inspection_subnets) {
    $inspection_subnets_real = $inspection_subnets[$::hostname]
  } elsif is_array($inspection_subnets) {
    $inspection_subnets_real = $inspection_subnets
  }

  if $step >= 4 or ($step >= 3 and $sync_db) {
    include ::ironic::inspector::cors
    class { '::ironic::inspector':
      sync_db            => $sync_db,
      dnsmasq_ip_subnets => $inspection_subnets_real,
    }

    include ::ironic::inspector::pxe_filter
    include ::ironic::inspector::pxe_filter::dnsmasq
    include ::ironic::config
    include ::ironic::inspector::logging
  }
}

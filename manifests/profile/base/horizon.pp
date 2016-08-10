# Copyright 2016 Red Hat, Inc.
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
# == Class: tripleo::profile::base::horizon
#
# Horizon profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::horizon (
  $step = hiera('step'),
) {
  if $step >= 4 {
    # Horizon
    include ::apache::mod::remoteip
    include ::apache::mod::status
    if 'cisco_n1kv' in hiera('neutron::plugins::ml2::mechanism_drivers') {
      $_profile_support = 'cisco'
    } else {
      $_profile_support = 'None'
    }
    $neutron_options   = {'profile_support' => $_profile_support }
    $memcached_ipv6 = hiera('memcached_ipv6', false)
    if $memcached_ipv6 {
      $horizon_memcached_servers = hiera('memcached_node_ips_v6', '[::1]')
    } else {
      $horizon_memcached_servers = hiera('memcached_node_ips', '127.0.0.1')
    }
    class { '::horizon':
      cache_server_ip => $horizon_memcached_servers,
      neutron_options => $neutron_options,
    }
  }
}

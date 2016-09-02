# Copyright 2014 Red Hat, Inc.
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

# == Class: tripleo::keepalived
#
# Configure keepalived for TripleO.
#
# === Parameters:
#
# [*controller_virtual_ip*]
#  Control IP or group of IPs to bind the pools
#  Can be a string or an array.
#  Defaults to undef
#
# [*control_virtual_interface*]
#  Interface to bind the control VIP
#  Can be a string or an array.
#  Defaults to undef
#
# [*public_virtual_interface*]
#  Interface to bind the public VIP
#  Can be a string or an array.
#  Defaults to undef
#
# [*public_virtual_ip*]
#  Public IP or group of IPs to bind the pools
#  Can be a string or an array.
#  Defaults to undef
#
# [*internal_api_virtual_ip*]
#  Virtual IP on the internal API network.
#  A string.
#  Defaults to false
#
# [*storage_virtual_ip*]
#  Virtual IP on the storage network.
#  A string.
#  Defaults to false
#
# [*storage_mgmt_virtual_ip*]
#  Virtual IP on the storage mgmt network.
#  A string.
#  Defaults to false
#
# [*redis_virtual_ip*]
#  Virtual IP on the redis service.
#  A string.
#  Defaults to false
#
class tripleo::keepalived (
  $controller_virtual_ip,
  $control_virtual_interface,
  $public_virtual_interface,
  $public_virtual_ip,
  $internal_api_virtual_ip = false,
  $storage_virtual_ip      = false,
  $storage_mgmt_virtual_ip = false,
  $redis_virtual_ip        = false,
) {

  case $::osfamily {
    'RedHat': {
      $keepalived_name_is_process = false
      $keepalived_vrrp_script     = 'systemctl status haproxy.service'
    } # RedHat
    'Debian': {
      $keepalived_name_is_process = true
      $keepalived_vrrp_script     = undef
    }
    default: {
      warning('Please configure keepalived defaults in tripleo::keepalived.')
      $keepalived_name_is_process = undef
      $keepalived_vrrp_script     = undef
    }
  }

  class { '::keepalived': }
  keepalived::vrrp_script { 'haproxy':
    name_is_process => $keepalived_name_is_process,
    script          => $keepalived_vrrp_script,
  }

  # KEEPALIVE INSTANCE CONTROL
  keepalived::instance { '51':
    interface    => $control_virtual_interface,
    virtual_ips  => [join([$controller_virtual_ip, ' dev ', $control_virtual_interface])],
    state        => 'MASTER',
    track_script => ['haproxy'],
    priority     => 101,
  }

  # KEEPALIVE INSTANCE PUBLIC
  keepalived::instance { '52':
    interface    => $public_virtual_interface,
    virtual_ips  => [join([$public_virtual_ip, ' dev ', $public_virtual_interface])],
    state        => 'MASTER',
    track_script => ['haproxy'],
    priority     => 101,
  }


  if $internal_api_virtual_ip and $internal_api_virtual_ip != $controller_virtual_ip {
    $internal_api_virtual_interface = interface_for_ip($internal_api_virtual_ip)
    # KEEPALIVE INTERNAL API NETWORK
    keepalived::instance { '53':
      interface    => $internal_api_virtual_interface,
      virtual_ips  => [join([$internal_api_virtual_ip, ' dev ', $internal_api_virtual_interface])],
      state        => 'MASTER',
      track_script => ['haproxy'],
      priority     => 101,
    }
  }

  if $storage_virtual_ip and $storage_virtual_ip != $controller_virtual_ip {
    $storage_virtual_interface = interface_for_ip($storage_virtual_ip)
    # KEEPALIVE STORAGE NETWORK
    keepalived::instance { '54':
      interface    => $storage_virtual_interface,
      virtual_ips  => [join([$storage_virtual_ip, ' dev ', $storage_virtual_interface])],
      state        => 'MASTER',
      track_script => ['haproxy'],
      priority     => 101,
    }
  }

  if $storage_mgmt_virtual_ip and $storage_mgmt_virtual_ip != $controller_virtual_ip {
    $storage_mgmt_virtual_interface = interface_for_ip($storage_mgmt_virtual_ip)
    # KEEPALIVE STORAGE MANAGEMENT NETWORK
    keepalived::instance { '55':
      interface    => $storage_mgmt_virtual_interface,
      virtual_ips  => [join([$storage_mgmt_virtual_ip, ' dev ', $storage_mgmt_virtual_interface])],
      state        => 'MASTER',
      track_script => ['haproxy'],
      priority     => 101,
    }
  }

  if $redis_virtual_ip and $redis_virtual_ip != $controller_virtual_ip {
    $redis_virtual_interface = interface_for_ip($redis_virtual_ip)
    # KEEPALIVE STORAGE MANAGEMENT NETWORK
    keepalived::instance { '56':
      interface    => $redis_virtual_interface,
      virtual_ips  => [join([$redis_virtual_ip, ' dev ', $redis_virtual_interface])],
      state        => 'MASTER',
      track_script => ['haproxy'],
      priority     => 101,
    }
  }

}

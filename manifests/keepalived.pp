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
#  DEPRECATED: Virtual IP on the internal API network.
#  A string.
#  Defaults to false
#
# [*storage_virtual_ip*]
#  DEPRECATED: Virtual IP on the storage network.
#  A string.
#  Defaults to false
#
# [*storage_mgmt_virtual_ip*]
#  DEPRECATED: Virtual IP on the storage mgmt network.
#  A string.
#  Defaults to false
#
# [*redis_virtual_ip*]
#  Virtual IP on the redis service.
#  A string.
#  Defaults to false
#
# [*ovndbs_virtual_ip*]
#  Virtual IP on the OVNDBs service.
#  A string.
#  Defaults to false
#
# [*virtual_router_id_base*]
#  Base for range used for virtual router IDs.
#  An integer.
#  Defaults to 50
#
# [*custom_vrrp_script*]
#  A custom vrrp script used to check if haproxy is running. Can
#  be used to override the distro defaults in this module.
#  Defaults to false.
#
# [*network_vips*]
#  A hash of networks with related ip address information.
#  Example:
#   { 'internal_api' => { 'ip_address' => '10.0.0.1', 'index' => 1' } }
#  Defaults to hiera('network_virtual_ips', {})
#
class tripleo::keepalived (
  $controller_virtual_ip,
  $control_virtual_interface,
  $public_virtual_interface,
  $public_virtual_ip,
  $redis_virtual_ip        = false,
  $ovndbs_virtual_ip       = false,
  $virtual_router_id_base  = 50,
  $custom_vrrp_script      = false,
  $network_vips            = hiera('network_virtual_ips', {}),
  # DEPRECATED PARAMETERS
  $internal_api_virtual_ip = false,
  $storage_virtual_ip      = false,
  $storage_mgmt_virtual_ip = false,
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

  if $custom_vrrp_script {
    $keepalived_vrrp_script_real = $custom_vrrp_script
  } else {
    $keepalived_vrrp_script_real = $keepalived_vrrp_script
  }

  class { '::keepalived': }
  keepalived::vrrp_script { 'haproxy':
    name_is_process => $keepalived_name_is_process,
    script          => $keepalived_vrrp_script_real,
  }

  # KEEPALIVE INSTANCE CONTROL
  keepalived::instance { "${$virtual_router_id_base + 1}":
    interface    => $control_virtual_interface,
    virtual_ips  => [join([$controller_virtual_ip, ' dev ', $control_virtual_interface])],
    state        => 'MASTER',
    track_script => ['haproxy'],
    priority     => 101,
  }

  # KEEPALIVE INSTANCE PUBLIC
  keepalived::instance { "${$virtual_router_id_base + 2}":
    interface    => $public_virtual_interface,
    virtual_ips  => [join([$public_virtual_ip, ' dev ', $public_virtual_interface])],
    state        => 'MASTER',
    track_script => ['haproxy'],
    priority     => 101,
  }

  if $redis_virtual_ip and $redis_virtual_ip != $controller_virtual_ip {
    $redis_virtual_interface = interface_for_ip($redis_virtual_ip)
    if is_ipv6_address($redis_virtual_ip) {
      $redis_virtual_netmask = '64'
    } else {
      $redis_virtual_netmask = '32'
    }
    # KEEPALIVE REDIS INSTANCE
    keepalived::instance { "${$virtual_router_id_base + 3}":
      interface    => $redis_virtual_interface,
      virtual_ips  => [join(["${redis_virtual_ip}/${redis_virtual_netmask}", ' dev ', $redis_virtual_interface])],
      state        => 'MASTER',
      track_script => ['haproxy'],
      priority     => 101,
    }
  }

  if $ovndbs_virtual_ip and $ovndbs_virtual_ip != $controller_virtual_ip {
    $ovndbs_virtual_interface = interface_for_ip($ovndbs_virtual_ip)
    # KEEPALIVE OVNDBS MANAGEMENT NETWORK
    keepalived::instance { "${$virtual_router_id_base + 4}":
      interface    => $ovndbs_virtual_interface,
      virtual_ips  => [join([$ovndbs_virtual_ip, ' dev ', $ovndbs_virtual_interface])],
      state        => 'MASTER',
      track_script => ['haproxy'],
      priority     => 101,
    }
  }

  # NOTE - add any new VIPs before the isolated network vips and update this
  # to use the new vrouter id
  $last_fixed_vrouter_id = $virtual_router_id_base + 4

  # Set up all vips for isolated networks, the vrouter id is based on a sequential index
  $network_vips.each |String $net_name, $vip_info| {
    $virtual_ip = $vip_info[ip_address]
    if $virtual_ip and $virtual_ip != $controller_virtual_ip {
      $virtual_interface = interface_for_ip($virtual_ip)
      if is_ipv6_address($virtual_ip) {
        $virtual_netmask = '64'
      } else {
        $virtual_netmask = '32'
      }

      $vrouter_id = $last_fixed_vrouter_id + $vip_info["index"]
      keepalived::instance { "${vrouter_id}":
        interface    => $virtual_interface,
        virtual_ips  => [join(["${virtual_ip}/${virtual_netmask}", ' dev ', $virtual_interface])],
        state        => 'MASTER',
        track_script => ['haproxy'],
        priority     => 101,
      }
    }
  }
}

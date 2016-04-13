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
# == Define: tripleo::pacemaker::haproxy_with_vip
#
# Configure the vip with the haproxy under pacemaker
#
# === Parameters:
#
# [*vip_name*]
#  (String) Logical name of the vip (control, public, storage ...)
#  Required
#
# [*ip_address*]
#  (String) IP address on which HAProxy is colocated
#  Required
#
# [*ensure*]
#  (Boolean) Create the all the resources only if true.  False won't
#  destroy the resource, it will just not create them.
#  Default to true
define tripleo::pacemaker::haproxy_with_vip($vip_name, $ip_address, $ensure = true) {
  if($ensure) {
    if is_ipv6_address($ip_address) {
      $netmask = '64'
    } else {
      $netmask = '32'
    }

    pacemaker::resource::ip { "${vip_name}_vip":
      ip_address   => $ip_address,
      cidr_netmask => $netmask,
    }
    pacemaker::constraint::base { "${vip_name}_vip-then-haproxy":
      constraint_type   => 'order',
      first_resource    => "ip-${ip_address}",
      second_resource   => 'haproxy-clone',
      first_action      => 'start',
      second_action     => 'start',
      constraint_params => 'kind=Optional',
      require           => [Pacemaker::Resource::Service['haproxy'],
                            Pacemaker::Resource::Ip["${vip_name}_vip"]],
    }
    pacemaker::constraint::colocation { "${vip_name}_vip-with-haproxy":
      source  => "ip-${ip_address}",
      target  => 'haproxy-clone',
      score   => 'INFINITY',
      require => [Pacemaker::Resource::Service['haproxy'],
                  Pacemaker::Resource::Ip["${vip_name}_vip"]],
    }
  }
}

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
# == Class: tripleo::profile::base::neutron::plugins::ml2::opendaylight
#
# OpenDaylight ML2 Neutron profile for TripleO
#
# === Parameters
#
# [*odl_port*]
#   (Optional) Port to use for OpenDaylight
#   Defaults to hiera('opendaylight::odl_rest_port')
#
# [*odl_username*]
#   (Optional) Username to configure for OpenDaylight
#   Defaults to 'admin'
#
# [*odl_password*]
#   (Optional) Password to configure for OpenDaylight
#   Defaults to 'admin'
#
# [*odl_url_ip*]
#   (Optional) Virtual IP address for ODL Api Service
#   Defaults to hiera('opendaylight_api_vip')
#
# [*conn_proto*]
#   (Optional) Protocol to use to for ODL REST access
#   Defaults to 'http'
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to hiera('enable_internal_tls', false)
#
# [*internal_api_fqdn*]
#   (Optional) FQDN.
#   Defaults to hiera('cloud_name_internal_api')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::neutron::plugins::ml2::opendaylight (
  $odl_port            = hiera('opendaylight::odl_rest_port'),
  $odl_username        = hiera('opendaylight::username'),
  $odl_password        = hiera('opendaylight::password'),
  $odl_url_ip          = hiera('opendaylight_api_vip'),
  $conn_proto          = 'http',
  $enable_internal_tls = hiera('enable_internal_tls', false),
  $internal_api_fqdn   = hiera('cloud_name_internal_api'),
  $step                = Integer(hiera('step')),
) {

  if $step >= 4 {
    if $enable_internal_tls {
      if empty($internal_api_fqdn) { fail('Internal API FQDN is Empty') }
      $odl_url_addr = $internal_api_fqdn
    } else {
      if empty($odl_url_ip) { fail('OpenDaylight API VIP is Empty') }
      $odl_url_addr = $odl_url_ip
    }
    class { '::neutron::plugins::ml2::opendaylight':
      odl_username => $odl_username,
      odl_password => $odl_password,
      odl_url      => "${conn_proto}://${odl_url_addr}:${odl_port}/controller/nb/v2/neutron",
    }
  }
}

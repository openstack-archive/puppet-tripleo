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
# == Class: tripleo::profile::base::neutron::plugins::ovs::opendaylight
#
# OpenDaylight Neutron OVS profile for TripleO
#
# === Parameters
#
# [*odl_port*]
#   (Optional) Port to use for OpenDaylight
#   Defaults to hiera('opendaylight::odl_rest_port')
#
# [*odl_check_url*]
#   (Optional) URL path used to check if ODL is up
#   Defaults to hiera('opendaylight_check_url')
#
# [*odl_api_ips*]
#   (Optional) List of OpenStack Controller IPs for ODL API
#   Defaults to hiera('opendaylight_api_node_ips')
#
# [*odl_url_ip*]
#   (Optional) Virtual IP address for ODL Api Service
#   Defaults to hiera('opendaylight_api_vip')
#
# [*conn_proto*]
#   (Optional) Protocol to use to for ODL REST access
#   Defaults to hiera('opendaylight::nb_connection_protocol')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::neutron::plugins::ovs::opendaylight (
  $odl_port      = hiera('opendaylight::odl_rest_port'),
  $odl_check_url = hiera('opendaylight_check_url'),
  $odl_api_ips   = hiera('opendaylight_api_node_ips'),
  $odl_url_ip    = hiera('opendaylight_api_vip'),
  $conn_proto    = hiera('opendaylight::nb_connection_protocol'),
  $step          = Integer(hiera('step')),
) {

  if $step >= 4 {
    if empty($odl_api_ips) { fail('No IPs assigned to OpenDaylight Api Service') }

    if ! $odl_url_ip { fail('OpenDaylight API VIP is Empty') }

    # Build URL to check if ODL is up before connecting OVS
    $opendaylight_url = "${conn_proto}://${odl_url_ip}:${odl_port}/${odl_check_url}"

    $odl_ovsdb_str = join(regsubst($odl_api_ips, '.+', 'tcp:\0:6640'), ' ')

    class { '::neutron::plugins::ovs::opendaylight':
      tunnel_ip       => hiera('neutron::agents::ml2::ovs::local_ip'),
      odl_check_url   => $opendaylight_url,
      odl_ovsdb_iface => $odl_ovsdb_str,
    }
  }
}

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
  $conn_proto    = hiera('opendaylight::nb_connection_protocol'),
  $step          = hiera('step'),
) {

  if $step >= 4 {
    # Figure out ODL IP (and VIP if on controller)
    if hiera('odl_on_controller') {
      $opendaylight_controller_ip = $odl_api_ips[0]
      $odl_url_ip = hiera('opendaylight_api_vip')
    } else {
      $opendaylight_controller_ip = hiera('opendaylight::odl_bind_ip')
      $odl_url_ip = $opendaylight_controller_ip
    }

    if ! $opendaylight_controller_ip { fail('OpenDaylight Controller IP is Empty') }

    if ! $odl_url_ip { fail('OpenDaylight API VIP is Empty') }

    # Build URL to check if ODL is up before connecting OVS
    $opendaylight_url = "${conn_proto}://${odl_url_ip}:${odl_port}/${odl_check_url}"

    class { '::neutron::plugins::ovs::opendaylight':
      tunnel_ip       => hiera('neutron::agents::ml2::ovs::local_ip'),
      odl_check_url   => $opendaylight_url,
      odl_ovsdb_iface => "tcp:${opendaylight_controller_ip}:6640",
    }
  }
}

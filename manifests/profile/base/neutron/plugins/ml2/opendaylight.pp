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
# [*conn_proto*]
#   (Optional) Protocol to use to for ODL REST access
#   Defaults to hiera('opendaylight::nb_connection_protocol')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::neutron::plugins::ml2::opendaylight (
  $odl_port   = hiera('opendaylight::odl_rest_port'),
  $conn_proto = hiera('opendaylight::nb_connection_protocol'),
  $step       = hiera('step'),
) {

  if $step >= 4 {
    # Figure out ODL IP
    if hiera('odl_on_controller') {
      $odl_url_ip = hiera('opendaylight_api_vip')
    } else {
      $odl_url_ip = hiera('opendaylight::odl_bind_ip')
    }

    if ! $odl_url_ip { fail('OpenDaylight Controller IP/VIP is Empty') }

    class { '::neutron::plugins::ml2::opendaylight':
      odl_url      => "${conn_proto}://${odl_url_ip}:${odl_port}/controller/nb/v2/neutron";
    }
  }
}

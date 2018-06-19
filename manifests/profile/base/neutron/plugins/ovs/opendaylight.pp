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
#   Defaults to 'http'
#
# [*certificate_specs*]
#   (Optional) The specifications to give to certmonger for the certificate
#   it will create. Note that the certificate nickname must be 'etcd' in
#   the case of this service.
#   Example with hiera:
#     tripleo::profile::base::etcd::certificate_specs:
#       hostname: <overcloud controller fqdn>
#       service_certificate: <service certificate path>
#       service_key: <service key path>
#       principal: "etcd/<overcloud controller fqdn>"
#   Defaults to {}.
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to hiera('enable_internal_tls', false)
#
# [*tunnel_ip*]
#   (Optional) IP to use for Tenant VXLAN/GRE tunneling source address
#   Defaults to hiera('neutron::agents::ml2::ovs::local_ip')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*vhostuser_socket_group*]
#   (Optional) Group name for vhostuser socket dir.
#   Defaults to qemu
#
# [*vhostuser_socket_user*]
#   (Optional) User name for vhostuser socket dir.
#   Defaults to qemu
#
# [*vhostuser_socket_dir*]
#   (Optional) vhostuser socket dir, The directory where $vhostuser_socket_dir
#   will be created with correct permissions, inorder to support vhostuser
#   client mode.
#
class tripleo::profile::base::neutron::plugins::ovs::opendaylight (
  $odl_port               = hiera('opendaylight::odl_rest_port'),
  $odl_check_url          = hiera('opendaylight_check_url'),
  $odl_api_ips            = hiera('opendaylight_api_node_ips'),
  $odl_url_ip             = hiera('opendaylight_api_vip'),
  $conn_proto             = 'http',
  $certificate_specs      = {},
  $enable_internal_tls    = hiera('enable_internal_tls', false),
  $tunnel_ip              = hiera('neutron::agents::ml2::ovs::local_ip'),
  $step                   = Integer(hiera('step')),
  $vhostuser_socket_group = hiera('tripleo::profile::base::neutron::plugins::ovs::opendaylight::vhostuser_socket_group', 'qemu'),
  $vhostuser_socket_user  = hiera('tripleo::profile::base::neutron::plugins::ovs::opendaylight::vhostuser_socket_user', 'qemu'),
  $vhostuser_socket_dir   = hiera('neutron::plugins::ovs::opendaylight::vhostuser_socket_dir', undef),
  ) {

  if $step >= 3 {
    if $vhostuser_socket_dir {
      file { $vhostuser_socket_dir:
        ensure => directory,
        owner  => $vhostuser_socket_user,
        group  => $vhostuser_socket_group,
        mode   => '0775',
      }
    }
  }

  if $step >= 4 {

    if empty($odl_api_ips) { fail('No IPs assigned to OpenDaylight API Service') }

    if empty($odl_url_ip) { fail('OpenDaylight API VIP is Empty') }

    # Build URL to check if ODL is up before connecting OVS
    $opendaylight_url = "${conn_proto}://${odl_url_ip}:${odl_port}/${odl_check_url}"

    if $enable_internal_tls {
      $tls_certfile = $certificate_specs['service_certificate']
      $tls_keyfile = $certificate_specs['service_key']
      $odl_ovsdb_str = join(regsubst($odl_api_ips, '.+', 'ssl:\0:6640'), ' ')
    } else {
      $tls_certfile = undef
      $tls_keyfile = undef
      $odl_ovsdb_str = join(regsubst($odl_api_ips, '.+', 'tcp:\0:6640'), ' ')
    }

    class { '::neutron::plugins::ovs::opendaylight':
      tunnel_ip       => $tunnel_ip,
      odl_check_url   => $opendaylight_url,
      odl_ovsdb_iface => $odl_ovsdb_str,
      enable_tls      => $enable_internal_tls,
      tls_key_file    => $tls_keyfile,
      tls_cert_file   => $tls_certfile
    }
  }

  if $step >= 5 {
    $odl_of_mgr = regsubst($odl_ovsdb_str , ':6640', ':6653')
    # Workaround until OpenDayight is capable of synchronizing flows
    if ! synchronize_odl_ovs_flows($odl_of_mgr) {
      fail('Failed to validate OVS OpenFlow pipeline')
    }
  }
}

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
# == Class: tripleo::profile::base::neutron::plugins::ml2::ovn
#
# OVN Neutron ML2 profile for tripleo
#
# [*ovn_db_host*]
#   The IP-Address where OVN DBs are listening.
#   Defaults to lookup('ovn_dbs_vip', undef, undef, undef)
#
# [*ovn_db_node_ips*]
#   (Optional) The OVN DBs node ip addresses are listening.
#   Defaults to lookup('ovn_dbs_node_ips', undef, undef, undef)
#
# [*ovn_db_clustered*]
#   (Optional) Boolean indicating if we're running with ovn db clustering
#   or pacemaker. Defaults to false for backwards compatibility
#   Defaults to lookup('ovn_db_clustered', undef, undef, false)
#
# [*ovn_nb_port*]
#   (Optional) Port number on which northbound database is listening
#   Defaults to lookup('ovn::northbound::port')
#
# [*ovn_sb_port*]
#   (Optional) Port number on which southbound database is listening
#   Defaults to lookup('ovn::southbound::port')
#
# [*ovn_nb_private_key*]
#   (optional) The PEM file with private key for SSL connection to OVN-NB-DB
#   Defaults to $::os_service_default
#
# [*ovn_nb_certificate*]
#   (optional) The PEM file with certificate that certifies the private
#   key specified in ovn_nb_private_key
#   Defaults to $::os_service_default
#
# [*ovn_nb_ca_cert*]
#   (optional) The PEM file with CA certificate that OVN should use to
#   verify certificates presented to it by SSL peers
#   Defaults to $::os_service_default
#
# [*ovn_sb_private_key*]
#   (optional) The PEM file with private key for SSL connection to OVN-SB-DB
#   Defaults to $::os_service_default
#
# [*ovn_sb_certificate*]
#   (optional) The PEM file with certificate that certifies the
#   private key specified in ovn_sb_private_key
#   Defaults to $::os_service_default
#
# [*ovn_sb_ca_cert*]
#   (optional) The PEM file with CA certificate that OVN should use to
#   verify certificates presented to it by SSL peers
#   Defaults to $::os_service_default
#
# [*protocol*]
#   (optional) Protocol use in communication with dbs
#   Defaults to tcp
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
# [*neutron_dns_integration*]
#   (Optional) Configure neutron to use the supplied unbound resolver nodes.
#   Defaults to false
#
# [*unbound_resolvers*]
#   (Optional) Unbound resolvers if configured.
#   Defaults to lookup('unbound_node_ips', undef, undef, undef)
#
# [*dns_servers*]
#   (Optional) Heat template defined dns servers if provided.
#   Defaults to lookup('neutron::plugins::ml2::ovn', undef, undef, $::os_service_default)
#
class tripleo::profile::base::neutron::plugins::ml2::ovn (
  $ovn_db_host              = lookup('ovn_dbs_vip', undef, undef, undef),
  $ovn_db_node_ips          = lookup('ovn_dbs_node_ips', undef, undef, undef),
  $ovn_db_clustered         = lookup('ovn_db_clustered', undef, undef, false),
  $ovn_nb_port              = lookup('ovn::northbound::port'),
  $ovn_sb_port              = lookup('ovn::southbound::port'),
  $ovn_nb_private_key       = $::os_service_default,
  $ovn_nb_certificate       = $::os_service_default,
  $ovn_nb_ca_cert           = $::os_service_default,
  $ovn_sb_private_key       = $::os_service_default,
  $ovn_sb_certificate       = $::os_service_default,
  $ovn_sb_ca_cert           = $::os_service_default,
  $protocol                 = 'tcp',
  $step                     = Integer(lookup('step')),
  $neutron_dns_integration  = false,
  $unbound_resolvers        = lookup('unbound_node_ips', undef, undef, undef),
  $dns_servers              = lookup('neutron::plugins::ml2::ovn::dns_servers', undef, undef, $::os_service_default),
) {

  if $step >= 4 {
    if $ovn_db_clustered {
      $db_hosts = any2array($ovn_db_node_ips)
    } else {
      $db_hosts = any2array($ovn_db_host)
    }
    $sb_conn = $db_hosts.map |$h| { join([$protocol, normalize_ip_for_uri($h), "${ovn_sb_port}"], ':') }
    $nb_conn = $db_hosts.map |$h| { join([$protocol, normalize_ip_for_uri($h), "${ovn_nb_port}"], ':') }

    if $neutron_dns_integration and $unbound_resolvers {
      $unbound_resolvers_real = $unbound_resolvers
    } else {
      $unbound_resolvers_real = $dns_servers
    }

    class { 'neutron::plugins::ml2::ovn':
      ovn_nb_connection  => join(any2array($nb_conn), ','),
      ovn_sb_connection  => join(any2array($sb_conn), ','),
      ovn_nb_private_key => $ovn_nb_private_key,
      ovn_nb_certificate => $ovn_nb_certificate,
      ovn_nb_ca_cert     => $ovn_nb_ca_cert,
      ovn_sb_private_key => $ovn_sb_private_key,
      ovn_sb_certificate => $ovn_sb_certificate,
      ovn_sb_ca_cert     => $ovn_sb_ca_cert,
      dns_servers        => $unbound_resolvers_real
    }
  }
}


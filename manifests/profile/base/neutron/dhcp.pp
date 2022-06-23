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
# == Class: tripleo::profile::base::neutron::dhcp
#
# Neutron DHCP Agent profile for tripleo
#
# === Parameters
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
class tripleo::profile::base::neutron::dhcp (
  $step                     = Integer(lookup('step')),
  $neutron_dns_integration  = false,
  $unbound_resolvers        = lookup('unbound_node_ips', undef, undef, undef),
) {
  if $step >= 4 {
    include tripleo::profile::base::neutron

    if $neutron_dns_integration and $unbound_resolvers {
      class{ 'neutron::agents::dhcp':
        dnsmasq_dns_servers => $unbound_resolvers
      }
    } else {
      include neutron::agents::dhcp
    }

    Service<| title == 'neutron-server' |> -> Service <| title == 'neutron-dhcp' |>
  }
}

#
# Copyright (C) 2015 eNovance SAS <licensing@enovance.com>
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
# == Define: tripleo::firewall::rule
#
# Define used to manage IPtables rules.
#
# === Parameters:
#
# [*port*]
#  (optional) The port associated to the rule.
#  Defaults to undef
#
# [*dport*]
#  (optional) The destination port associated to the rule.
#  Defaults to undef
#
# [*sport*]
#  (optional) The source port associated to the rule.
#  Defaults to undef
#
# [*proto*]
#  (optional) The protocol associated to the rule.
#  Defaults to 'tcp'
#
# [*action*]
#  (optional) The action policy associated to the rule.
#  Defaults to 'accept'
#
# [*state*]
#  (optional) Array of states associated to the rule..
#  Defaults to ['NEW']
#
# [*source*]
#  (optional) The source IP address associated to the rule.
#  Defaults to '0.0.0.0/0'
#
# [*iniface*]
#  (optional) The network interface associated to the rule.
#  Defaults to undef
#
# [*chain*]
#  (optional) The chain associated to the rule.
#  Defaults to 'INPUT'
#
# [*destination*]
#  (optional) The destination cidr associated to the rule.
#  Defaults to undef
#
#  [*extras*]
#  (optional) Hash of any puppetlabs-firewall supported parameters.
#  Defaults to {}
#
define tripleo::firewall::rule (
  $port        = undef,
  $dport       = undef,
  $sport       = undef,
  $proto       = 'tcp',
  $action      = 'accept',
  $state       = ['NEW'],
  $source      = '0.0.0.0/0',
  $iniface     = undef,
  $chain       = 'INPUT',
  $destination = undef,
  $extras      = {},
) {

  if $port == 'all' {
    warning("All ${proto} traffic will be open on this host.")
    # undef so the IPtables rule won't have any port specified.
    $port_real = undef
  } else {
    $port_real = $port
  }

  $basic = {
    'port'        => $port_real,
    'dport'       => $dport,
    'sport'       => $sport,
    'proto'       => $proto,
    'action'      => $action,
    'source'      => $source,
    'iniface'     => $iniface,
    'chain'       => $chain,
    'destination' => $destination,
  }
  if $proto != 'gre' {
    $state_rule = {
      'state' => $state
    }
  } else {
    $state_rule = {}
  }


  $rule = merge($basic, $state_rule, $extras)
  validate_hash($rule)

  # This conditional will ensure that TCP and UDP firewall rules have
  # a port specified in the configuration when using INPUT or OUTPUT chains.
  # If not, the Puppet catalog will fail.
  # If we don't do this sanity check, a user could create some TCP/UDP
  # rules without port, and the result would be an iptables rule that allow any
  # traffic on the host.
  if ($proto in ['tcp', 'udp']) and (! ($port or $dport or $sport) and ($chain != 'FORWARD')) {
    fail("${title} firewall rule cannot be created. TCP or UDP rules for INPUT or OUTPUT need port or sport or dport.")
  }
  create_resources('firewall', { "${title}" => $rule })

}

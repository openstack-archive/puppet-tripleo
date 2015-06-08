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
# [*extras*]
#  (optional) Hash of any puppetlabs-firewall supported parameters.
#  Defaults to {}
#
define tripleo::firewall::rule (
  $port    = undef,
  $proto   = 'tcp',
  $action  = 'accept',
  $state   = ['NEW'],
  $source  = '0.0.0.0/0',
  $iniface = undef,
  $chain   = 'INPUT',
  $extras  = {},
) {

  $basic = {
    'port'    => $port,
    'proto'   => $proto,
    'action'  => $action,
    'state'   => $state,
    'source'  => $source,
    'iniface' => $iniface,
    'chain'   => $chain,
  }

  $rule = merge($basic, $extras)
  validate_hash($rule)

  create_resources('firewall', { "${title}" => $rule })

}

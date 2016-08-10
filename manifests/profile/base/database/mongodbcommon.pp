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
# == Class: tripleo::profile::base::database::mongodb
#
# Mongodb profile for tripleo
#
# === Parameters
#
# [*mongodb_ipv6_enabled*]
#   A boolean value for mongodb server ipv6 is enabled or not
#   Defaults to false
#
# [*mongodb_node_ips*]
#   List of The mongodb node ip addresses
#
class tripleo::profile::base::database::mongodbcommon (
  $mongodb_ipv6_enabled = false,
  $mongodb_node_ips     = hiera('mongodb_node_ips'),
) {
  $port = '27017'

  # NOTE(gfidente): the following vars are needed on all nodes.
  # The addresses mangling will hopefully go away when we'll be able to
  # configure the connection string via hostnames, until then, we need to pass
  # the list of IPv6 addresses *with* port and without the brackets as 'members'
  # argument for the 'mongodb_replset' resource.
  if str2bool($mongodb_ipv6_enabled) {
    $mongo_node_ips_with_port_prefixed = prefix($mongodb_node_ips, '[')
    $mongo_node_ips_with_port = suffix(
      $mongo_node_ips_with_port_prefixed, "]:${port}")
    $mongo_node_ips_with_port_nobr = suffix($mongodb_node_ips, ":${port}")
  } else {
    $mongo_node_ips_with_port = suffix($mongodb_node_ips, ":${port}")
    $mongo_node_ips_with_port_nobr = suffix($mongodb_node_ips, ":${port}")
  }
  $mongo_node_string = join($mongo_node_ips_with_port, ',')

}

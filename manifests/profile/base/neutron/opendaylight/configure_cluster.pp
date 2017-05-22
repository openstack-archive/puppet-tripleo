# Copyright 2017 Red Hat, Inc.
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
# Configures an OpenDaylight cluster.
# It creates the akka configuration file for ODL to cluster correctly
# It will not configure clustering if less than 3 nodes
#
# == Function: tripleo::profile::base::neutron::opendaylight::configure_cluster
#
# == Parameters
#
# [*node_name*]
#   The short hostname of node
#
# [*odl_api_ips*] Array of IPs per ODL node
#   Defaults to empty array
#
define tripleo::profile::base::neutron::opendaylight::configure_cluster(
  $node_name,
  $odl_api_ips = [],
) {
  validate_array($odl_api_ips)
  if size($odl_api_ips) > 2 {
    $node_string = split($node_name, '-')
    $ha_node_index = $node_string[-1] + 1
    $ha_node_ip_str = join($odl_api_ips, ' ')
    exec { 'Configure ODL Clustering':
      command => "configure_cluster.sh ${ha_node_index} ${ha_node_ip_str}",
      path    => '/opt/opendaylight/bin/:/usr/sbin:/usr/bin:/sbin:/bin',
      creates => '/opt/opendaylight/configuration/initial/akka.conf'
    }
  }
}


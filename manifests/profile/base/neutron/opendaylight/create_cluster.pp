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
# == Class: tripleo::profile::base::neutron::opendaylight::create_cluster
#
# OpenDaylight class only used for creating clusters with container deployments
#
# === Parameters
#
# [*odl_api_ips*]
#   (Optional) List of OpenStack Controller IPs for ODL API
#   Defaults to hiera('opendaylight_api_node_ips')
#
# [*node_name*]
#   (Optional) The short hostname of node
#   Defaults to hiera('bootstrap_nodeid')
#
class tripleo::profile::base::neutron::opendaylight::create_cluster (
  $odl_api_ips  = hiera('opendaylight_api_node_ips'),
  $node_name    = hiera('bootstrap_nodeid')
) {

  tripleo::profile::base::neutron::opendaylight::configure_cluster {'ODL cluster':
    node_name   => $node_name,
    odl_api_ips => $odl_api_ips,
  }

}

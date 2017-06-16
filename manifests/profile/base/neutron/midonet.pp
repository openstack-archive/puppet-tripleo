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
# == Class: tripleo::profile::base::neutron::midonet
#
# Midonet Neutron profile for tripleo
#
# === Parameters
#
# [*admin_password*]
#   (Optional) Admin Password for Midonet API
#   Defaults to hiera('admin_password')
#
# [*bind_address*]
#   (Optional) The address to bind Cassandra and Midonet API to
#   Defaults to hiera('neutron::bind_host')
#
# [*keystone_admin_token*]
#   (Optional) The Keystone Admin Token
#   Defaults to hiera('keystone::admin_token')
#
# [*neutron_api_node_ips*]
#   (Optional) The IPs of the Neutron API hosts
#   Defaults to hiera('neutron_api_node_ips')
#
# [*neutron_auth_password*]
#   (Optional) Password to use for Neutron authentication
#   Defaults to hiera('neutron::server::password')
#
# [*neutron_auth_tenant*]
#   (Optional) Tenant to use for Neutron authentication
#   Defaults to hiera('neutron::server::project_name')
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')
#
# [*vip*]
#   (Optional) Public Virtual IP Address for this cloud
#   Defaults to hiera('public_virtual_ip')
#
# [*zk_on_controller*]
#   (Optional) Whether to put zookeeper on the controllers
#   Defaults to hiera('enable_zookeeper_on_controller')
#
# [*zookeeper_client_ip*]
#   (Optional) The IP of the Zookeeper Client
#   Defaults to hiera('neutron::bind_host')
#
# [*zookeeper_hostnames*]
#   (Optional) The IPs of the Zookeeper Servers
#   Defaults to hiera('controller_node_names')
#
class tripleo::profile::base::neutron::midonet (
  $admin_password        = hiera('admin_password', ''),
  $bind_address          = hiera('neutron::bind_host', ''),
  $keystone_admin_token  = hiera('keystone::admin_token', ''),
  $neutron_api_node_ips  = hiera('neutron_api_node_ips', ''),
  $neutron_auth_password = hiera('neutron::keystone::authtoken::password', ''),
  $neutron_auth_tenant   = hiera('neutron::keystone::authtoken::project_name', ''),
  $step                  = Integer(hiera('step')),
  $vip                   = hiera('public_virtual_ip'),
  $zk_on_controller      = hiera('enable_zookeeper_on_controller', ''),
  $zookeeper_client_ip   = hiera('neutron::bind_host', ''),
  $zookeeper_hostnames   = hiera('controller_node_names', ''),
) {
  include ::tripleo::profile::base::neutron
  include ::tripleo::profile::base::neutron::agents::midonet

  if $step >= 4 {

    # Run zookeeper in the controller if configured
    if zk_on_controller {
      class {'::tripleo::cluster::zookeeper':
        zookeeper_server_ips => $neutron_api_node_ips,
        # TODO: create a 'bind' hiera key for zookeeper
        zookeeper_client_ip  => $zookeeper_client_ip,
        zookeeper_hostnames  => split($zookeeper_hostnames, ',')
      }
    }

    # Run cassandra in the controller if configured
    if hiera('enable_cassandra_on_controller') {
      class {'::tripleo::cluster::cassandra':
        cassandra_servers => $neutron_api_node_ips,
        cassandra_ip      => $bind_address,
      }
    }

    class {'::tripleo::network::midonet::api':
      zookeeper_servers    => $neutron_api_node_ips,
      vip                  => $vip,
      keystone_ip          => $vip,
      keystone_admin_token => $keystone_admin_token,
      bind_address         => $bind_address,
      admin_password       => $admin_password,
    }

    class {'::neutron::plugins::midonet':
      midonet_api_ip    => $vip,
      keystone_tenant   => $neutron_auth_tenant,
      keystone_password => $neutron_auth_password
    }
  }
}

#
# Copyright (C) 2015 Midokura SARL
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
# == Class: tripleo::network::midonet::api
#
# Configure the MidoNet API
#
# == Parameters:
#
# [*zookeeper_servers*]
#  (required) List IPs of the zookeeper server cluster. Zookeeper is the
#  backend database where MidoNet stores the virtual network topology.
#  Array of strings value.
#
# [*vip*]
#  (required) Public Virtual IP where the API will be exposed.
#  String (IPv4) value.
#
# [*keystone_ip*]
#  (required) MidoNet API is registered as an OpenStack service. Provide the
#  keystone ip address.
#  String (IPv4) value.
#
# [*keystone_admin_token*]
#  (required) MidoNet API is registered as an OpenStack service. It needs the
#  keystone admin token to perform some admin calls.
#  String value.
#
# [*bind_address*]
#  (required) MidoNet API uses a Tomcat instance to offer the REST service. The
#  ip address where to bind the tomcat service.
#  String (IPv4) value.
#
# [*admin_password*]
#  (required) OpenStack admin user password.
#  String value.
#
# [*keystone_port*]
#  (optional) MidoNet API is registered as an OpenStack service. Provide
#  the keystone port.
#  Defaults to 35357
#
# [*keystone_tenant_name*]
#  (optional) Tenant of the keystone service.
#  Defaults to 'admin'
#
# [*admin_user_name*]
#  (optional) OpenStack admin user name.
#  Defaults to 'admin'
#
# [*admin_tenant_name*]
#  (optional). OpenStack admin tenant name.
#  Defaults to 'admin'
#

class tripleo::network::midonet::api(
  $zookeeper_servers,
  $vip,
  $keystone_ip,
  $keystone_admin_token,
  $bind_address,
  $admin_password,
  $keystone_port         = 35357,
  $keystone_tenant_name  = 'admin',
  $admin_user_name       = 'admin',
  $admin_tenant_name     = 'admin'
)
{

  # TODO: Remove this comment once we can guarantee that all the distros
  # deploying TripleO use Puppet > 3.7 because of this bug:
  # https://tickets.puppetlabs.com/browse/PUP-1299

  # validate_array($zookeeper_servers)
  validate_ip_address($vip)
  validate_ip_address($keystone_ip)
  validate_ip_address($bind_address)

  # Run Tomcat and MidoNet API
  class {'::tomcat':
    install_from_source => false
  } ->

  package {'midonet-api':
    ensure => present
  } ->

  class {'::midonet::midonet_api::run':
    zk_servers           => list_to_zookeeper_hash($zookeeper_servers),
    keystone_auth        => true,
    tomcat_package       => 'tomcat',
    vtep                 => false,
    api_ip               => $vip,
    api_port             => '8081',
    keystone_host        => $keystone_ip,
    keystone_port        => $keystone_port,
    keystone_admin_token => $keystone_admin_token,
    keystone_tenant_name => $keystone_tenant_name,
    catalina_base        => '/usr/share/tomcat',
    bind_address         => $bind_address
  }

  # Configure the CLI
  class {'::midonet::midonet_cli':
    api_endpoint => "http://${vip}:8081/midonet-api",
    username     => $admin_user_name,
    password     => $admin_password,
    tenant_name  => $admin_tenant_name
  }
}

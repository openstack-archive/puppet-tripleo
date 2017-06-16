#
# Copyright (C) 2015 Juniper Networks
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
# == Class: tripleo::network::contrail::webui
#
# Configure Contrail Webui services
#
# == Parameters:
#
# [*admin_password*]
#  (optional) admin password
#  String value.
#  Defaults to hiera('contrail::admin_password')
#
# [*admin_tenant_name*]
#  (optional) admin tenant name.
#  String value.
#  Defaults to hiera('contrail::admin_tenant_name')
#
# [*admin_token*]
#  (optional) admin token
#  String value.
#  Defaults to hiera('contrail::admin_token')
#
# [*admin_user*]
#  (optional) admin user name.
#  String value.
#  Defaults to hiera('contrail::admin_user')
#
# [*auth_host*]
#  (optional) keystone server ip address
#  String (IPv4) value.
#  Defaults to hiera('contrail::auth_host')
#
# [*auth_port_public*]
#  (optional) keystone port.
#  Integer value.
#  Defaults to hiera('contrail::auth_port_public')
#
# [*auth_protocol*]
#  (optional) authentication protocol.
#  String value.
#  Defaults to hiera('contrail::auth_protocol')
#
# [*cert_file*]
#  (optional) cert file name
#  String value.
#  Defaults to hiera('contrail::service_certificate',false)
#
# [*cassandra_server_list*]
#  (optional) List IPs+port of Cassandra servers
#  Array of strings value.
#  Defaults to hiera('contrail::cassandra_server_list')
#
# [*contrail_analytics_vip*]
#  (optional) VIP of Contrail Analytics
#  String (IPv4) value.
#  Defaults to hiera('contrail_analytics_vip',hiera('internal_api_virtual_ip'))
#
# [*contrail_config_vip*]
#  (optional) VIP of Contrail Config
#  String (IPv4) value.
#  Defaults to hiera('contrail_config_vip',hiera('internal_api_virtual_ip'))
#
# [*contrail_webui_http_port*]
#  (optional) Webui HTTP Port
#  Integer value.
#  Defaults to 8080
#
# [*contrail_webui_https_port*]
#  (optional) Webui HTTPS Port
#  Integer value.
#  Defaults to 8143
#
# [*neutron_vip*]
#  (optional) VIP of Neutron
#  String (IPv4) value.
#  Defaults to hiera('internal_api_virtual_ip')
#
# [*redis_ip*]
#  (optional) IP of Redis
#  String (IPv4) value.
#  Defaults to '127.0.0.1'
#
class tripleo::network::contrail::webui(
  $admin_password            = hiera('contrail::admin_password'),
  $admin_tenant_name         = hiera('contrail::admin_tenant_name'),
  $admin_token               = hiera('contrail::admin_token'),
  $admin_user                = hiera('contrail::admin_user'),
  $auth_host                 = hiera('internal_api_virtual_ip'),
  $auth_protocol             = hiera('contrail::auth_protocol'),
  $auth_port_public          = hiera('contrail::auth_port_public'),
  $cassandra_server_list     = hiera('contrail_database_node_ips'),
  $cert_file                 = hiera('contrail::service_certificate',false),
  $contrail_analytics_vip    = hiera('contrail_analytics_vip',hiera('internal_api_virtual_ip')),
  $contrail_config_vip       = hiera('contrail_config_vip',hiera('internal_api_virtual_ip')),
  $contrail_webui_http_port  = hiera('contrail::webui::http_port'),
  $contrail_webui_https_port = hiera('contrail::webui::https_port'),
  $neutron_vip               = hiera('internal_api_virtual_ip'),
  $redis_ip                  = hiera('contrail::webui::redis_ip'),
)
{
  class {'::contrail::webui':
    admin_user                => $admin_user,
    admin_password            => $admin_password,
    admin_token               => $admin_token,
    admin_tenant_name         => $admin_tenant_name,
    auth_port                 => $auth_port_public,
    auth_protocol             => $auth_protocol,
    cassandra_ip              => $cassandra_server_list,
    cert_file                 => $cert_file,
    contrail_config_vip       => $contrail_config_vip,
    contrail_analytics_vip    => $contrail_analytics_vip,
    contrail_webui_http_port  => $contrail_webui_http_port,
    contrail_webui_https_port => $contrail_webui_https_port,
    neutron_vip               => $neutron_vip,
    openstack_vip             => $auth_host,
    redis_ip                  => $redis_ip,
  }
}

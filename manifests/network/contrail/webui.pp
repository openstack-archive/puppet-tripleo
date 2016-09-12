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
# [*contrail_analytics_vip*]
#  (required) VIP of Contrail Analytics
#  String (IPv4) value.
#
# [*contrail_config_vip*]
#  (required) VIP of Contrail Config
#  String (IPv4) value.
#
# [*neutron_vip*]
#  (required) VIP of Neutron
#  String (IPv4) value.
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
# [*cassandra_server_list*]
#  (optional) List IPs+port of Cassandra servers
#  Array of strings value.
#  Defaults to hiera('contrail::cassandra_server_list')
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
# [*redis_ip*]
#  (optional) IP of Redis
#  String (IPv4) value.
#  Defaults to '127.0.0.1'
#
class tripleo::network::contrail::webui(
  $contrail_analytics_vip,
  $contrail_config_vip,
  $neutron_vip,
  $admin_password = hiera('contrail::admin_password'),
  $admin_tenant_name = hiera('contrail::admin_tenant_name'),
  $admin_token = hiera('contrail::admin_token'),
  $admin_user = hiera('contrail::admin_user'),
  $auth_host = hiera('contrail::auth_host'),
  $cassandra_server_list = hiera('contrail::cassandra_server_list'),
  $contrail_webui_http_port = 8080,
  $contrail_webui_https_port = 8143,
  $redis_ip = '127.0.0.1',
)
{
  class {'::contrail::webui':
    openstack_vip             => $auth_host,
    contrail_config_vip       => $contrail_config_vip,
    contrail_analytics_vip    => $contrail_analytics_vip,
    neutron_vip               => $neutron_vip,
    cassandra_ip              => $cassandra_server_list,
    redis_ip                  => $redis_ip,
    contrail_webui_http_port  => $contrail_webui_http_port,
    contrail_webui_https_port => $contrail_webui_https_port,
    admin_user                => $admin_user,
    admin_password            => $admin_password,
    admin_token               => $admin_token,
    admin_tenant_name         => $admin_tenant_name,
  }
}

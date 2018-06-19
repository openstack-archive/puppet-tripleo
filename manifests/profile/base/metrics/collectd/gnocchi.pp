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
# == Define: tripleo::profile::base::metrics::collectd::gnocchi
#
# This is used to create configuration file for collectd-gnocchi plugin
#
# === Parameters
#
# [*ensure*]
#   (Optional) String. Action to perform with gnocchi plugin
#   configuration file.
#   Defaults to 'present'
#
# [*order*]
#   (Optional) String. Prefix for gnocchi plugin configuration file.
#   Defaults to '00'
#
# [*auth_mode*]
#   (Optional) String. Type of authentication Gnocchi server is using.
#   Supported values are 'basic' and 'keystone'.
#   Defaults to 'basic'
#
# [*protocol*]
#   (Optional) String. API protocol Gnocchi server is using.
#   Defaults to 'http'
#
# [*server*]
#   (Optional) String. The name or address of a gnocchi endpoint to
#   which we should send metrics.
#   Defaults to undef
#
# [*port*]
#   (Optional) Integer. The port to which we will connect on the
#   Gnocchi server.
#   Defaults to 8041
#
# [*user*]
#   (Optional) String. Username for authenticating to the remote
#   Gnocchi server using simple authentication.
#   Defaults to undef
#
# [*keystone_auth_url*]
#   (Optional) String. Keystone endpoint URL to authenticate to.
#   Defaults to undef
#
# [*keystone_user_name*]
#   (Optional) String. Username for authenticating to Keystone.
#   Defaults to undef
#
# [*keystone_user_id*]
#   (Optional) String. User ID for authenticating to Keystone.
#   Defaults to undef
#
# [*keystone_password*]
#   (Optional) String. Password for authenticating to Keystone
#   Defaults to undef
#
# [*keystone_project_id*]
#   (Optional) String. Project ID for authenticating to Keystone.
#   Defaults to undef
#
# [*keystone_project_name*]
#   (Optional) String. Project name for authenticating to Keystone.
#   Defaults to undef
#
# [*keystone_user_domain_id*]
#   (Optional) String. User domain ID for authenticating to Keystone.
#   Defaults to undef
#
# [*keystone_user_domain_name*]
#   (Optional) String. User domain name for authenticating to Keystone.
#   Defaults to undef
#
# [*keystone_project_domain_id*]
#   (Optional) String. Project domain ID for authenticating to Keystone.
#   Defaults to undef
#
# [*keystone_project_domain_name*]
#   (Optional) String. Project domain name for authenticating to Keystone.
#   Defaults to undef
#
# [*keystone_region_name*]
#   (Optional) String. Region name for authenticating to Keystone.
#   Defaults to undef
#
# [*keystone_interface*]
#   (Optional) String. Type of Keystone endpoint to authenticate to.
#   Defaults to undef
#
# [*keystone_endpoint*]
#   (Optional) String. Explicitly state Gnocchi server URL if you want
#   to override Keystone value
#   Defaults to undef
#
# [*resource_type*]
#   (Optional) String. Default resource type created by the collectd-gnocchi
#   plugin in Gnocchi to store hosts.
#   Defaults to 'collectd'
#
# [*batch_size*]
#   (Optional) String. Minimum number of values Gnocchi should batch.
#   Defaults to 10
#
define tripleo::profile::base::metrics::collectd::gnocchi (
  $ensure                       = 'present',
  $order                        = '00',
  $auth_mode                    = 'basic',
  $protocol                     = 'http',
  $server                       = undef,
  $port                         = undef,
  $user                         = undef,
  $keystone_auth_url            = undef,
  $keystone_user_name           = undef,
  $keystone_user_id             = undef,
  $keystone_password            = undef,
  $keystone_project_id          = undef,
  $keystone_project_name        = undef,
  $keystone_user_domain_id      = undef,
  $keystone_user_domain_name    = undef,
  $keystone_project_domain_id   = undef,
  $keystone_project_domain_name = undef,
  $keystone_region_name         = undef,
  $keystone_interface           = undef,
  $keystone_endpoint            = undef,
  $resource_type                = 'collectd',
  $batch_size                   = 10,
) {
  include ::collectd

  package { ['python-collectd-gnocchi', 'collectd-python']:
    ensure => $ensure,
  }

  collectd::plugin { 'python':
    ensure  => $ensure,
    order   => $order,
    content => template('tripleo/collectd/collectd-gnocchi.conf.erb'),
    require => Package['python-collectd-gnocchi']
  }
}

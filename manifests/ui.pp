# Copyright 2016 Red Hat, Inc.
# All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# == Class: tripleo::ui
#
# Configure TripleO UI.
#
# === Parameters:
#
# [*servername*]
#  The servername for the virtualhost.
#  Optional. Defaults to $::fqdn
#
# [*bind_host*]
#  The host/ip address Apache will listen on.
#  Optional. Defaults to undef (listen on all ip addresses).
#
# [*ui_port*]
#  The port on which the UI is listening.
#  Defaults to 3000
#
# [*keystone_url*]
#  The keystone service url
#  Defaults to hiera('keystone::endpoint::public_url')
#
# [*heat_url*]
#  The heat service url
#  Defaults to hiera('heat::keystone::auth::public_url')
#
# [*heat_url*]
#  The heat service url
#  Defaults to hiera('heat::keystone::auth::public_url')
#
# [*heat_url*]
#  The heat service url
#  Defaults to hiera('heat::keystone::auth::public_url')
#
# [*ironic_url*]
#  The ironic service url
#  Defaults to hiera('ironic::keystone::auth::public_url')
#
# [*mistral_url*]
#  The mistral service url
#  Defaults to hiera('mistral::keystone::auth::public_url')
#
# [*swift_url*]
#  The swift service url
#  Defaults to hiera('swift::keystone::auth::public_url')
#
# [*zaqar_websocket_url*]
#  The zaqar websocket url
#  Defaults to hiera('zaquar::keystone::auth_websocket::public_url')
#
# [*zaqar_default_queue*]
#  The zaqar default queue
#  A string.
#  Defaults to 'tripleo'
#
class tripleo::ui (
  $servername          = $::fqdn,
  $bind_host           = hiera('controller_host'),
  $ui_port             = 3000,
  $keystone_url        = hiera('keystone_auth_uri_v2'),
  $heat_url            = hiera('heat::keystone::auth::public_url', undef),
  $ironic_url          = hiera('ironic::keystone::auth::public_url', undef),
  $mistral_url         = hiera('mistral::keystone::auth::public_url', undef),
  $swift_url           = hiera('swift::keystone::auth::public_url', undef),
  $zaqar_websocket_url = hiera('zaqar::keystone::auth_websocket::public_url', undef),
  $zaqar_default_queue = 'tripleo'
) {

  ::apache::vhost { 'tripleo-ui':
    ensure           => 'present',
    servername       => $servername,
    ip               => $bind_host,
    port             => $ui_port,
    docroot          => '/var/www/openstack-tripleo-ui/dist',
    options          => ['Indexes', 'FollowSymLinks'],
    fallbackresource => '/index.html',
  }

  # We already use apache::vhost to generate our own
  # configuration file, let's clean the configuration
  # embedded within the package
  file { "${apache::confd_dir}/openstack-tripleo-ui.conf" :
    ensure  => present,
    content => "#
# This file has been cleaned by Puppet.
#
# OpenStack TripleO UI configuration has been moved to:
# - 25-tripleo-ui.conf
#",
    require => Package['openstack-tripleo-ui'],
    before  => Service[$::apache::params::service_name],
  }

  file { '/var/www/openstack-tripleo-ui/dist/tripleo_ui_config.js' :
    ensure  => file,
    content => template('tripleo/ui/tripleo_ui_config.js.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

}

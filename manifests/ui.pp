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
  $bind_host           = undef,
  $ui_port             = 3000,
  $keystone_url        = hiera('keystone::endpoint::public_url'),
  $heat_url            = hiera('heat::keystone::auth::public_url', undef),
  $ironic_url          = hiera('ironic::keystone::auth::public_url', undef),
  $mistral_url         = hiera('mistral::keystone::auth::public_url', undef),
  $swift_url           = hiera('swift::keystone::auth::public_url', undef),
  $zaqar_websocket_url = hiera('zaqar::keystone::auth_websocket::public_url', undef),
  $zaqar_default_queue = 'tripleo'
) {

  ::apache::vhost { 'tripleo-ui':
    ensure     => 'present',
    servername => $servername,
    ip         => $bind_host,
    port       => $ui_port,
    docroot    => '/var/www/openstack-tripleo-ui/dist',
    options    => ['Indexes', 'FollowSymLinks'],
    rewrites   => [
      {
        comment      => 'Redirect 404 to index',
        rewrite_cond => ['%{REQUEST_FILENAME} !-f', '%{REQUEST_FILENAME} !-d'],
        rewrite_rule => ['(.*) index.html'],
      },
    ],
  }

  file { '/var/www/openstack-tripleo-ui/dist/tripleo_ui_config.js' :
    ensure  => file,
    content => template('tripleo/ui/tripleo_ui_config.js.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

}

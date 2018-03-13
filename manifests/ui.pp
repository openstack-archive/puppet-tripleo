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
#  Optional. Defaults to hiera('controller_host')
#
# [*ui_port*]
#  The port on which the UI is listening.
#  Defaults to 3000
#
# [*excluded_languages*]
#  A list of languages that shouldn't be enabled in the UI, e.g. ['en', 'de']
#  Defaults to []
#
# [*endpoint_proxy_keystone*]
#  The keystone proxy endpoint url
#  Defaults to undef
#
# [*endpoint_config_keystone*]
#  The keystone config endpoint url
#  Defaults to undef
#
# [*endpoint_proxy_heat*]
#  The heat proxy endpoint url
#  Defaults to undef
#
# [*endpoint_config_heat*]
#  The heat config endpoint url
#  Defaults to undef
#
# [*endpoint_proxy_ironic*]
#  The ironic proxy endpoint url
#  Defaults to undef
#
# [*endpoint_proxy_ironic_inspector*]
#  The ironic inspector proxy endpoint url
#  Defaults to undef
#
# [*endpoint_config_ironic*]
#  The ironic config endpoint url
#  Defaults to undef
#
# [*endpoint_config_ironic_inspector*]
#  The ironic inspector config endpoint url
#  Defaults to undef
#
# [*endpoint_proxy_mistral*]
#  The mistral proxy endpoint url
#  Defaults to undef
#
# [*endpoint_proxy_nova*]
#  The nova proxy endpoint url
#  Defaults to undef
#
# [*endpoint_config_mistral*]
#  The mistral config endpoint url
#  Defaults to undef
#
# [*endpoint_config_nova*]
#  The nova config endpoint url
#  Defaults to undef
#
# [*endpoint_proxy_swift*]
#  The swift proxy endpoint url
#  Defaults to undef
#
# [*endpoint_config_swift*]
#  The swift config endpoint url
#  Defaults to undef
#
# [*endpoint_proxy_zaqar*]
#  The zaqar proxy endpoint url
#  Defaults to undef
#
# [*endpoint_config_zaqar*]
#  The zaqar config endpoint url
#  Defaults to undf
#
# [*zaqar_default_queue*]
#  The zaqar default queue
#  A string.
#  Defaults to 'tripleo'
#
# [*enabled_loggers*]
#  List of enabled loggers
#  Defaults to ['console', 'zaqar']
#
class tripleo::ui (
  $servername                       = $::fqdn,
  $bind_host                        = hiera('controller_host'),
  $ui_port                          = 3000,
  $zaqar_default_queue              = 'tripleo',
  $excluded_languages               = [],
  $endpoint_proxy_zaqar             = undef,
  $endpoint_proxy_keystone          = undef,
  $endpoint_proxy_heat              = undef,
  $endpoint_proxy_ironic            = undef,
  $endpoint_proxy_ironic_inspector  = undef,
  $endpoint_proxy_mistral           = undef,
  $endpoint_proxy_nova              = undef,
  $endpoint_proxy_swift             = undef,
  $endpoint_config_zaqar            = undef,
  $endpoint_config_keystone         = undef,
  $endpoint_config_heat             = undef,
  $endpoint_config_ironic           = undef,
  $endpoint_config_ironic_inspector = undef,
  $endpoint_config_mistral          = undef,
  $endpoint_config_nova             = undef,
  $endpoint_config_swift            = undef,
  $enabled_loggers                  = ['console', 'zaqar'],

) {
  package {'openstack-tripleo-ui': }

  include ::apache
  include ::apache::mod::proxy
  include ::apache::mod::proxy_http
  include ::apache::mod::proxy_wstunnel

  ::apache::vhost { 'tripleo-ui':
    ensure           => 'present',
    require          => Package['openstack-tripleo-ui'],
    servername       => $servername,
    ip               => $bind_host,
    port             => $ui_port,
    docroot          => '/var/www/openstack-tripleo-ui/dist',
    options          => ['Indexes', 'FollowSymLinks'],
    fallbackresource => '/index.html',
    proxy_pass       => [
    {
      'path' => '/zaqar',
      'url'  => $endpoint_proxy_zaqar
    },
    {
      'path'         => '/keystone',
      'url'          => $endpoint_proxy_keystone,
      'reverse_urls' => $endpoint_proxy_keystone
    },
    {
      'path'         => '/heat',
      'url'          => $endpoint_proxy_heat,
      'reverse_urls' => $endpoint_proxy_heat
    },
    {
      'path'         => '/ironic',
      'url'          => $endpoint_proxy_ironic,
      'reverse_urls' => $endpoint_proxy_ironic
    },
    {
      'path'         => '/ironic-inspector',
      'url'          => $endpoint_proxy_ironic_inspector,
      'reverse_urls' => $endpoint_proxy_ironic_inspector
    },
    {
      'path'         => '/mistral',
      'url'          => $endpoint_proxy_mistral,
      'reverse_urls' => $endpoint_proxy_mistral
    },
    {
      'path'         => '/nova',
      'url'          => $endpoint_proxy_nova,
      'reverse_urls' => $endpoint_proxy_nova
    },
    {
      'path'         => '/swift',
      'url'          => $endpoint_proxy_swift,
      'reverse_urls' => $endpoint_proxy_swift
    },
    ],

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

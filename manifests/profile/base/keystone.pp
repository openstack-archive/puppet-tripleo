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
# == Class: tripleo::profile::base::keystone
#
# Keystone profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('bootstrap_nodeid')
#
# [*manage_db_purge*]
#   (Optional) Whether keystone token flushing should be enabled
#   Defaults to hiera('keystone_enable_db_purge', true)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*rabbit_hosts*]
#   list of the rabbbit host IPs
#   Defaults to hiera('rabbitmq_node_ips')
#
# [*rabbit_port*]
#   IP port for rabbitmq service
#   Defaults to hiera('keystone::rabbit_port', 5672)
#
# [*heat_admin_domain*]
#   domain name for heat admin
#   Defaults to undef
#
# [*heat_admin_user*]
#   heat admin user name
#   Defaults to undef
#
# [*heat_admin_email*]
#   heat admin email address
#   Defaults to undef
#
# [*heat_admin_password*]
#   heat admin password
#   Defaults to undef
#
class tripleo::profile::base::keystone (
  $bootstrap_node      = hiera('bootstrap_nodeid', undef),
  $manage_db_purge     = hiera('keystone_enable_db_purge', true),
  $step                = hiera('step'),
  $rabbit_hosts        = hiera('rabbitmq_node_ips', undef),
  $rabbit_port         = hiera('keystone::rabbit_port', 5672),
  $heat_admin_domain             = undef,
  $heat_admin_user               = undef,
  $heat_admin_email              = undef,
  $heat_admin_password           = undef,
) {
  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
    $manage_roles = true
    $manage_endpoint = true
    $manage_domain = true
  } else {
    $sync_db = false
    $manage_roles = false
    $manage_endpoint = false
    $manage_domain = false
  }

  if $step >= 4 or ( $step >= 3 and $sync_db ) {
    $rabbit_endpoints = suffix(any2array(normalize_ip_for_uri($rabbit_hosts)), ":${rabbit_port}")
    class { '::keystone':
      sync_db          => $sync_db,
      enable_bootstrap => $sync_db,
      rabbit_hosts     => $rabbit_endpoints,
    }

    include ::keystone::config
    include ::keystone::wsgi::apache
    include ::tripleo::profile::base::apache
    include ::keystone::cors

    if $manage_roles {
      include ::keystone::roles::admin
    }

    if $manage_endpoint {
      include ::keystone::endpoint
    }

  }

  if $step >= 5 and $manage_db_purge {
    include ::keystone::cron::token_flush
  }

  if $step >= 5 and $manage_domain {
    if hiera('heat_engine_enabled', false) {
      # create these seperate and don't use ::heat::keystone::domain since
      # that class writes out the configs
      keystone_domain { $heat_admin_domain:
        ensure  => 'present',
        enabled => true
      }
      keystone_user { "${heat_admin_user}::${heat_admin_domain}":
        ensure   => 'present',
        enabled  => true,
        email    => $heat_admin_email,
        password => $heat_admin_password
      }
      keystone_user_role { "${heat_admin_user}::${heat_admin_domain}@::${heat_admin_domain}":
        roles   => ['admin'],
        require => Class['::keystone::roles::admin']
      }
    }
  }

  if $step >= 5 and $manage_endpoint{
    if hiera('aodh_api_enabled', false) {
      include ::aodh::keystone::auth
    }
    if hiera('ceilometer_api_enabled', false) {
      include ::ceilometer::keystone::auth
    }
    if hiera('ceph_rgw_enabled', false) {
      include ::ceph::rgw::keystone::auth
    }
    if hiera('cinder_api_enabled', false) {
      include ::cinder::keystone::auth
    }
    if hiera('glance_api_enabled', false) {
      include ::glance::keystone::auth
    }
    if hiera('gnocchi_api_enabled', false) {
      include ::gnocchi::keystone::auth
    }
    if hiera('heat_api_enabled', false) {
      include ::heat::keystone::auth
    }
    if hiera('heat_api_cfn_enabled', false) {
      include ::heat::keystone::auth_cfn
    }
    if hiera('ironic_api_enabled', false) {
      include ::ironic::keystone::auth
    }
    if hiera('manila_api_enabled', false) {
      include ::manila::keystone::auth
    }
    if hiera('mistral_api_enabled', false) {
      include ::mistral::keystone::auth
    }
    if hiera('neutron_api_enabled', false) {
      include ::neutron::keystone::auth
    }
    if hiera('nova_api_enabled', false) {
      include ::nova::keystone::auth
    }
    if hiera('sahara_api_enabled', false) {
      include ::sahara::keystone::auth
    }
    if hiera('swift_proxy_enabled', false) {
      include ::swift::keystone::auth
    }
    if hiera('trove_api_enabled', false) {
      include ::trove::keystone::auth
    }
  }
}


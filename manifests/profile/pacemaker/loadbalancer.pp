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
# == Class: tripleo::profile::pacemaker::loadbalancer
#
# Loadbalancer Pacemaker HA profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('bootstrap_nodeid')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*enable_load_balancer*]
#   (Optional) Whether load balancing is enabled for this cluster
#   Defaults to hiera('enable_load_balancer', true)
#
class tripleo::profile::pacemaker::loadbalancer (
  $bootstrap_node       = hiera('bootstrap_nodeid'),
  $step                 = hiera('step'),
  $enable_load_balancer = hiera('enable_load_balancer', true)
) {

  include ::tripleo::profile::base::loadbalancer

  if $::hostname == downcase($bootstrap_node) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  if $step >= 2 and $pacemaker_master and $enable_load_balancer {
      # FIXME: we should not have to access tripleo::haproxy class
      # parameters here to configure pacemaker VIPs. The configuration
      # of pacemaker VIPs could move into puppet-tripleo or we should
      # make use of less specific hiera parameters here for the settings.
      pacemaker::resource::service { 'haproxy':
        clone_params => true,
      }

      # TODO(emilien): clean-up old parameter references when
      # https://review.openstack.org/#/c/320411/ is merged.
      if hiera('tripleo::loadbalancer::controller_virtual_ip', undef) {
        $control_vip_real = hiera('tripleo::loadbalancer::controller_virtual_ip')
      } else {
        $control_vip_real = hiera('controller_virtual_ip')
      }
      tripleo::pacemaker::haproxy_with_vip { 'haproxy_and_control_vip':
        vip_name   => 'control',
        ip_address => $control_vip_real,
      }

      if hiera('tripleo::loadbalancer::public_virtual_ip', undef) {
        $public_vip_real = hiera('tripleo::loadbalancer::public_virtual_ip')
      } else {
        $public_vip_real = hiera('public_virtual_ip')
      }
      tripleo::pacemaker::haproxy_with_vip { 'haproxy_and_public_vip':
        ensure     => $public_vip_real and $public_vip_real != $control_vip_real,
        vip_name   => 'public',
        ip_address => $public_vip_real,
      }

      $redis_vip = hiera('redis_vip')
      tripleo::pacemaker::haproxy_with_vip { 'haproxy_and_redis_vip':
        ensure     => $redis_vip and $redis_vip != $control_vip_real,
        vip_name   => 'redis',
        ip_address => $redis_vip,
      }

      if hiera('tripleo::loadbalancer::internal_api_virtual_ip', undef) {
        $internal_api_vip_real = hiera('tripleo::loadbalancer::internal_api_virtual_ip')
      } else {
        $internal_api_vip_real = hiera('internal_api_virtual_ip')
      }
      tripleo::pacemaker::haproxy_with_vip { 'haproxy_and_internal_api_vip':
        ensure     => $internal_api_vip_real and $internal_api_vip_real != $control_vip_real,
        vip_name   => 'internal_api',
        ip_address => $internal_api_vip_real,
      }

      if hiera('tripleo::loadbalancer::storage_virtual_ip', undef) {
        $storage_vip_real = hiera('tripleo::loadbalancer::storage_virtual_ip')
      } else {
        $storage_vip_real = hiera('storage_virtual_ip')
      }
      tripleo::pacemaker::haproxy_with_vip { 'haproxy_and_storage_vip':
        ensure     => $storage_vip_real and $storage_vip_real != $control_vip_real,
        vip_name   => 'storage',
        ip_address => $storage_vip_real,
      }

      if hiera('tripleo::loadbalancer::storage_mgmt_virtual_ip', undef) {
        $storage_mgmt_vip_real = hiera('tripleo::loadbalancer::storage_mgmt_virtual_ip')
      } else {
        $storage_mgmt_vip_real = hiera('storage_mgmt_virtual_ip')
      }
      tripleo::pacemaker::haproxy_with_vip { 'haproxy_and_storage_mgmt_vip':
        ensure     => $storage_mgmt_vip_real and $storage_mgmt_vip_real != $control_vip_real,
        vip_name   => 'storage_mgmt',
        ip_address => $storage_mgmt_vip_real,
      }
  }

}

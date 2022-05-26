# Copyright 2020 Red Hat, Inc.
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
# == Class: tripleo::profile::base::glance::backend::rbd
#
# Glance API rbd backend configuration for tripleo
#
# === Parameters
#
# [*backend_names*]
#   Array of rbd store backend names.
#
# [*multistore_config*]
#   (Optional) Hash containing multistore data for configuring multiple backends.
#   Defaults to {}
#
# [*rbd_store_ceph_conf*]
#   (Optional) Ceph cluster config file.
#   Defaults to lookup('glance::backend::rbd::rbd_store_ceph_conf', undef, undef, '/etc/ceph/ceph.conf').
#
# [*rbd_store_user*]
#   (Optional) Ceph client username.
#   Defaults to lookup('glance::backend::rbd::rbd_store_user', undef, undef, 'openstack').
#
# [*rbd_store_pool*]
#   (Optional) Ceph pool for storing images.
#   Defaults to lookup('glance::backend::rbd::rbd_store_pool', undef, undef, 'images').
#
# [*rbd_store_chunk_size*]
#   (Optional) RBD chunk size.
#   Defaults to lookup('glance::backend::rbd::rbd_store_chunk_size', undef, undef, undef).
#
# [*rbd_thin_provisioning*]
#   (Optional) Boolean describing if thin provisioning is enabled or not
#   Defaults to lookup('glance::backend::rbd::rbd_thin_provisioning', undef, undef, undef).
#
# [*rados_connect_timeout*]
#   (Optional) RADOS connection timeout.
#   Defaults to lookup('glance::backend::rbd::rados_connect_timeout', undef, undef, undef).
#
# [*store_description*]
#   (Optional) Provides constructive information about the store backend to
#   end users.
#   Defaults to lookup('tripleo::profile::base::glance::api::glance_store_description', undef, undef, 'RBD store').
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
class tripleo::profile::base::glance::backend::rbd (
  $backend_names,
  $multistore_config     = {},
  $rbd_store_ceph_conf   = lookup('glance::backend::rbd::rbd_store_ceph_conf', undef, undef, '/etc/ceph/ceph.conf'),
  $rbd_store_user        = lookup('glance::backend::rbd::rbd_store_user', undef, undef, 'openstack'),
  $rbd_store_pool        = lookup('glance::backend::rbd::rbd_store_pool', undef, undef, 'images'),
  $rbd_store_chunk_size  = lookup('glance::backend::rbd::rbd_store_chunk_size', undef, undef, undef),
  $rbd_thin_provisioning = lookup('glance::backend::rbd::rbd_thin_provisioning', undef, undef, undef),
  $rados_connect_timeout = lookup('glance::backend::rbd::rados_connect_timeout', undef, undef, undef),
  $store_description     = lookup('tripleo::profile::base::glance::api::glance_store_description', undef, undef, 'RBD store'),
  $step                  = Integer(lookup('step')),
) {

  if $step >= 4 {
    $backend_names.each |String $backend_name| {
      $backend_config = pick($multistore_config[$backend_name], {})

      $rbd_store_user_real = pick($backend_config['CephClientUserName'], $rbd_store_user)
      $rbd_store_pool_real = pick($backend_config['GlanceRbdPoolName'], $rbd_store_pool)
      $store_description_real = pick($backend_config['GlanceStoreDescription'], $store_description)

      $ceph_cluster_name = $backend_config['CephClusterName']

      if $ceph_cluster_name {
        $rbd_store_ceph_conf_real = "/etc/ceph/${ceph_cluster_name}.conf"
      } else {
        $rbd_store_ceph_conf_real = $rbd_store_ceph_conf
      }

      create_resources('glance::backend::multistore::rbd', { $backend_name => delete_undef_values({
        'rbd_store_ceph_conf'   => $rbd_store_ceph_conf_real,
        'rbd_store_user'        => $rbd_store_user_real,
        'rbd_store_pool'        => $rbd_store_pool_real,
        'rbd_store_chunk_size'  => $rbd_store_chunk_size,
        'rbd_thin_provisioning' => $rbd_thin_provisioning,
        'rados_connect_timeout' => $rados_connect_timeout,
        'store_description'     => $store_description_real,
      })})
    }
  }
}

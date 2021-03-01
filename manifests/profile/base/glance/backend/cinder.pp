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
# == Class: tripleo::profile::base::glance::backend::cinder
#
# Glance API cinder backend configuration for tripleo
#
# === Parameters
#
# [*backend_names*]
#   Array of cinder store backend names.
#
# [*multistore_config*]
#   (Optional) Hash containing multistore data for configuring multiple backends.
#   Defaults to {}
#
# [*cinder_ca_certificates_file*]
#   (Optional) Location of ca certicate file to use for cinder client requests.
#   Defaults to hiera('glance::backend::cinder::cinder_ca_certificates_file', undef).
#
# [*cinder_api_insecure*]
#   (Optional) Allow to perform insecure SSL requests to cinder.
#   Defaults to hiera('glance::backend::cinder::cinder_api_insecure', undef).
#
# [*cinder_catalog_info*]
#   (Optional) Info to match when looking for cinder in the service catalog.
#   Defaults to hiera('glance::backend::cinder::cinder_catalog_info', undef).
#
# [*cinder_endpoint_template*]
#   (Optional) Override service catalog lookup with template for cinder endpoint.
#   Defaults to hiera('glance::backend::cinder::cinder_endpoint_template', undef).
#
# [*cinder_http_retries*]
#   (Optional) Number of cinderclient retries on failed http calls.
#   Defaults to hiera('glance::backend::cinder::cinder_http_retries', undef).
#
# [*cinder_store_auth_address*]
#   (Optional) A valid authentication service address.
#   Defaults to hiera('glance::backend::cinder::cinder_store_auth_address', undef).
#
# [*cinder_store_project_name*]
#   (Optional) Project name where the image volume is stored in cinder.
#   Defaults to hiera('glance::backend::cinder::cinder_store_project_name', undef).
#
# [*cinder_store_user_name*]
#   (Optional) User name to authenticate against cinder.
#   Defaults to hiera('glance::backend::cinder::cinder_store_user_name', undef)
#
# [*cinder_store_password*]
#   (Optional) A valid password for the user specified by `cinder_store_user_name'
#   Defaults to hiera('glance::backend::cinder::cinder_store_password', undef)
#
# [*cinder_enforce_multipath*]
#   (Optional) Set to True when multipathd is enabled
#   Defaults to hiera('glance::backend::cinder::cinder_enforce_multipath', undef)
#
# [*cinder_use_multipath*]
#   (Optional) Set to True when multipathd is enabled
#   Defaults to hiera('glance::backend::cinder::cinder_use_multipath', undef)
#
# [*cinder_mount_point_base*]
#   (Optional) Directory where the NFS volume is mounted on the glance node.
#   Defaults to hiera('glance::backend::cinder::cinder_mount_point_base', undef)
#
# [*store_description*]
#   (Optional) Provides constructive information about the store backend to
#   end users.
#   Defaults to hiera('tripleo::profile::base::glance::api::glance_store_description', 'Cinder store').
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::glance::backend::cinder (
  $backend_names,
  $multistore_config           = {},
  $cinder_ca_certificates_file = hiera('glance::backend::cinder::cinder_ca_certificates_file', undef),
  $cinder_api_insecure         = hiera('glance::backend::cinder::cinder_api_insecure', undef),
  $cinder_catalog_info         = hiera('glance::backend::cinder::cinder_catalog_info', undef),
  $cinder_endpoint_template    = hiera('glance::backend::cinder::cinder_endpoint_template', undef),
  $cinder_http_retries         = hiera('glance::backend::cinder::cinder_http_retries', undef),
  $cinder_store_auth_address   = hiera('glance::backend::cinder::cinder_store_auth_address', undef),
  $cinder_store_project_name   = hiera('glance::backend::cinder::cinder_store_project_name', undef),
  $cinder_store_user_name      = hiera('glance::backend::cinder::cinder_store_user_name', undef),
  $cinder_store_password       = hiera('glance::backend::cinder::cinder_store_password', undef),
  $cinder_enforce_multipath    = hiera('glance::backend::cinder::cinder_enforce_multipath', undef),
  $cinder_use_multipath        = hiera('glance::backend::cinder::cinder_use_multipath', undef),
  $cinder_mount_point_base     = hiera('glance::backend::cinder::cinder_mount_point_base', undef),
  $store_description           = hiera('tripleo::profile::base::glance::api::glance_store_description', 'Cinder store'),
  $step                        = Integer(hiera('step')),
) {

  if $backend_names.length() > 1 {
    fail('Multiple cinder backends are not supported.')
  }

  if $step >= 4 {
    $backend_name = $backend_names[0]

    $multistore_description = pick($multistore_config[$backend_name], {})['GlanceStoreDescription']
    $store_description_real = pick($multistore_description, $store_description)

    glance::backend::multistore::cinder { $backend_name:
      cinder_api_insecure         => $cinder_api_insecure,
      cinder_catalog_info         => $cinder_catalog_info,
      cinder_http_retries         => $cinder_http_retries,
      cinder_endpoint_template    => $cinder_endpoint_template,
      cinder_ca_certificates_file => $cinder_ca_certificates_file,
      cinder_store_auth_address   => $cinder_store_auth_address,
      cinder_store_project_name   => $cinder_store_project_name,
      cinder_store_user_name      => $cinder_store_user_name,
      cinder_store_password       => $cinder_store_password,
      cinder_enforce_multipath    => $cinder_enforce_multipath,
      cinder_use_multipath        => $cinder_use_multipath,
      cinder_mount_point_base     => $cinder_mount_point_base,
      store_description           => $store_description_real,
    }
  }
}

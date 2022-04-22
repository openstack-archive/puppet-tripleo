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
# == Class: tripleo::profile::base::glance::backend::swift
#
# Glance API swift backend configuration for tripleo
#
# === Parameters
#
# [*backend_names*]
#   Array of swift store backend names.
#
# [*multistore_config*]
#   (Optional) Hash containing multistore data for configuring multiple backends.
#   Defaults to {}
#
#  [*swift_store_user*]
#    (Optional) Swift store user.
#    Defaults to lookup('glance::backend::swift::swift_store_user').
#
#  [*swift_store_key*]
#    (Optional) Swift store key.
#    Defaults to lookup('glance::backend::swift::swift_store_key').
#
#  [*swift_store_container*]
#    (Optional) Swift store container.
#    Defaults to lookup('glance::backend::swift::swift_store_container', undef, undef, undef).
#
#  [*swift_store_auth_address*]
#    (Optional) Swift store auth address.
#    Defaults to lookup('glance::backend::swift::swift_store_auth_address', undef, undef, undef).
#
#  [*swift_store_auth_version*]
#    (Optional) Swift store auth version.
#    Defaults to lookup('glance::backend::swift::swift_store_auth_version', undef, undef, undef).
#
#  [*swift_store_auth_project_domain_id*]
#    (Optional) Useful when keystone auth is version 3.
#    Defaults to lookup('glance::backend::swift::swift_store_auth_project_domain_id', undef, undef, undef).
#
#  [*swift_store_auth_user_domain_id*]
#    (Optional) Useful when keystone auth is version 3.
#    Defaults to lookup('glance::backend::swift::swift_store_auth_user_domain_id', undef, undef, undef).
#
#  [*swift_store_large_object_size*]
#    (Optional) What size, in MB, should Glance start chunking image files
#    and do a large object manifest in Swift?
#    Defaults to lookup('glance::backend::swift::swift_store_large_object_size', undef, undef, undef).
#
#  [*swift_store_large_object_chunk_size*]
#    (Optional) When doing a large object manifest, what size, in MB, should
#    Glance write chunks to Swift? This amount of data is written
#    to a temporary disk buffer during the process of chunking.
#    Defaults to lookup('glance::backend::swift::swift_store_large_object_chunk_size', undef, undef, undef).
#
#  [*swift_store_create_container_on_put*]
#    (Optional) Whether to create the swift container if it's missing.
#    Defaults to  lookup('glance::backend::swift::swift_store_create_container_on_put', undef, undef, undef).
#
#  [*swift_store_endpoint_type*]
#    (Optional) Swift store endpoint type.
#    Defaults to lookup('glance::backend::swift::swift_store_endpoint_type', undef, undef, undef).
#
#  [*swift_store_region*]
#    (Optional) Swift store region.
#    Defaults to lookup('glance::backend::swift::swift_store_region', undef, undef, undef).
#
#  [*default_swift_reference*]
#    (Optional) The reference to the default swift
#    account/backing store parameters to use for adding
#    new images.
#    Defaults to ref1.
#
# [*store_description*]
#   (Optional) Provides constructive information about the store backend to
#   end users.
#   Defaults to lookup('tripleo::profile::base::glance::api::glance_store_description', undef, undef, 'Swift store').
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
# DEPRECATED PARAMETERS
#
#  [*swift_store_config_file*]
#    (Optional)
#    Defaults to undef.
#
class tripleo::profile::base::glance::backend::swift (
  $backend_names,
  $multistore_config                   = {},
  $swift_store_user                    = lookup('glance::backend::swift::swift_store_user'),
  $swift_store_key                     = lookup('glance::backend::swift::swift_store_key'),
  $swift_store_container               = lookup('glance::backend::swift::swift_store_container', undef, undef, undef),
  $swift_store_auth_address            = lookup('glance::backend::swift::swift_store_auth_address', undef, undef, undef),
  $swift_store_auth_version            = lookup('glance::backend::swift::swift_store_auth_version', undef, undef, undef),
  $swift_store_auth_project_domain_id  = lookup('glance::backend::swift::swift_store_auth_project_domain_id', undef, undef, undef),
  $swift_store_auth_user_domain_id     = lookup('glance::backend::swift::swift_store_auth_user_domain_id', undef, undef, undef),
  $swift_store_large_object_size       = lookup('glance::backend::swift::swift_store_large_object_size', undef, undef, undef),
  $swift_store_large_object_chunk_size = lookup('glance::backend::swift::swift_store_large_object_chunk_size', undef, undef, undef),
  $swift_store_create_container_on_put = lookup('glance::backend::swift::swift_store_create_container_on_put', undef, undef, undef),
  $swift_store_endpoint_type           = lookup('glance::backend::swift::swift_store_endpoint_type', undef, undef, undef),
  $swift_store_region                  = lookup('glance::backend::swift::swift_store_region', undef, undef, undef),
  $default_swift_reference             = 'ref1',
  $store_description                   = lookup('tripleo::profile::base::glance::api::glance_store_description',
                                                undef, undef, 'Swift store'),
  $step                                = Integer(lookup('step')),
  # DEPRECATED PARAMETERS
  $swift_store_config_file             = undef,
) {

  if $backend_names.length() > 1 {
    fail('Multiple swift backends are not supported.')
  }

  if $swift_store_config_file != undef {
    warning('The swift_store_config_file parameter has been deprecated and has no effect')
  }

  if $step >= 4 {
    $backend_name = $backend_names[0]

    $multistore_description = pick($multistore_config[$backend_name], {})['GlanceStoreDescription']
    $store_description_real = pick($multistore_description, $store_description)

    create_resources('glance::backend::multistore::swift', { $backend_name => delete_undef_values({
      'swift_store_user'                    => $swift_store_user,
      'swift_store_key'                     => $swift_store_key,
      'swift_store_container'               => $swift_store_container,
      'swift_store_auth_address'            => $swift_store_auth_address,
      'swift_store_auth_version'            => $swift_store_auth_version,
      'swift_store_auth_project_domain_id'  => $swift_store_auth_project_domain_id,
      'swift_store_auth_user_domain_id'     => $swift_store_auth_user_domain_id,
      'swift_store_large_object_size'       => $swift_store_large_object_size,
      'swift_store_large_object_chunk_size' => $swift_store_large_object_chunk_size,
      'swift_store_create_container_on_put' => $swift_store_create_container_on_put,
      'swift_store_endpoint_type'           => $swift_store_endpoint_type,
      'swift_store_region'                  => $swift_store_region,
      'default_swift_reference'             => $default_swift_reference,
      'store_description'                   => $store_description_real,
    })})
  }
}

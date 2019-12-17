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
# == Class: tripleo::profile::base::ironic::conductor
#
# Ironic conductor profile for TripleO
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('cinder_backup_short_bootstrap_node_name')
#
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')
#
# [*manage_pxe*]
#   (Optional) Whether to manage the PXE/iPXE environment for the conductor.
#   Defaults to true
#
# [*enable_staging*]
#   (Optional) Whether to enable ironic-staging-drivers support.
#   Defaults to false
#
class tripleo::profile::base::ironic::conductor (
  $bootstrap_node = hiera('ironic_api_short_bootstrap_node_name', undef),
  $step           = Integer(hiera('step')),
  $manage_pxe     = true,
  $enable_staging = false,
) {
  include tripleo::profile::base::ironic
  # Database is accessed by both API and conductor, hence it's here.
  if $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  # Ironic conductor class expects PXE directories exist
  if ($step >= 3 and $sync_db) and $manage_pxe {
      include ironic::pxe
  }

  if $step >= 4 {
      include ironic::conductor
      include ironic::drivers::interfaces
      include ironic::drivers::pxe
      if $manage_pxe {
          include ironic::pxe
      }

      # Configure a few popular drivers
      include ironic::drivers::ansible
      include ironic::drivers::drac
      include ironic::drivers::ilo
      include ironic::drivers::ipmi
      include ironic::drivers::redfish
      if $enable_staging {
          include ironic::drivers::staging
      }

      # Configure access to other services
      include ironic::cinder
      include ironic::drivers::inspector
      include ironic::glance
      include ironic::neutron
      include ironic::service_catalog
      include ironic::swift
  }
}

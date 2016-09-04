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
# [*step*]
#   (Optional) The current step of the deployment
#   Defaults to hiera('step')
#
# [*manage_pxe*]
#   (Optional) Whether to manage the PXE/iPXE environment for the conductor.
#   Defaults to true
#
class tripleo::profile::base::ironic::conductor (
  $step = hiera('step'),
  $manage_pxe = true,
) {
  include ::tripleo::profile::base::ironic

  if $step >= 4 {
      include ::ironic::conductor
      include ::ironic::drivers::pxe
      if $manage_pxe {
          include ::ironic::pxe
      }

      # Configure a few popular drivers
      include ::ironic::drivers::drac
      include ::ironic::drivers::ilo
      include ::ironic::drivers::ipmi
      include ::ironic::drivers::ssh
  }
}

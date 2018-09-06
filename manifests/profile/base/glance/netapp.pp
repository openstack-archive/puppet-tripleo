# Copyright 2018 Red Hat, Inc.
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
# == Class: tripleo::profile::base::glance::netapp
#
# Create metadata file for glance Netapp
#
# === Parameters
#
# [*netapp_share*]
#   Netapp share to mount, in 'IP:PATH' format.
#
# [*netapp_nfs_mount*]
#   (Optional) NFS mount point.
#   Defaults to '/var/lib/glance/images'
#
# [*filesystem_store_metadata_file*]
#   (optional) The path to a file which contains the metadata to be returned
#    with any location associated with the filesystem store
#    properties.
#   Defaults to '/etc/glance/glance-metadata-file.json'.
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')

class tripleo::profile::base::glance::netapp (
  $netapp_share,
  $netapp_nfs_mount               = '/var/lib/glance/images',
  $filesystem_store_metadata_file = '/etc/glance/glance-metadata-file.json',
  $step                           = Integer(hiera('step')),
) {


  if ($step >= 4) {
    $netapp_share_location = sprintf('nfs://%s', regsubst($netapp_share, ':', '', 'G'))
    $metadata = {
      'id'             => 'TripleOGlanceNetapp',
      'share_location' => $netapp_share_location,
      'mountpoint'     => $netapp_nfs_mount,
      'type'           => 'nfs', }
    file { $filesystem_store_metadata_file:
      ensure  => file,
      content => inline_template('<%= require "json"; JSON.dump(@metadata) %>'),
    }
  }
}


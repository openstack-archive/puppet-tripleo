# Copyright 2017 Red Hat, Inc.
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
# == Class: tripleo::certmonger::libvirt_vnc_dirs
#
# Creates the necessary directories for libvirt vnc certificates and keys in the
# assigned locations if specified. It also assigns the correct SELinux tags.
#
# === Parameters:
#
# [*certificate_dir*]
#   (Optional) Directory where libvirt-vnc's certificates will be stored. If left
#   unspecified, it won't be created.
#   Defaults to undef
#
# [*key_dir*]
#   (Optional) Directory where libvirt-vnc's keys will be stored.
#   Defaults to undef
#
class tripleo::certmonger::libvirt_vnc_dirs(
  $certificate_dir = undef,
  $key_dir         = undef,
){

  if $certificate_dir {
    file { $certificate_dir :
      ensure  => 'directory',
      selrole => 'object_r',
      seltype => 'cert_t',
      seluser => 'system_u',
    }
    File[$certificate_dir] ~> Certmonger_certificate<| tag == 'libvirt-vnc-cert' |>
  }

  if $key_dir {
    file { $key_dir :
      ensure  => 'directory',
      selrole => 'object_r',
      seltype => 'cert_t',
      seluser => 'system_u',
    }
    File[$key_dir] ~> Certmonger_certificate<| tag == 'libvirt-vnc-cert' |>
  }

}

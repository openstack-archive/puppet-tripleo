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
# == Class: tripleo::certmonger
#
# Sets some default defaults necessary for the global certmonger setup.
#
# === Parameters
#
# [*global_ca*]
#   The certmonger nickname for the CA that will be used.
#
class tripleo::certmonger (
  $global_ca
){
  include ::certmonger

  Certmonger_certificate {
    ca          => $global_ca,
    ensure      => 'present',
    certbackend => 'FILE',
    keybackend  => 'FILE',
    wait        => true,
    require     => Class['::certmonger'],
  }
}

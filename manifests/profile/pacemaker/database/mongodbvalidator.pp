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
# == Class: tripleo::profile::pacemaker::database::mongodb::conn_validator
#
# Connection validator for a node that serves MongoDB. This is done to be able
# to iterate through the different servers in a more seamless way.
#
# === Parameters
#
# [*title*]
#   the title or namevar of the resource will be used as the server of the
#   actual mongodb_conn_validator.
#
# [*port*]
#   The port in which the MongoDB server is listening on.
#
define tripleo::profile::pacemaker::database::mongodbvalidator(
  $port,
) {
  mongodb_conn_validator { "${title}_conn_validator" :
    server  => $title,
    port    => $port,
    timeout => '600',
  }
}

#########################################################################
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
# == Class: tripleo::profile::base::aide::rules
#
# Aide rules hash profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*content*]
#   Used by concat to populate aide.conf
#
# [*body*]
#   Used by concat to populate aide conf file
#
# [*order*]
# Specifies a method for sorting fragments by name within aide conf file
#
define tripleo::profile::base::aide::rules (
  $step    = Integer(hiera('step')),
  $content = '',
  $order   = 10,
) {

  include ::tripleo::profile::base::aide

  if $content == '' {
    $body = $name
  } else {
    $body = $content
  }

  if (!is_numeric($order) and !is_string($order))
  {
    fail('$order must be a string or an integer')
  }
  validate_string($body)

  concat::fragment{ "aide_fragment_${name}":
    target  => 'aide.conf',
    order   => $order,
    content => $body,
  }
}

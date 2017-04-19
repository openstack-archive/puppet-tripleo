# Copyright 2017 Red Hat, Inc.
# All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: tripleo::profile::base::login_defs
#
# Sets login.defs Parameters
#
# === Parameters
#
# [*step*]
#  (Optional) The current step in deployment. See tripleo-heat-templates
#  for more details.
#  Defaults to hiera('step')
#
# [*password_max_days*]
#  (Optional) Set the maximum age allowed for passwords
#  Defaults to hiera('password_max_days', 99999)
#
# [*password_min_days*]
#  (Optional) Set the minimum age allowed for passwords
#  Defaults to hiera('password_min_days', 7)
#
# [*password_warn_age*]
#  (Optional) Set the warning period for password expiration
#  Defaults to hiera('password_min_len', 6)
#
# [*password_min_len*]
#  (Optional) Set the minimum allowed password length.
#  Defaults to hiera('password_warn_age', 7)
#
# [*fail_delay*]
#  (Optional) The period of time between password retries
#  Defaults to hiera('fail_delay', 4)

class tripleo::profile::base::login_defs (
  $password_max_days = hiera('password_max_days', 99999),
  $password_min_days = hiera('password_min_days', 7),
  $password_min_len  = hiera('password_min_len', 6),
  $password_warn_age = hiera('password_warn_age', 7),
  $fail_delay        = hiera('fail_delay', 4),
  $step              = Integer(hiera('step'))
) {
  include ::tripleo::profile::base::login_defs

  if $step >= 1 {
    package { 'shadow-utils':
    ensure =>  'present'
    }

    augeas { 'login_defs':
      context =>  '/files/etc/login.defs',
      changes => [
        "set PASS_MAX_DAYS ${password_max_days}",
        "set PASS_MIN_DAYS ${password_min_days}",
        "set PASS_MIN_LEN ${password_min_len}",
        "set PASS_WARN_AGE ${password_warn_age}",
        "set FAIL_DELAY ${fail_delay}"
      ],
    }

    file { '/etc/login.defs':
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
    }
  }
}

# Copyright 2016 Red Hat, Inc.
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
# == Class: tripleo::profile::base::sshd
#
# SSH composable service for TripleO
#
# === Parameters
#
# [*bannertext*]
#   The text used within /etc/issue and /etc/issue.net
#   Defaults to hiera('BannerText')
#
# [*motd*]
#   The text used within SSH Banner
#   Defaults to hiera('MOTD')
#
class tripleo::profile::base::sshd (
  $bannertext = hiera('BannerText', undef),
  $motd = hiera('MOTD', undef),
) {

  include ::ssh

  if $bannertext {
    $filelist = [ '/etc/issue', '/etc/issue.net', ]
    file { $filelist:
      ensure  => file,
      backup  => false,
      content => $bannertext,
      owner   => 'root',
      group   => 'root',
      mode    => '0644'
    }
  }

  if $motd {
    file { '/etc/motd':
      ensure  => file,
      backup  => false,
      content => $motd,
      owner   => 'root',
      group   => 'root',
      mode    => '0644'
    }
  }
}

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
# == Class: tripleo::profile::base::docker
#
# docker profile for tripleo
#
# === Parameters
#
# [*docker_namespace*]
#   The namespace to be used when setting INSECURE_REGISTRY
#   this will be split on "/" to derive the docker registry
#   (defaults to undef)
#
# [*insecure_registry*]
#   Set docker_namespace to INSECURE_REGISTRY, used when a local registry
#   is enabled (defaults to false)
#
# [*registry_mirror*]
#   Configure a registry-mirror in the /etc/docker/daemon.json file.
#   (defaults to false)
#
# [*step*]
#   step defaults to hiera('step')
#
class tripleo::profile::base::docker (
  $docker_namespace = undef,
  $insecure_registry = false,
  $registry_mirror = false,
  $step = hiera('step'),
) {
  if $step >= 1 {
    package {'docker':
      ensure => installed,
    }

    service { 'docker':
      ensure  => 'running',
      enable  => true,
      require => Package['docker'],
    }

    if $insecure_registry {
      if $docker_namespace == undef {
        fail('You must provide a $docker_namespace in order to configure insecure registry')
      }
      $namespace = strip($docker_namespace.split('/')[0])
      $changes = [ "set INSECURE_REGISTRY '\"--insecure-registry ${namespace}\"'", ]
    } else {
      $changes = [ 'rm INSECURE_REGISTRY', ]
    }

    augeas { 'docker-sysconfig':
      lens      => 'Shellvars.lns',
      incl      => '/etc/sysconfig/docker',
      changes   => $changes,
      subscribe => Package['docker'],
      notify    => Service['docker'],
    }

    if $registry_mirror {
      $mirror_changes = [
        'set dict/entry[. = "registry-mirrors"] "registry-mirrors',
        "set dict/entry[. = \"registry-mirrors\"]/array/string \"${registry_mirror}\""
      ]
    } else {
      $mirror_changes = [ 'rm dict/entry[. = "registry-mirrors"]', ]
    }

    file { '/etc/docker/daemon.json':
      ensure  => 'present',
      content => '{}',
      mode    => '0644',
      replace => false,
      require => Package['docker']
    }

    augeas { 'docker-daemon.json':
      lens      => 'Json.lns',
      incl      => '/etc/docker/daemon.json',
      changes   => $mirror_changes,
      subscribe => Package['docker'],
      notify    => Service['docker'],
      require   => File['/etc/docker/daemon.json'],
    }

  }
}

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
# [*insecure_registry_address*]
#   The host/port combiniation of the insecure registry. This is used to configure
#   /etc/sysconfig/docker so that a local (insecure) registry can be accessed.
#   Example: 127.0.0.1:8787 (defaults to unset)
#
# [*registry_mirror*]
#   Configure a registry-mirror in the /etc/docker/daemon.json file.
#   (defaults to false)
#
# [*docker_options*]
#   OPTIONS that are used to startup the docker service.  NOTE:
#   --selinux-enabled is dropped due to recommendations here:
#   https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/7.2_Release_Notes/technology-preview-file_systems.html
#   Defaults to '--log-driver=journald --signature-verification=false --iptables=false'
#
# [*configure_storage*]
#   Boolean. Whether to configure a docker storage backend. Defaults to true.
#
# [*storage_options*]
#   Storage options to configure. Defaults to '-s overlay2'
#
# [*step*]
#   step defaults to hiera('step')
#
# [*configure_libvirt_polkit*]
#   Configures libvirt polkit to grant the kolla nova user access to the libvirtd unix domain socket on the host.
#   Defaults to true when nova_compute service is enabled, false when nova_compute is disabled
#
# [*docker_nova_uid*]
#   When configure_libvirt_polkit = true, the uid/gid of the nova user within the docker container.
#   Defaults to 42436
#
# [*services_enabled*]
#   List of TripleO services enabled on the role.
#   Defaults to hiera('services_names')
#
# DEPRECATED PARAMETERS
#
# [*docker_namespace*]
#   DEPRECATED: The namespace to be used when setting INSECURE_REGISTRY
#   this will be split on "/" to derive the docker registry
#   (defaults to undef)
#
# [*insecure_registry*]
#   DEPRECATED: Set docker_namespace to INSECURE_REGISTRY, used when a local registry
#   is enabled (defaults to false)
#
class tripleo::profile::base::docker (
  $insecure_registry_address = undef,
  $registry_mirror = false,
  $docker_options = '--log-driver=journald --signature-verification=false --iptables=false',
  $configure_storage = true,
  $storage_options = '-s overlay2',
  $step = Integer(hiera('step')),
  $configure_libvirt_polkit = undef,
  $docker_nova_uid = 42436,
  $services_enabled = hiera('service_names', []),
  # DEPRECATED PARAMETERS
  $docker_namespace = undef,
  $insecure_registry = false,
) {

  if $configure_libvirt_polkit == undef {
    $configure_libvirt_polkit_real = 'nova_compute' in $services_enabled
  } else {
    $configure_libvirt_polkit_real = $configure_libvirt_polkit
  }

  if $step >= 1 {
    package {'docker':
      ensure => installed,
    }

    service { 'docker':
      ensure  => 'running',
      enable  => true,
      require => Package['docker'],
    }

    if $docker_options {
      $options_changes = [ "set OPTIONS '\"${docker_options}\"'" ]
    } else {
      $options_changes = [ 'rm OPTIONS' ]
    }

    augeas { 'docker-sysconfig-options':
      lens      => 'Shellvars.lns',
      incl      => '/etc/sysconfig/docker',
      changes   => $options_changes,
      subscribe => Package['docker'],
      notify    => Service['docker'],
    }

    if $insecure_registry {
      warning('The $insecure_registry and $docker_namespace are deprecated. Use $insecure_registry_address instead.')
      if $docker_namespace == undef {
        fail('You must provide a $docker_namespace in order to configure insecure registry')
      }
      $namespace = strip($docker_namespace.split('/')[0])
      $registry_changes = [ "set INSECURE_REGISTRY '\"--insecure-registry ${namespace}\"'" ]
    } elsif $insecure_registry_address {
      $registry_changes = [ "set INSECURE_REGISTRY '\"--insecure-registry ${insecure_registry_address}\"'" ]
    } else {
      $registry_changes = [ 'rm INSECURE_REGISTRY' ]
    }

    augeas { 'docker-sysconfig-registry':
      lens      => 'Shellvars.lns',
      incl      => '/etc/sysconfig/docker',
      changes   => $registry_changes,
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
    if $configure_storage {
      if $storage_options == undef {
        fail('You must provide a $storage_options in order to configure storage')
      }
      $storage_changes = [ "set DOCKER_STORAGE_OPTIONS '\" ${storage_options}\"'", ]
    } else {
      $storage_changes = [ 'rm DOCKER_STORAGE_OPTIONS', ]
    }

    augeas { 'docker-sysconfig-storage':
      lens    => 'Shellvars.lns',
      incl    => '/etc/sysconfig/docker-storage',
      changes => $storage_changes,
      notify  => Service['docker'],
      require => Package['docker'],
    }

  }
  if ($step >= 4 and $configure_libvirt_polkit_real) {
    # Workaround for polkit authorization for libvirtd socket on host
    #
    # This creates a local user with the kolla nova uid, and sets the polkit rule to
    # allow both it and the nova user from the nova rpms, should it exist (uid 162).

    group { 'docker_nova_group':
      name => 'docker_nova',
      gid  => $docker_nova_uid
    }
    -> user { 'docker_nova_user':
      name    => 'docker_nova',
      uid     => $docker_nova_uid,
      gid     => $docker_nova_uid,
      shell   => '/sbin/nologin',
      comment => 'OpenStack Nova Daemons',
      groups  => ['nobody']
    }

    # Similar to the polkit rule in the openstack-nova rpm spec
    # but allow both the 'docker_nova' and 'nova' user
    $docker_nova_polkit_rule = '// openstack-nova libvirt management permissions
polkit.addRule(function(action, subject) {
    if (action.id == "org.libvirt.unix.manage" &&
        /^(docker_)?nova$/.test(subject.user)) {
        return polkit.Result.YES;
    }
});
'
    package {'polkit':
      ensure => installed,
    }
    -> file {'/etc/polkit-1/rules.d/50-nova.rules':
      content => $docker_nova_polkit_rule,
      mode    => '0644'
    }
  }
}

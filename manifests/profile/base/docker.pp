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
# [*insecure_registries*]
#   An array of host/port combiniations of insecure registries. This is used to configure
#   /etc/sysconfig/docker so that local (insecure) registries can be accessed.
#   Example: ['127.0.0.1:8787']
#   (defaults to unset)
#
# [*registry_mirror*]
#   Configure a registry-mirror in the /etc/docker/daemon.json file.
#   (defaults to false)
#
# [*docker_options*]
#   OPTIONS that are used to startup the docker service.
#   Defaults to '--log-driver=journald --signature-verification=false --iptables=false --live-restore'
#
# [*additional_sockets*]
#   Array of addtional domain sockets for the docker daemon to bind to.
#   Defaults to undef
#
# [*configure_network*]
#   Boolean. Whether to configure the docker network. Defaults to false.
#
# [*network_options*]
#   Network options to configure. Defaults to ''
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
# [*debug*]
#   Boolean. Value to configure docker daemon's debug configuration.
#   Defaults to false
#
# [*deployment_user*]
#   String. Value to configure the deployment user.
#   Defaults to hiera('deployment_user', undef)
#
# [*selinux_enabled*]
#   Boolean. Whether to enable SELinux for docker or not. NOTE:
#   --selinux-enabled is disabled by default due to recommendations here:
#   https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/7.2_Release_Notes/technology-preview-file_systems.html
#   Defaults to false
#
# DEPRECATED PARAMETERS
#
# [*insecure_registry_address*]
#   DEPRECATED: The host/port combiniation of the insecure registry. This is used to configure
#   /etc/sysconfig/docker so that a local (insecure) registry can be accessed.
#   Example: 127.0.0.1:8787 (defaults to unset)
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
  $insecure_registries = undef,
  $registry_mirror     = false,
  $docker_options      = '--log-driver=journald --signature-verification=false --iptables=false --live-restore',
  $additional_sockets  = undef,
  $configure_network   = false,
  $network_options     = '',
  $configure_storage   = true,
  $storage_options     = '-s overlay2',
  $step                = Integer(hiera('step')),
  $debug               = false,
  $deployment_user     = hiera('deployment_user', undef),
  $selinux_enabled     = false,
  # DEPRECATED PARAMETERS
  $insecure_registry_address = undef,
  $docker_namespace = undef,
  $insecure_registry = false,
) {

  warning('tripleo::profile::base::docker(_registry) are deprecated and will be removed in the future.')

  if $step >= 1 {
    package {'docker':
      ensure => installed,
    }
    # NOTE(aschultz): LP#1750194 - need to set ip_forward before docker starts
    # so lets set it before we install the package if we're managing it.
    Sysctl::Value<| title == 'net.ipv4.ip_forward' |> -> Package['docker']

    $docker_unit_override="[Service]\nMountFlags=\n"

    file {'/etc/systemd/system/docker.service.d':
      ensure  => directory,
      require => Package['docker'],
    }
    -> file {'/etc/systemd/system/docker.service.d/99-unset-mountflags.conf':
      content => $docker_unit_override,
    }
    ~> exec { 'systemd daemon-reload':
      command     => 'systemctl daemon-reload',
      path        => ['/usr/bin', '/usr/sbin'],
      refreshonly => true,
      notify      => Service['docker']
    }

    service { 'docker':
      ensure  => 'running',
      enable  => true,
      require => Package['docker'],
    }

    if $docker_options {
      if $selinux_enabled {
        $selinux_enabled_string = ' --selinux-enabled'
      } else {
        $selinux_enabled_string = ''
      }
      if $additional_sockets {
        $arg_string = join(prefix(any2array($additional_sockets), '-H unix://'), ' ')
        # We include the typical default socket to make sure other docker clients
        # will work.
        $add_sockets = " -H unix:///run/docker.sock ${arg_string}"
      } else {
        $add_sockets = ''
      }
      $options_changes = [ "set OPTIONS '\"${docker_options}${add_sockets}${selinux_enabled_string}\"'" ]
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
      warning('The $insecure_registry and $docker_namespace are deprecated. Use $insecure_registries instead.')
      if $docker_namespace == undef {
        fail('You must provide a $docker_namespace in order to configure insecure registry')
      }
      $namespace = strip($docker_namespace.split('/')[0])
      $registry_changes = [ "set INSECURE_REGISTRY '\"--insecure-registry ${namespace}\"'" ]
    } elsif $insecure_registry_address {
      warning('The $insecure_registry_address parameter is deprecated. Use $insecure_registries instead.')
      $registry_changes = [ "set INSECURE_REGISTRY '\"--insecure-registry ${insecure_registry_address}\"'" ]
    } elsif $insecure_registries {
      $registry_changes = [ join(['set INSECURE_REGISTRY \'"--insecure-registry ',
                                  join(any2array($insecure_registries), ' --insecure-registry '),
                                  '"\''], '') ]
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
        "set dict/entry[. = 'registry-mirrors'] registry-mirrors",
        "set dict/entry[. = 'registry-mirrors']/array/string \"${registry_mirror}\""
      ]
    } else {
      $mirror_changes = [ "rm dict/entry[. = 'registry-mirrors']", ]
    }

    if $debug {
      $debug_changes = [
        "set dict/entry[. = 'debug'] debug",
        "set dict/entry[. = 'debug']/const true", ]
    } else {
      $debug_changes = [
        "set dict/entry[. = 'debug'] debug",
        "set dict/entry[. = 'debug']/const false", ]
    }

    file { '/etc/docker/daemon.json':
      ensure  => 'present',
      content => '{}',
      mode    => '0644',
      replace => false,
      require => Package['docker']
    }

    augeas { 'docker-daemon.json-mirror':
      lens      => 'Json.lns',
      incl      => '/etc/docker/daemon.json',
      changes   => $mirror_changes,
      subscribe => Package['docker'],
      notify    => Service['docker'],
      require   => File['/etc/docker/daemon.json'],
    }

    augeas { 'docker-daemon.json-debug':
      lens      => 'Json.lns',
      incl      => '/etc/docker/daemon.json',
      changes   => $debug_changes,
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

    if $configure_network {
      if $network_options == undef {
        fail('You must provide a $network_options in order to configure network')
      }
      $network_changes = [ "set DOCKER_NETWORK_OPTIONS '\" ${network_options}\"'", ]
    } else {
      $network_changes = [ 'rm DOCKER_NETWORK_OPTIONS', ]
    }

    augeas { 'docker-sysconfig-network':
      lens    => 'Shellvars.lns',
      incl    => '/etc/sysconfig/docker-network',
      changes => $network_changes,
      notify  => Service['docker'],
      require => Package['docker'],
    }

    if $additional_sockets {
      # When specifying additional sockets, ensure that the directory
      # exists for each one.
      any2array($additional_sockets).each | String $sock_path | {
        file {dirname($sock_path):
          ensure => directory,
          notify => Service['docker']
        }
      }
    }

    if $deployment_user or $additional_sockets {
      ensure_resource('group', 'docker', {
        'ensure' => 'present'
      })
    }

    if $deployment_user {
      ensure_resource('user', $deployment_user, {
        'name'   => $deployment_user,
        'groups' => 'docker',
        # We need to add the user into docker group
        # before docker starts otherwise the user won't
        # be able to use Docker CLI.
        # See background:
        # https://review.openstack.org/#/c/390549/3/elements/puppet-stack-config/puppet-stack-config.pp
        # https://docs.docker.com/install/linux/linux-postinstall/#manage-docker-as-a-non-root-user
        'notify'  => Service['docker'],
      })
    }

  }
}

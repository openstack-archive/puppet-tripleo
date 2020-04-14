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
# == Class: tripleo::profile::pacemaker::rabbitmq_bundle
#
# Containerized RabbitMQ Pacemaker HA profile for tripleo
#
# === Parameters
#
# [*rabbitmq_docker_image*]
#   (Optional) The docker image to use for creating the pacemaker bundle
#   Defaults to hiera('tripleo::profile::pacemaker::rabbitmq_bundle::rabbitmq_docker_image', undef)
#
# [*rabbitmq_docker_control_port*]
#   (Optional) The bundle's pacemaker_remote control port on the host
#   Defaults to hiera('tripleo::profile::pacemaker::rabbitmq_bundle::control_port', '3122')
#
# [*erlang_cookie*]
#   (Optional) Content of erlang cookie.
#   Defaults to hiera('rabbitmq::erlang_cookie').
#
# [*user_ha_queues*]
#   (Optional) The number of HA queues in to be configured in rabbitmq
#   Defaults to hiera('rabbitmq::nr_ha_queues'), which is usually 0 meaning
#   that the queues number will be CEIL(N/2) where N is the number of rabbitmq
#   nodes.
#
# [*rpc_scheme*]
#   (Optional) Protocol for oslo messaging rpc backend.
#   Defaults to hiera('oslo_messaging_rpc_scheme').
#
# [*rpc_bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   when rabbit is configured for rpc messaging backend
#   Defaults to hiera('oslo_messaging_rpc_bootstrap_node_name')
#
# [*rpc_nodes*]
#   (Optional) Array of host(s) for oslo messaging rpc nodes.
#   Defaults to hiera('oslo_messaging_rpc_node_names', []).
#
# [*notify_scheme*]
#   (Optional) oslo messaging notify backend indicator.
#   Defaults to hiera('oslo_messaging_notify_scheme').
#
# [*notify_bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   when rabbit is configured for rpc messaging backend
#   Defaults to hiera('oslo_messaging_notify_bootstrap_node_name')
#
# [*notify_nodes*]
#   (Optional) Array of host(s) for oslo messaging notify nodes.
#   Defaults to hiera('oslo_messaging_notify_node_names', []).
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to hiera('enable_internal_tls', false)
#
# [*rabbitmq_extra_policies*]
#   (Optional) Hash of extra policies for the HA queues
#   Defaults to hiera('rabbitmq_extra_policies', {'ha-promote-on-shutdown' => 'always'})
#
# [*pcs_tries*]
#   (Optional) The number of times pcs commands should be retried.
#   Defaults to hiera('pcs_tries', 20)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*container_backend*]
#   (optional) Container backend to use when creating the bundle
#   Defaults to 'docker'
#
# [*log_driver*]
#   (optional) Container log driver to use. When set to undef it uses 'k8s-file'
#   when container_cli is set to podman and 'journald' when it is set to docker.
#   Defaults to undef
#
# [*log_file*]
#   (optional) Container log file to use. Only relevant when log_driver is
#   set to 'k8s-file'.
#   Defaults to '/var/log/containers/stdouts/rabbitmq-bundle.log'
#
# [*tls_priorities*]
#   (optional) Sets PCMK_tls_priorities in /etc/sysconfig/pacemaker when set
#   Defaults to hiera('tripleo::pacemaker::tls_priorities', undef)
#
# [*bundle_user*]
#   (optional) Set the --user= switch to be passed to pcmk
#   Defaults to 'root'
#
class tripleo::profile::pacemaker::rabbitmq_bundle (
  $rabbitmq_docker_image        = hiera('tripleo::profile::pacemaker::rabbitmq_bundle::rabbitmq_docker_image', undef),
  $rabbitmq_docker_control_port = hiera('tripleo::profile::pacemaker::rabbitmq_bundle::control_port', '3122'),
  $erlang_cookie                = hiera('rabbitmq::erlang_cookie'),
  $user_ha_queues               = hiera('rabbitmq::nr_ha_queues', 0),
  $rpc_scheme                   = hiera('oslo_messaging_rpc_scheme'),
  $rpc_bootstrap_node           = hiera('oslo_messaging_rpc_short_bootstrap_node_name'),
  $rpc_nodes                    = hiera('oslo_messaging_rpc_node_names_override',
                                        hiera('oslo_messaging_rpc_node_names', [])),
  $notify_scheme                = hiera('oslo_messaging_notify_scheme'),
  $notify_bootstrap_node        = hiera('oslo_messaging_notify_short_bootstrap_node_name'),
  $notify_nodes                 = hiera('oslo_messaging_notify_node_names_override',
                                        hiera('oslo_messaging_notify_node_names', [])),
  $enable_internal_tls          = hiera('enable_internal_tls', false),
  $rabbitmq_extra_policies      = hiera('rabbitmq_extra_policies', {'ha-promote-on-shutdown' => 'always'}),
  $pcs_tries                    = hiera('pcs_tries', 20),
  $step                         = Integer(hiera('step')),
  $container_backend            = 'docker',
  $log_driver                   = undef,
  $log_file                     = '/var/log/containers/stdouts/rabbitmq-bundle.log',
  $tls_priorities               = hiera('tripleo::pacemaker::tls_priorities', undef),
  $bundle_user                  = 'root',
) {
  # is this an additional nova cell?
  if hiera('nova_is_additional_cell', undef) {
    $rpc_nodes_real = hiera('oslo_messaging_rpc_cell_node_names', [])
  } else {
    $rpc_nodes_real = $rpc_nodes
  }

  if $rpc_scheme == 'rabbit' {
    $bootstrap_node = $rpc_bootstrap_node
    $rabbit_nodes = $rpc_nodes_real
  } elsif $notify_scheme == 'rabbit' {
    $bootstrap_node = $notify_bootstrap_node
    $rabbit_nodes = $notify_nodes
  } else {
    $bootstrap_node = undef
    $rabbit_nodes = []
  }

  if $::hostname == downcase($bootstrap_node) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  if $log_driver == undef {
    if hiera('container_cli', 'docker') == 'podman' {
      $log_driver_real = 'k8s-file'
    } else {
      $log_driver_real = 'journald'
    }
  } else {
    $log_driver_real = $log_driver
  }
  if $log_driver_real == 'k8s-file' {
    $log_file_real = " --log-opt path=${log_file}"
  } else {
    $log_file_real = ''
  }
  include tripleo::profile::base::rabbitmq

  file { '/var/lib/rabbitmq/.erlang.cookie':
    ensure  => file,
    owner   => 'rabbitmq',
    group   => 'rabbitmq',
    mode    => '0400',
    content => $erlang_cookie,
    replace => true,
    require => Class['::rabbitmq'],
  }

  file_line { 'rabbitmq-pamd-systemd':
    ensure            => absent,
    path              => '/etc/pam.d/system-auth',
    match             => '^-session\s+optional\s+pam_systemd.so',
    match_for_absence => true,
  }
  # Note that once we move to RHEL8 where pam_unix.so supports the quiet option
  # we can just add quiet to the pam_unix option for the session module and remove this one
  file_line { 'rabbitmq-pamd-succeed':
    ensure => present,
    path   => '/etc/pam.d/system-auth',
    line   => 'session     sufficient    pam_succeed_if.so quiet_success user ingroup rabbitmq',
    after  => '^session.*pam_limits.so'
  }


  if $step >= 2 {
    if $pacemaker_master {
      if $rpc_scheme == 'rabbit' {
        $rabbitmq_short_node_names = hiera('oslo_messaging_rpc_short_node_names_override',
          hiera('oslo_messaging_rpc_short_node_names'))
      } elsif $notify_scheme == 'rabbit' {
        $rabbitmq_short_node_names = hiera('oslo_messaging_notify_short_node_names_override',
          hiera('oslo_messaging_notify_short_node_names'))
      }
      $rabbitmq_nodes_count = count($rabbitmq_short_node_names)
      $rabbitmq_short_node_names.each |String $node_name| {
        pacemaker::property { "rabbitmq-role-${node_name}":
          property => 'rabbitmq-role',
          value    => true,
          tries    => $pcs_tries,
          node     => downcase($node_name),
          before   => Pacemaker::Resource::Bundle['rabbitmq-bundle'],
        }
      }

      $storage_maps = {
        'rabbitmq-cfg-files'               => {
          'source-dir' => '/var/lib/kolla/config_files/rabbitmq.json',
          'target-dir' => '/var/lib/kolla/config_files/config.json',
          'options'    => 'ro',
        },
        'rabbitmq-cfg-data'                => {
          'source-dir' => '/var/lib/config-data/puppet-generated/rabbitmq/',
          'target-dir' => '/var/lib/kolla/config_files/src',
          'options'    => 'ro',
        },
        'rabbitmq-hosts'                   => {
          'source-dir' => '/etc/hosts',
          'target-dir' => '/etc/hosts',
          'options'    => 'ro',
        },
        'rabbitmq-localtime'               => {
          'source-dir' => '/etc/localtime',
          'target-dir' => '/etc/localtime',
          'options'    => 'ro',
        },
        'rabbitmq-lib'                     => {
          'source-dir' => '/var/lib/rabbitmq',
          'target-dir' => '/var/lib/rabbitmq',
          'options'    => 'rw',
        },
        'rabbitmq-pki-extracted'           => {
          'source-dir' => '/etc/pki/ca-trust/extracted',
          'target-dir' => '/etc/pki/ca-trust/extracted',
          'options'    => 'ro',
        },
        'rabbitmq-pki-ca-bundle-crt'       => {
          'source-dir' => '/etc/pki/tls/certs/ca-bundle.crt',
          'target-dir' => '/etc/pki/tls/certs/ca-bundle.crt',
          'options'    => 'ro',
        },
        'rabbitmq-pki-ca-bundle-trust-crt' => {
          'source-dir' => '/etc/pki/tls/certs/ca-bundle.trust.crt',
          'target-dir' => '/etc/pki/tls/certs/ca-bundle.trust.crt',
          'options'    => 'ro',
        },
        'rabbitmq-pki-cert'                => {
          'source-dir' => '/etc/pki/tls/cert.pem',
          'target-dir' => '/etc/pki/tls/cert.pem',
          'options'    => 'ro',
        },
        'rabbitmq-log'                     => {
          'source-dir' => '/var/log/containers/rabbitmq',
          'target-dir' => '/var/log/rabbitmq',
          'options'    => 'rw',
        },
        'rabbitmq-dev-log'                 => {
          'source-dir' => '/dev/log',
          'target-dir' => '/dev/log',
          'options'    => 'rw',
        },
      }

      if $enable_internal_tls {
        $storage_maps_tls = {
          'rabbitmq-pki-cert' => {
            'source-dir' => '/etc/pki/tls/certs/rabbitmq.crt',
            'target-dir' => '/var/lib/kolla/config_files/src-tls/etc/pki/tls/certs/rabbitmq.crt',
            'options'    => 'ro',
          },
          'rabbitmq-pki-key'  => {
            'source-dir' => '/etc/pki/tls/private/rabbitmq.key',
            'target-dir' => '/var/lib/kolla/config_files/src-tls/etc/pki/tls/private/rabbitmq.key',
            'options'    => 'ro',
          },
        }
      } else {
        $storage_maps_tls = {}
      }
      if $tls_priorities != undef {
        $tls_priorities_real = " -e PCMK_tls_priorities=${tls_priorities}"
      } else {
        $tls_priorities_real = ''
      }

      pacemaker::resource::bundle { 'rabbitmq-bundle':
        image             => $rabbitmq_docker_image,
        replicas          => $rabbitmq_nodes_count,
        location_rule     => {
          resource_discovery => 'exclusive',
          score              => 0,
          expression         => ['rabbitmq-role eq true'],
        },
        container_options => 'network=host',
        # lint:ignore:140chars
        options           => "--user=${bundle_user} --log-driver=${log_driver_real}${log_file_real} -e KOLLA_CONFIG_STRATEGY=COPY_ALWAYS -e LANG=en_US.UTF-8 -e LC_ALL=en_US.UTF-8${tls_priorities_real}",
        # lint:endignore
        run_command       => '/bin/bash /usr/local/bin/kolla_start',
        network           => "control-port=${rabbitmq_docker_control_port}",
        storage_maps      => merge($storage_maps, $storage_maps_tls),
        container_backend => $container_backend,
        tries             => $pcs_tries,
      }

      # The default nr of ha queues is ceiling(N/2)
      if $user_ha_queues == 0 {
        $nr_rabbit_nodes = size($rabbit_nodes)
        $nr_ha_queues = $nr_rabbit_nodes / 2 + ($nr_rabbit_nodes % 2)
        $ha_queues_policy = { 'ha-mode' => 'exactly', 'ha-params' => $nr_ha_queues }
      } elsif $user_ha_queues == -1 {
        $ha_queues_policy = { 'ha-mode' => 'all' }
      } else {
        $nr_ha_queues = $user_ha_queues
        $ha_queues_policy = { 'ha-mode' => 'exactly', 'ha-params' => $nr_ha_queues }
      }
      $ha_policy = merge($ha_queues_policy, $rabbitmq_extra_policies)
      $ocf_params = "set_policy='ha-all ^(?!amq\\.).* ${to_json($ha_policy)}'"

      pacemaker::resource::ocf { 'rabbitmq':
        ocf_agent_name  => 'heartbeat:rabbitmq-cluster',
        resource_params => $ocf_params,
        meta_params     => 'notify=true container-attribute-target=host',
        op_params       => 'start timeout=200s stop timeout=200s',
        tries           => $pcs_tries,
        location_rule   => {
          resource_discovery => 'exclusive',
          score              => 0,
          expression         => ['rabbitmq-role eq true'],
        },
        bundle          => 'rabbitmq-bundle',
        require         => [Class['::rabbitmq'],
                            Pacemaker::Resource::Bundle['rabbitmq-bundle']],
        before          => Exec['rabbitmq-ready'],
      }

      if size($rabbit_nodes) == 1 {
        $check_command = 'rabbitmqctl status | grep -F "{rabbit,"'
      } else {
        # This grep makes sure the rabbit app in erlang is up and running
        # which is enough to guarantee that the user will eventually get
        # replicated around the cluster
        $cmd1 = 'rabbitmqctl eval "rabbit_nodes:is_running(node(), rabbit)." | grep -q true'
        $cmd2 = 'rabbitmqctl eval "rabbit_mnesia:is_clustered()." | grep -q true'
        $check_command = "${cmd1} && ${cmd2}"
      }

      exec { 'rabbitmq-ready':
        path      => '/usr/sbin:/usr/bin:/sbin:/bin',
        command   => $check_command,
        unless    => $check_command,
        timeout   => 30,
        tries     => 180,
        try_sleep => 10,
        tag       => 'rabbitmq_ready',
      }

      # Set the HA queue policy here, because the rabbitmq resource
      # agent do so very early in the bootstrap process, and it
      # doesn't seem to work reliably.
      # Note: rabbitmq_policy expects all the hash values passed
      # to 'definition' to be strings
      rabbitmq_policy { 'ha-all@/':
        applyto    => 'queues',
        pattern    => '^(?!amq\.).*',
        definition => hash($ha_policy.map |$k, $v| {[$k, "${v}"]}),
      }

      # Make sure that if we create rabbitmq users at the same step it happens
      # after the cluster is up
      Exec['rabbitmq-ready'] -> Rabbitmq_user<||>
      Exec['rabbitmq-ready'] -> Rabbitmq_policy<||>
    }
  }
}

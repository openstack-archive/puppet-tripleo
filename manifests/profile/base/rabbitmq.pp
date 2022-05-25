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
# == Class: tripleo::profile::base::rabbitmq
#
# RabbitMQ profile for tripleo
#
# === Parameters
#
# [*certificate_specs*]
#   (Optional) The specifications to give to certmonger for the certificate
#   it will create. Note that the certificate nickname must be 'mysql' in
#   the case of this service.
#   Example with hiera:
#     tripleo::profile::base::database::mysql::certificate_specs:
#       hostname: <overcloud controller fqdn>
#       service_certificate: <service certificate path>
#       service_key: <service key path>
#       principal: "mysql/<overcloud controller fqdn>"
#   Defaults to {}.
#
# [*config_variables*]
#   (Optional) RabbitMQ environment.
#   Defaults to lookup('rabbitmq_config_variables').
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to undef
#
# [*fips_mode*]
#   (Optional) Whether the erlang crypto app is configured for FIPS mode or not.
#   Defaults to false
#
# [*ssl_versions*]
#   (Optional) When enable_internal_tls is in use, list the enabled
#   TLS protocol version.
#   Defaults to ['tlsv1.2', 'tlsv1.3']
#
# [*inter_node_ciphers*]
#   (Optional) When enable_internal_tls is in use, list the allowed ciphers
#   for the encrypted inter-node communication.
#   Defaults to ''
#
# [*rabbitmq_cacert*]
#   (Optional) When internal tls is enabled this should point to the CA file
#   Defaults to lookup('rabbitmq::ssl_cacert', undef, undef, undef)
#
# [*verify_server_peer*]
#   (Optional) Server verify peer
#   Defaults to 'verify_none'
#
# [*verify_client_peer*]
#   (Optional) Client verify peer
#   Defaults to 'verify_peer'
#
# [*environment*]
#   (Optional) RabbitMQ environment.
#   Defaults to lookup('rabbitmq_environment').
#
# [*additional_erl_args*]
#   (Optional) Additional string to be passed to RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS
#   Defaults to undef
#
# [*inet_dist_interface*]
#   (Optional) Address to bind the inter-cluster interface
#   to. It is the inet_dist_use_interface option in the kernel variables
#   Defaults to lookup('rabbitmq::interface', undef, undef, undef).
#
# [*ipv6*]
#   (Optional) Whether to deploy RabbitMQ on IPv6 network.
#   Defaults to str2bool(lookup('rabbit_ipv6', undef, undef, false)).
#
# [*kernel_variables*]
#   (Optional) RabbitMQ environment.
#   Defaults to lookup('rabbitmq_environment').
#
# [*rpc_scheme*]
#   (Optional) Protocol for oslo messaging rpc backend.
#   Defaults to lookup('oslo_messaging_rpc_scheme', undef, undef, 'rabbit').
#
# [*rpc_nodes*]
#   (Optional) Array of host(s) for oslo messaging rpc nodes.
#   Defaults to lookup('oslo_messaging_rpc_node_names', undef, undef, []).
#
# [*rpc_bootstrap_node*]
#   (Optional) The hostname of the rpc node for bootstrapping tasks
#   Defaults to lookup('oslo_messaging_rpc_short_bootstrap_node_name')
#
# [*notify_scheme*]
#   (Optional) oslo messaging notify backend indicator.
#   Defaults to lookup('oslo_messaging_notify_scheme', undef, undef, 'rabbit').
#
# [*notify_nodes*]
#   (Optional) Array of host(s) for oslo messaging notify nodes.
#   Defaults to lookup('oslo_messaging_notify_node_names', undef, undef, []).
#
# [*notify_bootstrap_node*]
#   (Optional) The hostname of the notify node for bootstrapping tasks
#   Defaults to lookup('oslo_messaging_notify_short_bootstrap_node_name')
#
# [*rabbitmq_pass*]
#   (Optional) RabbitMQ Default Password.
#   Defaults to lookup('rabbitmq::default_pass')
#
# [*rabbitmq_user*]
#   (Optional) RabbitMQ Default User.
#   Defaults to lookup('rabbitmq::default_user')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
class tripleo::profile::base::rabbitmq (
  $certificate_specs             = {},
  $config_variables              = lookup('rabbitmq_config_variables'),
  $enable_internal_tls           = undef,
  $fips_mode                     = false,
  $environment                   = lookup('rabbitmq_environment'),
  $additional_erl_args           = undef,
  $ssl_versions                  = ['tlsv1.2', 'tlsv1.3'],
  $inter_node_ciphers            = '',
  $rabbitmq_cacert               = lookup('rabbitmq::ssl_cacert', undef, undef, undef),
  $verify_server_peer            = 'verify_none',
  $verify_client_peer            = 'verify_peer',
  $inet_dist_interface           = lookup('rabbitmq::interface', undef, undef, undef),
  $ipv6                          = str2bool(lookup('rabbit_ipv6', undef, undef, false)),
  $kernel_variables              = lookup('rabbitmq_kernel_variables'),
  $rpc_scheme                    = lookup('oslo_messaging_rpc_scheme', undef, undef, 'rabbit'),
  $rpc_nodes                     = lookup('oslo_messaging_rpc_node_names', undef, undef, []),
  $rpc_bootstrap_node            = lookup('oslo_messaging_rpc_short_bootstrap_node_name'),
  $notify_scheme                 = lookup('oslo_messaging_notify_scheme', undef, undef, 'rabbit'),
  $notify_nodes                  = lookup('oslo_messaging_notify_node_names', undef, undef, []),
  $notify_bootstrap_node         = lookup('oslo_messaging_notify_short_bootstrap_node_name'),
  $rabbitmq_pass                 = lookup('rabbitmq::default_pass'),
  $rabbitmq_user                 = lookup('rabbitmq::default_user'),
  $step                          = Integer(lookup('step')),
) {
  if $rpc_scheme == 'rabbit' {
    $nodes = $rpc_nodes
    $bootstrap_node = $rpc_bootstrap_node
  } elsif $notify_scheme == 'rabbit' {
    $nodes = $notify_nodes
    $bootstrap_node = $notify_bootstrap_node
  } else {
    $nodes = []
  }

  if $enable_internal_tls {
    $tls_certfile = $certificate_specs['service_certificate']
    $tls_keyfile = $certificate_specs['service_key']

    # Historically in THT the default value of RabbitAdditionalErlArgs was "'+sbwt none'", we
    # want to strip leading and trailing ' chars.
    if $additional_erl_args != undef {
      $additional_erl_args_real = regsubst($additional_erl_args, "(^'|'$)", '', 'G')
    } else {
      $additional_erl_args_real = ''
    }
    # lint:ignore:140chars
    $rabbitmq_additional_erl_args = "\"${additional_erl_args_real} -ssl_dist_optfile /etc/rabbitmq/ssl-dist.conf -crypto fips_mode ${fips_mode}\""
    # lint:endignore
    $rabbitmq_client_additional_erl_args = "\"${additional_erl_args_real}\""
    $environment_real = merge($environment, {
      'RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS' => $rabbitmq_additional_erl_args,
      'RABBITMQ_CTL_ERL_ARGS' => $rabbitmq_additional_erl_args,
      'LANG'   => 'en_US.UTF-8',
      'LC_ALL' => 'en_US.UTF-8'
    })
    $configured_ssl_versions = $ssl_versions
  } else {
    $tls_certfile = undef
    $tls_keyfile = undef
    if $additional_erl_args != undef {
      # Historically in THT the default value of RabbitAdditionalErlArgs was "'+sbwt none'", we
      # want to strip leading and trailing ' chars.
      $additional_erl_args_real = regsubst($additional_erl_args, "(^'|'$)", '', 'G')
      $rabbitmq_additional_erl_args = "\"${additional_erl_args_real}\""
      $environment_real = merge($environment, {
        'RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS' => $rabbitmq_additional_erl_args,
        'RABBITMQ_CTL_ERL_ARGS' => $rabbitmq_additional_erl_args,
      })
    } else {
      $environment_real = $environment
    }
    $configured_ssl_versions = undef
  }

  if $inet_dist_interface {
    $real_kernel_variables = merge(
      $kernel_variables,
      { 'inet_dist_use_interface' => ip_to_erl_format($inet_dist_interface) }
    )
  } else {
    $real_kernel_variables = $kernel_variables
  }

  $manage_service = lookup('rabbitmq::service_manage', undef, undef, true)
  if $step >= 1 {
    file { '/etc/rabbitmq/ssl-dist.conf':
      ensure  => file,
      content => template('tripleo/rabbitmq/ssl-dist.conf.erb'),
      owner   => 'rabbitmq',
      group   => 'rabbitmq',
      mode    => '0640',
    }
    # Specific configuration for multi-nodes or when running with Pacemaker.
    if count($nodes) > 1 or ! $manage_service {
      class { 'rabbitmq':
        config_cluster          => $manage_service,
        cluster_nodes           => $nodes,
        config_kernel_variables => $real_kernel_variables,
        config_variables        => $config_variables,
        environment_variables   => $environment_real,
        # TLS options
        ssl_cert                => $tls_certfile,
        ssl_key                 => $tls_keyfile,
        ssl_versions            => $configured_ssl_versions,
        ssl_verify              => $verify_server_peer,
        ipv6                    => $ipv6,
      }

      # when running multi-nodes without Pacemaker
      if $manage_service {
        rabbitmq_policy { 'ha-all@/':
          pattern    => '^(?!amq\.).*',
          definition => {
            'ha-mode' => 'all',
          },
        }
      }
    } else {
      # Standard configuration
      class { 'rabbitmq':
        config_kernel_variables => $kernel_variables,
        config_variables        => $config_variables,
        environment_variables   => $environment,
        # TLS options
        ssl_cert                => $tls_certfile,
        ssl_key                 => $tls_keyfile,
        ssl_versions            => $configured_ssl_versions,
        ipv6                    => $ipv6,
      }
    }
  }

  if $bootstrap_node and $::hostname == downcase($bootstrap_node) {
    $rabbitmq_bootstrapnode = true
  } else {
    $rabbitmq_bootstrapnode = false
  }

  if $rabbitmq_bootstrapnode and $step >= 2 {
    # When need to enforce the rabbitmq user inside a bootstrap node check for two reasons:
    # a) on HA the users get replicated by the cluster anyway
    # b) in the pacemaker profiles for rabbitmq we have an Exec['rabbitmq-ready'] -> Rabbitmq_User<||> collector
    #    which is applied only on the bootstrap node (because enforcing the readiness on all nodes can be problematic
    #    in situations like controller replacement)
    # Required for changing password on update scenario. Password will be changed only when
    # called explicity, THT enforces that the rabbitmq service is already running when we call this.
    rabbitmq_user { $rabbitmq_user :
      password => $rabbitmq_pass,
      admin    => true,
    }
  }
}

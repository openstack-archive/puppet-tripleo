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
#   Defaults to hiera('rabbitmq_config_variables').
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to undef
#
# [*environment*]
#   (Optional) RabbitMQ environment.
#   Defaults to hiera('rabbitmq_environment').
#
# [*inet_dist_interface*]
#   (Optional) Address to bind the inter-cluster interface
#   to. It is the inet_dist_use_interface option in the kernel variables
#   Defaults to hiera('rabbitmq::interface', undef).
#
# [*ipv6*]
#   (Optional) Whether to deploy RabbitMQ on IPv6 network.
#   Defaults to str2bool(hiera('rabbit_ipv6', false)).
#
# [*kernel_variables*]
#   (Optional) RabbitMQ environment.
#   Defaults to hiera('rabbitmq_environment').
#
# [*nodes*]
#   (Optional) Array of host(s) for RabbitMQ nodes.
#   Defaults to hiera('rabbitmq_node_names', []).
#
# [*rabbitmq_pass*]
#   (Optional) RabbitMQ Default Password.
#   Defaults to hiera('rabbitmq::default_pass')
#
# [*rabbitmq_user*]
#   (Optional) RabbitMQ Default User.
#   Defaults to hiera('rabbitmq::default_user')
#
# [*stack_action*]
#   (Optional) Action of the stack deployment.
#   Defaults to hiera('stack_action')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::rabbitmq (
  $certificate_specs             = {},
  $config_variables              = hiera('rabbitmq_config_variables'),
  $enable_internal_tls           = undef,  # TODO(jaosorior): pass this via t-h-t
  $environment                   = hiera('rabbitmq_environment'),
  $inet_dist_interface           = hiera('rabbitmq::interface', undef),
  $ipv6                          = str2bool(hiera('rabbit_ipv6', false)),
  $kernel_variables              = hiera('rabbitmq_kernel_variables'),
  $nodes                         = hiera('rabbitmq_node_names', []),
  $rabbitmq_pass                 = hiera('rabbitmq::default_pass'),
  $rabbitmq_user                 = hiera('rabbitmq::default_user'),
  $stack_action                  = hiera('stack_action'),
  $step                          = Integer(hiera('step')),
) {
  if $enable_internal_tls {
    $tls_certfile = $certificate_specs['service_certificate']
    $tls_keyfile = $certificate_specs['service_key']
    $cert_option = "-ssl_dist_opt server_certfile ${tls_certfile}"
    $key_option = "-ssl_dist_opt server_keyfile ${tls_keyfile}"
    $secure_renegotiate = '-ssl_dist_opt server_secure_renegotiate true -ssl_dist_opt client_secure_renegotiate true'

    $rabbitmq_additional_erl_args = "\"${cert_option} ${key_option} ${secure_renegotiate}\""
    $environment_real = merge($environment, {
      'RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS' => $rabbitmq_additional_erl_args,
      'RABBITMQ_CTL_ERL_ARGS' => $rabbitmq_additional_erl_args
    })
  } else {
    $tls_certfile = undef
    $tls_keyfile = undef
    $environment_real = $environment
  }

  if $inet_dist_interface {
    $real_kernel_variables = merge(
      $kernel_variables,
      { 'inet_dist_use_interface' => ip_to_erl_format($inet_dist_interface) }
    )
  } else {
    $real_kernel_variables = $kernel_variables
  }

  $manage_service = hiera('rabbitmq::service_manage', true)
  if $step >= 1 {
    # Specific configuration for multi-nodes or when running with Pacemaker.
    if count($nodes) > 1 or ! $manage_service {
      class { '::rabbitmq':
        config_cluster          => $manage_service,
        cluster_nodes           => $nodes,
        config_kernel_variables => $real_kernel_variables,
        config_variables        => $config_variables,
        environment_variables   => $environment_real,
        # TLS options
        ssl_cert                => $tls_certfile,
        ssl_key                 => $tls_keyfile,
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
      class { '::rabbitmq':
        config_kernel_variables => $kernel_variables,
        config_variables        => $config_variables,
        environment_variables   => $environment,
        # TLS options
        ssl_cert                => $tls_certfile,
        ssl_key                 => $tls_keyfile,
        ipv6                    => $ipv6,
      }
    }
  }

  if $step >= 2 {
    # In case of HA, starting of rabbitmq-server is managed by pacemaker, because of which, a dependency
    # to Service['rabbitmq-server'] will not work. Sticking with UPDATE action.
    if $stack_action == 'UPDATE' {
      # Required for changing password on update scenario. Password will be changed only when
      # called explicity, if the rabbitmq service is already running.
      rabbitmq_user { $rabbitmq_user :
        password => $rabbitmq_pass,
        admin    => true,
      }
    }
  }

  if $step >= 1 and hiera('veritas_hyperscale_controller_enabled', false) {
    include ::veritas_hyperscale::hs_rabbitmq
  }
}

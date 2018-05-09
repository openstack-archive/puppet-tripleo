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
# [*ssl_versions*]
#   (Optional) When enable_internal_tls is in use, list the enabled
#   TLS protocol version.
#   Defaults to undef
#
# [*inter_node_ciphers*]
#   (Optional) When enable_internal_tls is in use, list the allowed ciphers
#   for the encrypted inter-node communication.
# lint:ignore:140chars
#   Defaults to "ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:AES256-GCM-SHA384:AES256-SHA256:AES128-GCM-SHA256:AES128-SHA256:DHE-DSS-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA256:DHE-DSS-AES128-GCM-SHA256:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES128-SHA256:DHE-DSS-AES128-SHA256"
# lint:endignore
#   which is the list of ciphers enabled out of the openssl cipher list format
#   !SSLv2:kEECDH:kRSA:kEDH:kPSK:+3DES:!aNULL:!eNULL:!MD5:!EXP:!RC4:!SEED:!IDEA:!DES:!SSLv3:!TLSv1
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
# [*rpc_scheme*]
#   (Optional) Protocol for oslo messaging rpc backend.
#   Defaults to hiera('oslo_messaging_rpc_scheme', 'rabbit').
#
# [*rpc_nodes*]
#   (Optional) Array of host(s) for oslo messaging rpc nodes.
#   Defaults to hiera('oslo_messaging_rpc_node_names', []).
#
# [*rpc_bootstrap_node*]
#   (Optional) The hostname of the rpc node for bootstrapping tasks
#   Defaults to hiera('oslo_messaging_rpc_short_bootstrap_node_name')
#
# [*notify_scheme*]
#   (Optional) oslo messaging notify backend indicator.
#   Defaults to hiera('oslo_messaging_notify_scheme', 'rabbit').
#
# [*notify_nodes*]
#   (Optional) Array of host(s) for oslo messaging notify nodes.
#   Defaults to hiera('oslo_messaging_notify_node_names', []).
#
# [*notify_bootstrap_node*]
#   (Optional) The hostname of the notify node for bootstrapping tasks
#   Defaults to hiera('oslo_messaging_notify_short_bootstrap_node_name')
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
  $ssl_versions                  = undef,
  # lint:ignore:140chars
  $inter_node_ciphers            = 'ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:AES256-GCM-SHA384:AES256-SHA256:AES128-GCM-SHA256:AES128-SHA256:DHE-DSS-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA256:DHE-DSS-AES128-GCM-SHA256:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES128-SHA256:DHE-DSS-AES128-SHA256',
  # lint:endignore
  $inet_dist_interface           = hiera('rabbitmq::interface', undef),
  $ipv6                          = str2bool(hiera('rabbit_ipv6', false)),
  $kernel_variables              = hiera('rabbitmq_kernel_variables'),
  $rpc_scheme                    = hiera('oslo_messaging_rpc_scheme', 'rabbit'),
  $rpc_nodes                     = hiera('oslo_messaging_rpc_node_names', []),
  $rpc_bootstrap_node            = hiera('oslo_messaging_rpc_short_bootstrap_node_name'),
  $notify_scheme                 = hiera('oslo_messaging_notify_scheme', 'rabbit'),
  $notify_nodes                  = hiera('oslo_messaging_notify_node_names', []),
  $notify_bootstrap_node         = hiera('oslo_messaging_notify_short_bootstrap_node_name'),
  $rabbitmq_pass                 = hiera('rabbitmq::default_pass'),
  $rabbitmq_user                 = hiera('rabbitmq::default_user'),
  $stack_action                  = hiera('stack_action'),
  $step                          = Integer(hiera('step')),
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
    $cert_option = "-ssl_dist_opt server_certfile ${tls_certfile}"
    $key_option = "-ssl_dist_opt server_keyfile ${tls_keyfile}"
    $ciphers_option = "-ssl_dist_opt server_ciphers ${inter_node_ciphers}"
    $secure_renegotiate = '-ssl_dist_opt server_secure_renegotiate true -ssl_dist_opt client_secure_renegotiate true'

    $rabbitmq_additional_erl_args = "\"${cert_option} ${key_option} ${ciphers_option} ${secure_renegotiate}\""
    $environment_real = merge($environment, {
      'RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS' => $rabbitmq_additional_erl_args,
      'RABBITMQ_CTL_ERL_ARGS' => $rabbitmq_additional_erl_args
    })
    # Configure a list of secure transport protocols, unless the
    # user explicitly sets one
    if !defined(ssl_versions) {
      $configured_ssl_versions = ['tlsv1.2', 'tlsv1.1']
    } else {
      $configured_ssl_versions = $ssl_versions
    }
  } else {
    $tls_certfile = undef
    $tls_keyfile = undef
    $environment_real = $environment
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
        ssl_versions            => $configured_ssl_versions,
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
        ssl_versions            => $configured_ssl_versions,
        ipv6                    => $ipv6,
      }
    }
  }

  if $::hostname == downcase($bootstrap_node) {
    $rabbitmq_bootstrapnode = true
  } else {
    $rabbitmq_bootstrapnode = false
  }

  if $rabbitmq_bootstrapnode and $step >= 2 {
    # In case of HA, starting of rabbitmq-server is managed by pacemaker, because of which, a dependency
    # to Service['rabbitmq-server'] will not work. Sticking with UPDATE action.
    # When need to enforce the rabbitmq user inside a bootstrap node check for two reasons:
    # a) on HA the users get replicated by the cluster anyway
    # b) in the pacemaker profiles for rabbitmq we have an Exec['rabbitmq-ready'] -> Rabbitmq_User<||> collector
    #    which is applied only on the bootstrap node (because enforcing the readiness on all nodes can be problematic
    #    in situations like controller replacement)
    if $stack_action == 'UPDATE' {
      # Required for changing password on update scenario. Password will be changed only when
      # called explicity, if the rabbitmq service is already running.
      rabbitmq_user { $rabbitmq_user :
        password => $rabbitmq_pass,
        admin    => true,
      }
    }
    if hiera('veritas_hyperscale_controller_enabled', false) {
      include ::veritas_hyperscale::hs_rabbitmq
    }
  }

}

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
# == Class: tripleo::profile::pacemaker::haproxy
#
# HAproxy with Pacemaker HA profile for tripleo
#
# === Parameters
#
# [*haproxy_docker_image*]
#   (Optional) The docker image to use for creating the pacemaker bundle
#   Defaults to lookup('tripleo::profile::pacemaker::haproxy::haproxy_docker_image', undef, undef, undef)
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to lookup('haproxy_short_bootstrap_node_name')
#
# [*enable_load_balancer*]
#   (Optional) Whether load balancing is enabled for this cluster
#   Defaults to lookup('enable_load_balancer', undef, undef, true)
#
# [*ca_bundle*]
#   (Optional) The path to the CA file that will be used for the TLS
#   configuration. It's only used if internal TLS is enabled.
#   Defaults to lookup('tripleo::haproxy::ca_bundle', undef, undef, undef)
#
# [*crl_file*]
#   (Optional) The path to the file that contains the certificate
#   revocation list. It's only used if internal TLS is enabled.
#   Defaults to lookup('tripleo::haproxy::crl_file', undef, undef, undef)
#
# [*deployed_ssl_cert_path*]
#   (Optional) The filepath of the certificate as it will be stored in
#   the controller.
#   Defaults to lookup('tripleo::haproxy::service_certificate', undef, undef, undef)
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to lookup('enable_internal_tls', undef, undef, false)
#
# [*internal_certs_directory*]
#   (Optional) Directory the holds the certificates to be used when
#   when TLS is enabled in the internal network
#   Defaults to undef
#
# [*internal_keys_directory*]
#   (Optional) Directory the holds the certificates to be used when
#   when TLS is enabled in the internal network
#   Defaults to undef
#
# [*meta_params*]
#   (optional) Additional meta parameters to pass to "pcs resource create" for the VIP
#   Defaults to ''
#
# [*op_params*]
#   (optional) Additional op parameters to pass to "pcs resource create" for the VIP
#   Defaults to ''
#
# [*container_backend*]
#   (optional) Container backend to use when creating the bundle
#   Defaults to 'podman'
#
# [*log_driver*]
#   (optional) Container log driver to use.
#   Defaults to 'k8s-file'
#
# [*log_file*]
#   (optional) Container log file to use. Only relevant when log_driver is
#   set to 'k8s-file'.
#   Defaults to '/var/log/containers/stdouts/haproxy-bundle.log'
#
# [*tls_priorities*]
#   (optional) Sets PCMK_tls_priorities in /etc/sysconfig/pacemaker when set
#   Defaults to lookup('tripleo::pacemaker::tls_priorities', undef, undef, undef)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
# [*pcs_tries*]
#   (Optional) The number of times pcs commands should be retried.
#   Defaults to lookup('pcs_tries', undef, undef, 20)
#
# [*bundle_user*]
#   (optional) Set the --user= switch to be passed to pcmk
#   Defaults to 'root'
#
# [*force_nic*]
#   (optional) Force a specific nic interface name when creating all the VIPs
#   The listening nic can be customized on a per-VIP basis by creating a hiera
#   dict called: force_vip_nic_overrides[<vip/network name>] = 'dummy'
#   Defaults to lookup('tripleo::pacemaker::force_nic', undef, undef, undef)
#
class tripleo::profile::pacemaker::haproxy_bundle (
  $haproxy_docker_image     = lookup('tripleo::profile::pacemaker::haproxy::haproxy_docker_image', undef, undef, undef),
  $bootstrap_node           = lookup('haproxy_short_bootstrap_node_name'),
  $enable_load_balancer     = lookup('enable_load_balancer', undef, undef, true),
  $ca_bundle                = lookup('tripleo::haproxy::ca_bundle', undef, undef, undef),
  $crl_file                 = lookup('tripleo::haproxy::crl_file', undef, undef, undef),
  $enable_internal_tls      = lookup('enable_internal_tls', undef, undef, false),
  $internal_certs_directory = undef,
  $internal_keys_directory  = undef,
  $deployed_ssl_cert_path   = lookup('tripleo::haproxy::service_certificate', undef, undef, undef),
  $meta_params              = '',
  $op_params                = '',
  $container_backend        = 'podman',
  $tls_priorities           = lookup('tripleo::pacemaker::tls_priorities', undef, undef, undef),
  $bundle_user              = 'root',
  $force_nic                = lookup('tripleo::pacemaker::force_nic', undef, undef, undef),
  $log_driver               = 'k8s-file',
  $log_file                 = '/var/log/containers/stdouts/haproxy-bundle.log',
  $step                     = Integer(lookup('step')),
  $pcs_tries                = lookup('pcs_tries', undef, undef, 20),
) {
  include tripleo::profile::base::haproxy

  if $bootstrap_node and $::hostname == downcase($bootstrap_node) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  if $log_driver == 'k8s-file' {
    $log_file_real = " --log-opt path=${log_file}"
  } else {
    $log_file_real = ''
  }
  $force_vip_nic_overrides = lookup('force_vip_nic_overrides', undef, undef, {})
  validate_legacy(Hash, 'validate_hash',  $force_vip_nic_overrides)

  if $step >= 2 and $enable_load_balancer {
    if $pacemaker_master {
      if (lookup('haproxy_short_node_names_override', undef, undef, undef)) {
        $haproxy_short_node_names = lookup('haproxy_short_node_names_override')
      } else {
        $haproxy_short_node_names = lookup('haproxy_short_node_names')
      }

      $haproxy_short_node_names.each |String $node_name| {
        pacemaker::property { "haproxy-role-${node_name}":
          property => 'haproxy-role',
          value    => true,
          tries    => $pcs_tries,
          node     => downcase($node_name),
          before   => Pacemaker::Resource::Bundle['haproxy-bundle'],
        }
      }
      $haproxy_location_rule = {
        resource_discovery => 'exclusive',
        score              => 0,
        expression         => ['haproxy-role eq true'],
      }
      # FIXME: we should not have to access tripleo::haproxy class
      # parameters here to configure pacemaker VIPs. The configuration
      # of pacemaker VIPs could move into puppet-tripleo or we should
      # make use of less specific hiera parameters here for the settings.
      $haproxy_nodes = lookup('haproxy_short_node_names')
      $haproxy_nodes_count = count($haproxy_nodes)


      $storage_maps = {
          'haproxy-cfg-files'               => {
            'source-dir' => '/var/lib/kolla/config_files/haproxy.json',
            'target-dir' => '/var/lib/kolla/config_files/config.json',
            'options'    => 'ro',
          },
          'haproxy-cfg-data'                => {
            'source-dir' => '/var/lib/config-data/puppet-generated/haproxy/',
            'target-dir' => '/var/lib/kolla/config_files/src',
            'options'    => 'ro',
          },
          'haproxy-hosts'                   => {
            'source-dir' => '/etc/hosts',
            'target-dir' => '/etc/hosts',
            'options'    => 'ro',
          },
          'haproxy-localtime'               => {
            'source-dir' => '/etc/localtime',
            'target-dir' => '/etc/localtime',
            'options'    => 'ro',
          },
          'haproxy-var-lib'                 => {
            'source-dir' => '/var/lib/haproxy',
            'target-dir' => '/var/lib/haproxy',
            'options'    => 'rw,z',
          },
          'haproxy-pki-extracted'           => {
            'source-dir' => '/etc/pki/ca-trust/extracted',
            'target-dir' => '/etc/pki/ca-trust/extracted',
            'options'    => 'ro',
          },
          'haproxy-pki-ca-bundle-crt'       => {
            'source-dir' => '/etc/pki/tls/certs/ca-bundle.crt',
            'target-dir' => '/etc/pki/tls/certs/ca-bundle.crt',
            'options'    => 'ro',
          },
          'haproxy-pki-ca-bundle-trust-crt' => {
            'source-dir' => '/etc/pki/tls/certs/ca-bundle.trust.crt',
            'target-dir' => '/etc/pki/tls/certs/ca-bundle.trust.crt',
            'options'    => 'ro',
          },
          'haproxy-pki-cert'                => {
            'source-dir' => '/etc/pki/tls/cert.pem',
            'target-dir' => '/etc/pki/tls/cert.pem',
            'options'    => 'ro',
          },
          'haproxy-dev-log'                 => {
            'source-dir' => '/dev/log',
            'target-dir' => '/dev/log',
            'options'    => 'rw',
          },
      };

      if $deployed_ssl_cert_path {
        $cert_storage_maps = {
          'haproxy-cert' => {
            'source-dir' => $deployed_ssl_cert_path,
            'target-dir' => "/var/lib/kolla/config_files/src-tls${deployed_ssl_cert_path}",
            'options'    => 'ro',
          },
        }
      } else {
        $cert_storage_maps = {}
      }

      if $enable_internal_tls {
        $haproxy_storage_maps = {
          'haproxy-pki-certs'  => {
            'source-dir' => $internal_certs_directory,
            'target-dir' => "/var/lib/kolla/config_files/src-tls${internal_certs_directory}",
            'options'    => 'ro',
          },
          'haproxy-pki-keys' => {
            'source-dir' => $internal_keys_directory,
            'target-dir' => "/var/lib/kolla/config_files/src-tls${internal_keys_directory}",
            'options'    => 'ro',
          },
        }
        if $ca_bundle {
          $ca_storage_maps = {
            'haproxy-pki-ca-file' => {
              'source-dir' => $ca_bundle,
              'target-dir' => "/var/lib/kolla/config_files/src-tls${ca_bundle}",
              'options'    => 'ro',
            },
          }
        } else {
          $ca_storage_maps = {}
        }
        if $crl_file {
          $crl_storage_maps = {
            'haproxy-pki-crl-file' => {
              'source-dir' => $crl_file,
              'target-dir' => $crl_file,
              'options'    => 'ro',
            },
          }
        } else {
          $crl_storage_maps = {}
        }
        $storage_maps_internal_tls = merge($haproxy_storage_maps, $ca_storage_maps, $crl_storage_maps)
      } else {
        $storage_maps_internal_tls = {}
      }

      if $tls_priorities != undef {
        $tls_priorities_real = " -e PCMK_tls_priorities=${tls_priorities}"
      } else {
        $tls_priorities_real = ''
      }

      pacemaker::resource::bundle { 'haproxy-bundle':
        image             => $haproxy_docker_image,
        replicas          => $haproxy_nodes_count,
        location_rule     => $haproxy_location_rule,
        container_options => 'network=host',
        # lint:ignore:140chars
        options           => "--user=${bundle_user} --log-driver=${log_driver}${log_file_real} -e KOLLA_CONFIG_STRATEGY=COPY_ALWAYS${tls_priorities_real}",
        # lint:endignore
        run_command       => '/bin/bash /usr/local/bin/kolla_start',
        storage_maps      => merge($storage_maps, $cert_storage_maps, $storage_maps_internal_tls),
        container_backend => $container_backend,
        tries             => $pcs_tries,
      }
      $control_vip = lookup('controller_virtual_ip')
      if has_key($force_vip_nic_overrides, 'controller_virtual_ip') {
        $control_vip_nic = $force_vip_nic_overrides['controller_virtual_ip']
      } else {
        $control_vip_nic = $force_nic
      }
      tripleo::pacemaker::haproxy_with_vip { 'haproxy_and_control_vip':
        vip_name      => 'control',
        ip_address    => $control_vip,
        location_rule => $haproxy_location_rule,
        meta_params   => $meta_params,
        op_params     => $op_params,
        nic           => $control_vip_nic,
        pcs_tries     => $pcs_tries,
      }

      $public_vip = lookup('public_virtual_ip')
      if has_key($force_vip_nic_overrides, 'public_virtual_ip') {
        $public_vip_nic = $force_vip_nic_overrides['public_virtual_ip']
      } else {
        $public_vip_nic = $force_nic
      }
      tripleo::pacemaker::haproxy_with_vip { 'haproxy_and_public_vip':
        ensure        => $public_vip and $public_vip != $control_vip,
        vip_name      => 'public',
        ip_address    => $public_vip,
        location_rule => $haproxy_location_rule,
        meta_params   => $meta_params,
        op_params     => $op_params,
        nic           => $public_vip_nic,
        pcs_tries     => $pcs_tries,
      }

      $redis = lookup('redis_enabled', undef, undef, false)
      if $redis {
        $redis_vip = lookup('redis_vip')
        if has_key($force_vip_nic_overrides, 'redis_vip') {
          $redis_vip_nic = $force_vip_nic_overrides['redis_vip']
        } else {
          $redis_vip_nic = $force_nic
        }
        tripleo::pacemaker::haproxy_with_vip { 'haproxy_and_redis_vip':
          ensure        => $redis_vip and $redis_vip != $control_vip,
          vip_name      => 'redis',
          ip_address    => $redis_vip,
          location_rule => $haproxy_location_rule,
          meta_params   => $meta_params,
          op_params     => $op_params,
          nic           => $redis_vip_nic,
          pcs_tries     => $pcs_tries,
        }
      }

      # Set up all vips for isolated networks
      $network_vips = lookup('network_virtual_ips', undef, undef, {})
      $network_vips.each |String $net_name, $vip_info| {
        $virtual_ip = $vip_info[ip_address]
        if has_key($force_vip_nic_overrides, $net_name) {
          $vip_nic = $force_vip_nic_overrides[$net_name]
        } else {
          $vip_nic = $force_nic
        }
        tripleo::pacemaker::haproxy_with_vip {"haproxy_and_${net_name}_vip":
          ensure        => $virtual_ip and $virtual_ip != $control_vip,
          vip_name      => $net_name,
          ip_address    => $virtual_ip,
          location_rule => $haproxy_location_rule,
          meta_params   => $meta_params,
          op_params     => $op_params,
          nic           => $vip_nic,
          pcs_tries     => $pcs_tries,
        }
      }
    }
  }

}

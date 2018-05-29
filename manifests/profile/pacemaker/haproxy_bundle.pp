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
#   Defaults to hiera('tripleo::profile::pacemaker::haproxy::haproxy_docker_image', undef)
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('haproxy_short_bootstrap_node_name')
#
# [*enable_load_balancer*]
#   (Optional) Whether load balancing is enabled for this cluster
#   Defaults to hiera('enable_load_balancer', true)
#
# [*ca_bundle*]
#   (Optional) The path to the CA file that will be used for the TLS
#   configuration. It's only used if internal TLS is enabled.
#   Defaults to hiera('tripleo::haproxy::ca_bundle', undef)
#
# [*crl_file*]
#   (Optional) The path to the file that contains the certificate
#   revocation list. It's only used if internal TLS is enabled.
#   Defaults to hiera('tripleo::haproxy::crl_file', undef)
#
# [*deployed_ssl_cert_path*]
#   (Optional) The filepath of the certificate as it will be stored in
#   the controller.
#   Defaults to hiera('tripleo::haproxy::service_certificate', undef)
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to hiera('enable_internal_tls', false)
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
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*pcs_tries*]
#   (Optional) The number of times pcs commands should be retried.
#   Defaults to hiera('pcs_tries', 20)
#
class tripleo::profile::pacemaker::haproxy_bundle (
  $haproxy_docker_image     = hiera('tripleo::profile::pacemaker::haproxy::haproxy_docker_image', undef),
  $bootstrap_node           = hiera('haproxy_short_bootstrap_node_name'),
  $enable_load_balancer     = hiera('enable_load_balancer', true),
  $ca_bundle                = hiera('tripleo::haproxy::ca_bundle', undef),
  $crl_file                 = hiera('tripleo::haproxy::crl_file', undef),
  $enable_internal_tls      = hiera('enable_internal_tls', false),
  $internal_certs_directory = undef,
  $internal_keys_directory  = undef,
  $deployed_ssl_cert_path   = hiera('tripleo::haproxy::service_certificate', undef),
  $step                     = Integer(hiera('step')),
  $pcs_tries                = hiera('pcs_tries', 20),
) {
  include ::tripleo::profile::base::haproxy

  if $::hostname == downcase($bootstrap_node) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  if $step >= 1 and $pacemaker_master and hiera('stack_action') == 'UPDATE' and $enable_load_balancer {
    tripleo::pacemaker::resource_restart_flag { 'haproxy-clone':
      subscribe => Concat['/etc/haproxy/haproxy.cfg'],
    }
  }

  if $step >= 2 and $enable_load_balancer {
    if $pacemaker_master {
      $haproxy_short_node_names = hiera('haproxy_short_node_names')
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
      $haproxy_nodes = hiera('haproxy_short_node_names')
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
            'options'    => 'rw',
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

      pacemaker::resource::bundle { 'haproxy-bundle':
        image             => $haproxy_docker_image,
        replicas          => $haproxy_nodes_count,
        location_rule     => $haproxy_location_rule,
        container_options => 'network=host',
        options           => '--user=root --log-driver=journald -e KOLLA_CONFIG_STRATEGY=COPY_ALWAYS',
        run_command       => '/bin/bash /usr/local/bin/kolla_start',
        storage_maps      => merge($storage_maps, $cert_storage_maps, $storage_maps_internal_tls),
      }
      $control_vip = hiera('controller_virtual_ip')
      tripleo::pacemaker::haproxy_with_vip { 'haproxy_and_control_vip':
        vip_name      => 'control',
        ip_address    => $control_vip,
        location_rule => $haproxy_location_rule,
        pcs_tries     => $pcs_tries,
      }

      $public_vip = hiera('public_virtual_ip')
      tripleo::pacemaker::haproxy_with_vip { 'haproxy_and_public_vip':
        ensure        => $public_vip and $public_vip != $control_vip,
        vip_name      => 'public',
        ip_address    => $public_vip,
        location_rule => $haproxy_location_rule,
        pcs_tries     => $pcs_tries,
      }

      $redis_vip = hiera('redis_vip')
      tripleo::pacemaker::haproxy_with_vip { 'haproxy_and_redis_vip':
        ensure        => $redis_vip and $redis_vip != $control_vip,
        vip_name      => 'redis',
        ip_address    => $redis_vip,
        location_rule => $haproxy_location_rule,
        pcs_tries     => $pcs_tries,
      }

      # Set up all vips for isolated networks
      $network_vips = hiera('network_virtual_ips', {})
      $network_vips.each |String $net_name, $vip_info| {
        $virtual_ip = $vip_info[ip_address]
        tripleo::pacemaker::haproxy_with_vip {"haproxy_and_${net_name}_vip":
          ensure        => $virtual_ip and $virtual_ip != $control_vip,
          vip_name      => $net_name,
          ip_address    => $virtual_ip,
          location_rule => $haproxy_location_rule,
          pcs_tries     => $pcs_tries,
        }
      }
    }
  }

}

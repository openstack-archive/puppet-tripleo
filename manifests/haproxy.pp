# Copyright 2014 Red Hat, Inc.
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

# == Class: tripleo::haproxy
#
# Configure HAProxy for TripleO.
#
# === Parameters:
#
# [*haproxy_service_manage*]
#  Will be passed as value for service_manage to HAProxy module.
#  Defaults to true
#
# [*haproxy_global_maxconn*]
#  The value to use as maxconn in the HAProxy global config section.
#  Defaults to 20480
#
# [*haproxy_default_maxconn*]
#  The value to use as maxconn in the HAProxy default config section.
#  Defaults to 4096
#
# [*haproxy_default_timeout*]
#  The value to use as timeout in the HAProxy default config section.
#  Defaults to [ 'http-request 10s', 'queue 2m', 'connect 10s', 'client 2m', 'server 2m', 'check 10s' ]
#
# [*haproxy_listen_bind_param*]
#  A list of params to be added to the HAProxy listener bind directive. By
#  default the 'transparent' param is added but it should be cleared if
#  one of the *_virtual_ip addresses is a wildcard, eg. 0.0.0.0
#  Defaults to [ 'transparent' ]
#
# [*haproxy_member_options*]
#  The default options to use for the HAProxy balancer members.
#  Defaults to [ 'check', 'inter 2000', 'rise 2', 'fall 5' ]
#
# [*haproxy_log_address*]
#  The IPv4, IPv6 or filesystem socket path of the syslog server.
#  Defaults to '/dev/log'
#
# [*controller_hosts*]
#  IPs of host or group of hosts to load-balance the services
#  Can be a string or an array.
#  Defaults tohiera('controller_node_ips')
#
# [*controller_hosts_names*]
#  Names of host or group of hosts to load-balance the services
#  Can be a string or an array.
#  Defaults to hiera('controller_node_names', undef)
#
# [*controller_virtual_ip*]
#  Control IP or group of IPs to bind the pools
#  Can be a string or an array.
#  Defaults to undef
#
# [*contrail_config_hosts*]
#  (optional) Specify the contrail config hosts ips.
#  Defaults to hiera('contrail_config_node_ips')
#
# [*contrail_config_hosts_names*]
#  (optional) Specify the contrail config hosts.
#  Defaults to hiera('contrail_config_node_ips')
#
# [*contrail_config*]
#  (optional) Switch to check that contrail config is enabled.
#  Defaults to hiera('contrail_config_enabled')
#
# [*contrail_webui*]
#  (optional) Switch to check that contrail config is enabled.
#  Defaults to hiera('contrail_webui_enabled')
#
# [*contrail_analytics*]
#  (optional) Switch to check that contrail config is enabled.
#  Defaults to hiera('contrail_analytics_enabled')
#
# [*public_virtual_ip*]
#  Public IP or group of IPs to bind the pools
#  Can be a string or an array.
#  Defaults to undef
# [*haproxy_stats_user*]
#
#  Username for haproxy stats authentication.
#  A string.
#  Defaults to 'admin'
#
# [*haproxy_stats_password*]
#  Password for haproxy stats authentication.  When set, authentication is
#  enabled on the haproxy stats endpoint.
#  A string.
#  Defaults to undef
#
# [*service_certificate*]
#  Filename of an HAProxy-compatible certificate and key file
#  When set, enables SSL on the public API endpoints using the specified file.
#  Defaults to undef
#
# [*use_internal_certificates*]
#  Flag that indicates if we'll use an internal certificate for this specific
#  service. When set, enables SSL on the internal API endpoints using the file
#  that certmonger is tracking; this is derived from the network the service is
#  listening on.
#  Defaults to false
#
# [*internal_certificates_specs*]
#  A hash that should contain the specs that were used to create the
#  certificates. As the name indicates, only the internal certificates will be
#  fetched from here. And the keys should follow the following pattern
#  "haproxy-<network name>". The network name should be as it was defined in
#  tripleo-heat-templates.
#  Note that this is only taken into account if the $use_internal_certificates
#  flag is set.
#  Defaults to {}
#
# [*enable_internal_tls*]
#  A flag that indicates if the servers in the internal network are using TLS.
#  This enables the 'ssl' option for the server members that are proxied.
#  Defaults to hiera('enable_internal_tls', false)
#
# [*ssl_cipher_suite*]
#  The default string describing the list of cipher algorithms ("cipher suite")
#  that are negotiated during the SSL/TLS handshake for all "bind" lines. This
#  value comes from the Fedora system crypto policy.
#  Defaults to '!SSLv2:kEECDH:kRSA:kEDH:kPSK:+3DES:!aNULL:!eNULL:!MD5:!EXP:!RC4:!SEED:!IDEA:!DES'
#
# [*ssl_options*]
#  String that sets the default ssl options to force on all "bind" lines.
#  Defaults to 'no-sslv3'
#
# [*ca_bundle*]
#  Path to the CA bundle to be used for HAProxy to validate the certificates of
#  the servers it balances
#  Defaults to '/etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt'
#
# [*haproxy_stats_certificate*]
#  Filename of an HAProxy-compatible certificate and key file
#  When set, enables SSL on the haproxy stats endpoint using the specified file.
#  Defaults to undef
#
# [*keystone_admin*]
#  (optional) Enable or not Keystone Admin API binding
#  Defaults to hiera('keystone_enabled', false)
#
# [*keystone_public*]
#  (optional) Enable or not Keystone Public API binding
#  Defaults to hiera('keystone_enabled', false)
#
# [*neutron*]
#  (optional) Enable or not Neutron API binding
#  Defaults to hiera('neutron_api_enabled', false)
#
# [*cinder*]
#  (optional) Enable or not Cinder API binding
#  Defaults to hiera('cinder_api_enabled', false)
#
# [*congress*]
#  (optional) Enable or not Congress API binding
#  Defaults to hiera('congress_enabled', false)
#
# [*manila*]
#  (optional) Enable or not Manila API binding
#  Defaults to hiera('manila_api_enabled', false)
#
# [*sahara*]
#  (optional) Enable or not Sahara API binding
#  defaults to hiera('sahara_api_enabled', false)
#
# [*tacker*]
#  (optional) Enable or not Tacker API binding
#  Defaults to hiera('tacker_enabled', false)
#
# [*trove*]
#  (optional) Enable or not Trove API binding
#  defaults to hiera('trove_api_enabled', false)
#
# [*glance_api*]
#  (optional) Enable or not Glance API binding
#  Defaults to hiera('glance_api_enabled', false)
#
# [*nova_osapi*]
#  (optional) Enable or not Nova API binding
#  Defaults to hiera('nova_api_enabled', false)
#
# [*nova_placement*]
#  (optional) Enable or not Nova Placement API binding
#  Defaults to hiera('nova_placement_enabled', false)
#
# [*nova_metadata*]
#  (optional) Enable or not Nova metadata binding
#  Defaults to hiera('nova_api_enabled', false)
#
# [*nova_novncproxy*]
#  (optional) Enable or not Nova novncproxy binding
#  Defaults to hiera('nova_vnc_proxy_enabled', false)
#
# [*ec2_api*]
#  (optional) Enable or not EC2 API binding
#  Defaults to hiera('ec2_api_enabled', false)
#
# [*ec2_api_metadata*]
#  (optional) Enable or not EC2 API metadata binding
#  Defaults to hiera('ec2_api_enabled', false)
#
# [*ceilometer*]
#  (optional) Enable or not Ceilometer API binding
#  Defaults to hiera('ceilometer_api_enabled', false)
#
# [*aodh*]
#  (optional) Enable or not Aodh API binding
#  Defaults to hiera('aodh_api_enabled', false)
#
# [*panko*]
#  (optional) Enable or not Panko API binding
#  Defaults to hiera('panko_api_enabled', false)
#
# [*barbican*]
#  (optional) Enable or not Barbican API binding
#  Defaults to hiera('barbican_api_enabled', false)
#
# [*gnocchi*]
#  (optional) Enable or not Gnocchi API binding
#  Defaults to hiera('gnocchi_api_enabled', false)
#
# [*mistral*]
#  (optional) Enable or not Mistral API binding
#  Defaults to hiera('mistral_api_enabled', false)
#
# [*swift_proxy_server*]
#  (optional) Enable or not Swift API binding
#  Defaults to hiera('swift_proxy_enabled', false)
#
# [*heat_api*]
#  (optional) Enable or not Heat API binding
#  Defaults to hiera('heat_api_enabled', false)
#
# [*heat_cloudwatch*]
#  (optional) Enable or not Heat Cloudwatch API binding
#  Defaults to hiera('heat_api_cloudwatch_enabled', false)
#
# [*heat_cfn*]
#  (optional) Enable or not Heat CFN API binding
#  Defaults to hiera('heat_api_cfn_enabled', false)
#
# [*horizon*]
#  (optional) Enable or not Horizon dashboard binding
#  Defaults to hiera('horizon_enabled', false)
#
# [*ironic*]
#  (optional) Enable or not Ironic API binding
#  Defaults to hiera('ironic_enabled', false)
#
# [*ironic_inspector*]
#  (optional) Enable or not Ironic Inspector API binding
#  Defaults to hiera('ironic_inspector_enabled', false)
#
# [*mysql*]
#  (optional) Enable or not MySQL Galera binding
#  Defaults to hiera('mysql_enabled', false)
#
# [*mysql_clustercheck*]
#  (optional) Enable check via clustercheck for mysql
#  Defaults to false
#
# [*mysql_member_options*]
#  The options to use for the mysql HAProxy balancer members.
#  If this parameter is undefined, the actual value configured will depend
#  on the value of $mysql_clustercheck. If cluster checking is enabled,
#  the mysql member options will be: "['backup', 'port 9200', 'on-marked-down shutdown-sessions', 'check', 'inter 1s']"
#  and if mysql cluster checking is disabled, the member options will be: "union($haproxy_member_options, ['backup'])"
#  Defaults to undef
#
# [*rabbitmq*]
#  (optional) Enable or not RabbitMQ binding
#  Defaults to false
#
# [*etcd*]
#  (optional) Enable or not Etcd binding
#  Defaults to hiera('etcd_enabled', false)
#
# [*docker_registry*]
#  (optional) Enable or not the Docker Registry API binding
#  Defaults to hiera('enable_docker_registry', false)
#
# [*redis*]
#  (optional) Enable or not Redis binding
#  Defaults to hiera('redis_enabled', false)
#
# [*redis_password*]
#  (optional) Password for Redis authentication, eventually needed by the
#  specific monitoring we do from HAProxy for Redis
#  Defaults to undef
#
# [*midonet_api*]
#  (optional) Enable or not MidoNet API binding
#  Defaults to false
#
# [*zaqar_api*]
#  (optional) Enable or not Zaqar Api binding
#  Defaults to hiera('zaqar_api_enabled', false)
#
# [*ceph_rgw*]
#  (optional) Enable or not Ceph RadosGW binding
#  Defaults to hiera('ceph_rgw_enabled', false)
#
# [*opendaylight*]
#  (optional) Enable or not OpenDaylight binding
#  Defaults to hiera('opendaylight_api_enabled', false)
#
# [*ovn_dbs*]
#  (optional) Enable or not OVN northd binding
#  Defaults to hiera('ovn_dbs_enabled', false)
#
# [*zaqar_ws*]
#  (optional) Enable or not Zaqar Websockets binding
#  Defaults to false
#
# [*ui*]
#  (optional) Enable or not TripleO UI
#  Defaults to false
#
# [*aodh_network*]
#  (optional) Specify the network aodh is running on.
#  Defaults to hiera('aodh_api_network', undef)
#
# [*barbican_network*]
#  (optional) Specify the network barbican is running on.
#  Defaults to hiera('barbican_api_network', undef)
#
# [*ceilometer_network*]
#  (optional) Specify the network ceilometer is running on.
#  Defaults to hiera('ceilometer_api_network', undef)
#
# [*ceph_rgw_network*]
#  (optional) Specify the network ceph_rgw is running on.
#  Defaults to hiera('ceph_rgw_network', undef)
#
# [*cinder_network*]
#  (optional) Specify the network cinder is running on.
#  Defaults to hiera('cinder_api_network', undef)
#
# [*congress_network*]
#  (optional) Specify the network congress is running on.
#  Defaults to hiera('congress_api_network', undef)
#
# [*docker_registry_network*]
#  (optional) Specify the network docker-registry is running on.
#  Defaults to hiera('docker_registry_network', undef)
#
# [*glance_api_network*]
#  (optional) Specify the network glance_api is running on.
#  Defaults to hiera('glance_api_network', undef)
#
# [*gnocchi_network*]
#  (optional) Specify the network gnocchi is running on.
#  Defaults to hiera('gnocchi_api_network', undef)
#
# [*heat_api_network*]
#  (optional) Specify the network heat_api is running on.
#  Defaults to hiera('heat_api_network', undef)
#
# [*heat_cfn_network*]
#  (optional) Specify the network heat_cfn is running on.
#  Defaults to hiera('heat_api_cfn_network', undef)
#
# [*heat_cloudwatch_network*]
#  (optional) Specify the network heat_cloudwatch is running on.
#  Defaults to hiera('heat_api_cloudwatch_network', undef)
#
# [*ironic_inspector_network*]
#  (optional) Specify the network ironic_inspector is running on.
#  Defaults to hiera('ironic_inspector_network', undef)
#
# [*ironic_network*]
#  (optional) Specify the network ironic is running on.
#  Defaults to hiera('ironic_api_network', undef)
#
# [*keystone_admin_network*]
#  (optional) Specify the network keystone_admin is running on.
#  Defaults to hiera('keystone_network', undef)
#
# [*keystone_public_network*]
#  (optional) Specify the network keystone_public is running on.
#  Defaults to hiera('keystone_network', undef)
#
# [*manila_network*]
#  (optional) Specify the network manila is running on.
#  Defaults to hiera('manila_api_network', undef)
#
# [*mistral_network*]
#  (optional) Specify the network mistral is running on.
#  Defaults to hiera('mistral_api_network', undef)
#
# [*neutron_network*]
#  (optional) Specify the network neutron is running on.
#  Defaults to hiera('neutron_api_network', undef)
#
# [*nova_metadata_network*]
#  (optional) Specify the network nova_metadata is running on.
#  Defaults to hiera('nova_api_network', undef)
#
# [*nova_novncproxy_network*]
#  (optional) Specify the network nova_novncproxy is running on.
#  Defaults to hiera('nova_vncproxy_network', undef)
#
# [*nova_osapi_network*]
#  (optional) Specify the network nova_osapi is running on.
#  Defaults to hiera('nova_api_network', undef)
#
# [*nova_placement_network*]
#  (optional) Specify the network nova_placement is running on.
#  Defaults to hiera('nova_placement_network', undef)
#
# [*ec2_api_network*]
#  (optional) Specify the network ec2_api is running on.
#  Defaults to hiera('ec2_api_network', undef)
#
# [*ec2_api_metadata_network*]
#  (optional) Specify the network ec2_api_metadata is running on.
#  Defaults to hiera('ec2_api_network', undef)
#
# [*opendaylight_network*]
#  (optional) Specify the network opendaylight is running on.
#  Defaults to hiera('opendaylight_api_network', undef)
#
# [*panko_network*]
#  (optional) Specify the network panko is running on.
#  Defaults to hiera('panko_api_network', undef)
#
# [*ovn_dbs_network*]
#  (optional) Specify the network ovn_dbs is running on.
#  Defaults to hiera('ovn_dbs_network', undef)
#
# [*sahara_network*]
#  (optional) Specify the network sahara is running on.
#  Defaults to hiera('sahara_api_network', undef)
#
# [*swift_proxy_server_network*]
#  (optional) Specify the network swift_proxy_server is running on.
#  Defaults to hiera('swift_proxy_network', undef)
#
# [*tacker_network*]
#  (optional) Specify the network tacker is running on.
#  Defaults to hiera('tacker_api_network', undef)
#
# [*trove_network*]
#  (optional) Specify the network trove is running on.
#  Defaults to hiera('trove_api_network', undef)
#
# [*zaqar_api_network*]
#  (optional) Specify the network zaqar_api is running on.
#  Defaults to hiera('zaqar_api_network', undef)
#
# [*service_ports*]
#  (optional) Hash that contains the values to override from the service ports
#  The available keys to modify the services' ports are:
#    'aodh_api_port' (Defaults to 8042)
#    'aodh_api_ssl_port' (Defaults to 13042)
#    'barbican_api_port' (Defaults to 9311)
#    'barbican_api_ssl_port' (Defaults to 13311)
#    'ceilometer_api_port' (Defaults to 8777)
#    'ceilometer_api_ssl_port' (Defaults to 13777)
#    'cinder_api_port' (Defaults to 8776)
#    'cinder_api_ssl_port' (Defaults to 13776)
#    'docker_registry_port' (Defaults to 8787)
#    'docker_registry_ssl_port' (Defaults to 13787)
#    'glance_api_port' (Defaults to 9292)
#    'glance_api_ssl_port' (Defaults to 13292)
#    'gnocchi_api_port' (Defaults to 8041)
#    'gnocchi_api_ssl_port' (Defaults to 13041)
#    'mistral_api_port' (Defaults to 8989)
#    'mistral_api_ssl_port' (Defaults to 13989)
#    'heat_api_port' (Defaults to 8004)
#    'heat_api_ssl_port' (Defaults to 13004)
#    'heat_cfn_port' (Defaults to 8000)
#    'heat_cfn_ssl_port' (Defaults to 13005)
#    'heat_cw_port' (Defaults to 8003)
#    'heat_cw_ssl_port' (Defaults to 13003)
#    'ironic_api_port' (Defaults to 6385)
#    'ironic_api_ssl_port' (Defaults to 13385)
#    'ironic_inspector_port' (Defaults to 5050)
#    'ironic_inspector_ssl_port' (Defaults to 13050)
#    'keystone_admin_api_port' (Defaults to 35357)
#    'keystone_admin_api_ssl_port' (Defaults to 13357)
#    'keystone_public_api_port' (Defaults to 5000)
#    'keystone_public_api_ssl_port' (Defaults to 13000)
#    'manila_api_port' (Defaults to 8786)
#    'manila_api_ssl_port' (Defaults to 13786)
#    'neutron_api_port' (Defaults to 9696)
#    'neutron_api_ssl_port' (Defaults to 13696)
#    'nova_api_port' (Defaults to 8774)
#    'nova_api_ssl_port' (Defaults to 13774)
#    'nova_placement_port' (Defaults to 8778)
#    'nova_placement_ssl_port' (Defaults to 13778)
#    'nova_metadata_port' (Defaults to 8775)
#    'nova_novnc_port' (Defaults to 6080)
#    'nova_novnc_ssl_port' (Defaults to 13080)
#    'opendaylight_api_port' (Defaults to 8081)
#    'panko_api_port' (Defaults to 8779)
#    'panko_api_ssl_port' (Defaults to 13779)
#    'ovn_nbdb_port' (Defaults to 6641)
#    'ovn_sbdb_port' (Defaults to 6642)
#    'sahara_api_port' (Defaults to 8386)
#    'sahara_api_ssl_port' (Defaults to 13386)
#    'swift_proxy_port' (Defaults to 8080)
#    'swift_proxy_ssl_port' (Defaults to 13808)
#    'trove_api_port' (Defaults to 8779)
#    'trove_api_ssl_port' (Defaults to 13779)
#    'zaqar_api_port' (Defaults to 8888)
#    'zaqar_api_ssl_port' (Defaults to 13888)
#    'ceph_rgw_port' (Defaults to 8080)
#    'ceph_rgw_ssl_port' (Defaults to 13808)
#    'zaqar_ws_port' (Defaults to 9000)
#    'zaqar_ws_ssl_port' (Defaults to 9000)
#  * Note that for zaqar's websockets we don't support having a different
#  port for SSL, because it ignores the handshake.
#  Defaults to {}
#
class tripleo::haproxy (
  $controller_virtual_ip,
  $public_virtual_ip,
  $haproxy_service_manage      = true,
  $haproxy_global_maxconn      = 20480,
  $haproxy_default_maxconn     = 4096,
  $haproxy_default_timeout     = [ 'http-request 10s', 'queue 2m', 'connect 10s', 'client 2m', 'server 2m', 'check 10s' ],
  $haproxy_listen_bind_param   = [ 'transparent' ],
  $haproxy_member_options      = [ 'check', 'inter 2000', 'rise 2', 'fall 5' ],
  $haproxy_log_address         = '/dev/log',
  $haproxy_stats_user          = 'admin',
  $haproxy_stats_password      = undef,
  $controller_hosts            = hiera('controller_node_ips'),
  $controller_hosts_names      = hiera('controller_node_names', undef),
  $contrail_config_hosts       = hiera('contrail_config_node_ips', undef),
  $contrail_config_hosts_names = hiera('contrail_config_node_names', undef),
  $contrail_analytics          = hiera('contrail_analytics_enabled', false),
  $contrail_config             = hiera('contrail_config_enabled', false),
  $contrail_webui              = hiera('contrail_webui_enabled', false),
  $service_certificate         = undef,
  $use_internal_certificates   = false,
  $internal_certificates_specs = {},
  $enable_internal_tls         = hiera('enable_internal_tls', false),
  $ssl_cipher_suite            = '!SSLv2:kEECDH:kRSA:kEDH:kPSK:+3DES:!aNULL:!eNULL:!MD5:!EXP:!RC4:!SEED:!IDEA:!DES',
  $ssl_options                 = 'no-sslv3',
  $ca_bundle                   = '/etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt',
  $haproxy_stats_certificate   = undef,
  $keystone_admin              = hiera('keystone_enabled', false),
  $keystone_public             = hiera('keystone_enabled', false),
  $neutron                     = hiera('neutron_api_enabled', false),
  $cinder                      = hiera('cinder_api_enabled', false),
  $congress                    = hiera('congress_enabled', false),
  $manila                      = hiera('manila_api_enabled', false),
  $sahara                      = hiera('sahara_api_enabled', false),
  $tacker                      = hiera('tacker_enabled', false),
  $trove                       = hiera('trove_api_enabled', false),
  $glance_api                  = hiera('glance_api_enabled', false),
  $nova_osapi                  = hiera('nova_api_enabled', false),
  $nova_placement              = hiera('nova_placement_enabled', false),
  $nova_metadata               = hiera('nova_api_enabled', false),
  $nova_novncproxy             = hiera('nova_vnc_proxy_enabled', false),
  $ec2_api                     = hiera('ec2_api_enabled', false),
  $ec2_api_metadata            = hiera('ec2_api_enabled', false),
  $ceilometer                  = hiera('ceilometer_api_enabled', false),
  $aodh                        = hiera('aodh_api_enabled', false),
  $panko                       = hiera('panko_api_enabled', false),
  $barbican                    = hiera('barbican_api_enabled', false),
  $gnocchi                     = hiera('gnocchi_api_enabled', false),
  $mistral                     = hiera('mistral_api_enabled', false),
  $swift_proxy_server          = hiera('swift_proxy_enabled', false),
  $heat_api                    = hiera('heat_api_enabled', false),
  $heat_cloudwatch             = hiera('heat_api_cloudwatch_enabled', false),
  $heat_cfn                    = hiera('heat_api_cfn_enabled', false),
  $horizon                     = hiera('horizon_enabled', false),
  $ironic                      = hiera('ironic_api_enabled', false),
  $ironic_inspector            = hiera('ironic_inspector_enabled', false),
  $mysql                       = hiera('mysql_enabled', false),
  $mysql_clustercheck          = false,
  $mysql_member_options        = undef,
  $rabbitmq                    = false,
  $etcd                        = hiera('etcd_enabled', false),
  $docker_registry             = hiera('enable_docker_registry', false),
  $redis                       = hiera('redis_enabled', false),
  $redis_password              = undef,
  $midonet_api                 = false,
  $zaqar_api                   = hiera('zaqar_api_enabled', false),
  $ceph_rgw                    = hiera('ceph_rgw_enabled', false),
  $opendaylight                = hiera('opendaylight_api_enabled', false),
  $ovn_dbs                     = hiera('ovn_dbs_enabled', false),
  $zaqar_ws                    = hiera('zaqar_api_enabled', false),
  $ui                          = hiera('enable_ui', false),
  $aodh_network                = hiera('aodh_api_network', undef),
  $barbican_network            = hiera('barbican_api_network', false),
  $ceilometer_network          = hiera('ceilometer_api_network', undef),
  $ceph_rgw_network            = hiera('ceph_rgw_network', undef),
  $cinder_network              = hiera('cinder_api_network', undef),
  $congress_network            = hiera('congress_api_network', undef),
  $docker_registry_network     = hiera('docker_registry_network', undef),
  $glance_api_network          = hiera('glance_api_network', undef),
  $gnocchi_network             = hiera('gnocchi_api_network', undef),
  $heat_api_network            = hiera('heat_api_network', undef),
  $heat_cfn_network            = hiera('heat_api_cfn_network', undef),
  $heat_cloudwatch_network     = hiera('heat_api_cloudwatch_network', undef),
  $ironic_inspector_network    = hiera('ironic_inspector_network', undef),
  $ironic_network              = hiera('ironic_api_network', undef),
  $keystone_admin_network      = hiera('keystone_admin_api_network', undef),
  $keystone_public_network     = hiera('keystone_public_api_network', undef),
  $manila_network              = hiera('manila_api_network', undef),
  $mistral_network             = hiera('mistral_api_network', undef),
  $neutron_network             = hiera('neutron_api_network', undef),
  $nova_metadata_network       = hiera('nova_api_network', undef),
  $nova_novncproxy_network     = hiera('nova_vnc_proxy_network', undef),
  $nova_osapi_network          = hiera('nova_api_network', undef),
  $nova_placement_network      = hiera('nova_placement_network', undef),
  $panko_network               = hiera('panko_api_network', undef),
  $ovn_dbs_network             = hiera('ovn_dbs_network', undef),
  $ec2_api_network             = hiera('ec2_api_network', undef),
  $ec2_api_metadata_network    = hiera('ec2_api_network', undef),
  $sahara_network              = hiera('sahara_api_network', undef),
  $swift_proxy_server_network  = hiera('swift_proxy_network', undef),
  $tacker_network              = hiera('tacker_api_network', undef),
  $trove_network               = hiera('trove_api_network', undef),
  $zaqar_api_network           = hiera('zaqar_api_network', undef),
  $service_ports               = {}
) {
  $default_service_ports = {
    aodh_api_port => 8042,
    aodh_api_ssl_port => 13042,
    barbican_api_port => 9311,
    barbican_api_ssl_port => 13311,
    ceilometer_api_port => 8777,
    ceilometer_api_ssl_port => 13777,
    cinder_api_port => 8776,
    cinder_api_ssl_port => 13776,
    congress_api_port => 1789,
    congress_api_ssl_port => 13789,
    contrail_config_port => 8082,
    contrail_config_ssl_port => 18082,
    contrail_discovery_port => 5998,
    contrail_discovery_ssl_port => 15998,
    contrail_analytics_port => 8090,
    contrail_analytics_ssl_port => 18090,
    contrail_webui_http_port => 8080,
    contrail_webui_https_port => 8143,
    docker_registry_port => 8787,
    docker_registry_ssl_port => 13787,
    glance_api_port => 9292,
    glance_api_ssl_port => 13292,
    gnocchi_api_port => 8041,
    gnocchi_api_ssl_port => 13041,
    mistral_api_port => 8989,
    mistral_api_ssl_port => 13989,
    heat_api_port => 8004,
    heat_api_ssl_port => 13004,
    heat_cfn_port => 8000,
    heat_cfn_ssl_port => 13005,
    heat_cw_port => 8003,
    heat_cw_ssl_port => 13003,
    ironic_api_port => 6385,
    ironic_api_ssl_port => 13385,
    ironic_inspector_port => 5050,
    ironic_inspector_ssl_port => 13050,
    keystone_admin_api_port => 35357,
    keystone_admin_api_ssl_port => 13357,
    keystone_public_api_port => 5000,
    keystone_public_api_ssl_port => 13000,
    manila_api_port => 8786,
    manila_api_ssl_port => 13786,
    midonet_cluster_port => 8181,
    neutron_api_port => 9696,
    neutron_api_ssl_port => 13696,
    nova_api_port => 8774,
    nova_api_ssl_port => 13774,
    nova_placement_port => 8778,
    nova_placement_ssl_port => 13778,
    nova_metadata_port => 8775,
    nova_novnc_port => 6080,
    nova_novnc_ssl_port => 13080,
    opendaylight_api_port => 8081,
    panko_api_port => 8779,
    panko_api_ssl_port => 13779,
    ovn_nbdb_port => 6641,
    ovn_sbdb_port => 6642,
    ec2_api_port => 8788,
    ec2_api_ssl_port => 13788,
    ec2_api_metadata_port => 8789,
    sahara_api_port => 8386,
    sahara_api_ssl_port => 13386,
    swift_proxy_port => 8080,
    swift_proxy_ssl_port => 13808,
    tacker_api_port => 9890,
    tacker_api_ssl_port => 13989,
    trove_api_port => 8779,
    trove_api_ssl_port => 13779,
    ui_port => 3000,
    ui_ssl_port => 443,
    zaqar_api_port => 8888,
    zaqar_api_ssl_port => 13888,
    ceph_rgw_port => 8080,
    ceph_rgw_ssl_port => 13808,
    zaqar_ws_port => 9000,
    zaqar_ws_ssl_port => 9000,
  }
  $ports = merge($default_service_ports, $service_ports)

  if $enable_internal_tls {
    $internal_tls_member_options = ['ssl', 'verify required', "ca-file ${ca_bundle}"]
  } else {
    $internal_tls_member_options = []
  }

  $controller_hosts_real = any2array(split($controller_hosts, ','))
  if ! $controller_hosts_names {
    $controller_hosts_names_real = $controller_hosts_real
  } else {
    $controller_hosts_names_real = downcase(any2array(split($controller_hosts_names, ',')))
  }

  # TODO(bnemec): When we have support for SSL on private and admin endpoints,
  # have the haproxy stats endpoint use that certificate by default.
  if $haproxy_stats_certificate {
    $haproxy_stats_bind_certificate = $haproxy_stats_certificate
  }

  $horizon_vip = hiera('horizon_vip', $controller_virtual_ip)
  if $service_certificate {
    # NOTE(jaosorior): If the horizon_vip and the public_virtual_ip are the
    # same, the first option takes precedence. Which is the case when network
    # isolation is not enabled. This is not a problem as both options are
    # identical. If network isolation is enabled, this works correctly and
    # will add a TLS binding to both the horizon_vip and the
    # public_virtual_ip.
    # Even though for the public_virtual_ip the port 80 is listening, we
    # redirect to https in the horizon_options below.
    $horizon_bind_opts = {
      "${horizon_vip}:80"        => $haproxy_listen_bind_param,
      "${horizon_vip}:443"       => union($haproxy_listen_bind_param, ['ssl', 'crt', $service_certificate]),
      "${public_virtual_ip}:80"  => $haproxy_listen_bind_param,
      "${public_virtual_ip}:443" => union($haproxy_listen_bind_param, ['ssl', 'crt', $service_certificate]),
    }
    $horizon_options = {
      'cookie'       => 'SERVERID insert indirect nocache',
      'rsprep'       => '^Location:\ http://(.*) Location:\ https://\1',
      # NOTE(jaosorior): We always redirect to https for the public_virtual_ip.
      'redirect'     => "scheme https code 301 if { hdr(host) -i ${public_virtual_ip} } !{ ssl_fc }",
      'option'       => 'forwardfor',
      'http-request' => [
          'set-header X-Forwarded-Proto https if { ssl_fc }',
          'set-header X-Forwarded-Proto http if !{ ssl_fc }'],
    }
  } else {
    $horizon_bind_opts = {
      "${horizon_vip}:80" => $haproxy_listen_bind_param,
      "${public_virtual_ip}:80" => $haproxy_listen_bind_param,
    }
    $horizon_options = {
      'cookie' => 'SERVERID insert indirect nocache',
      'option' => 'forwardfor',
    }
  }

  if $haproxy_stats_bind_certificate {
    $haproxy_stats_bind_opts = {
      "${controller_virtual_ip}:1993" => union($haproxy_listen_bind_param, ['ssl', 'crt', $haproxy_stats_bind_certificate]),
    }
  } else {
    $haproxy_stats_bind_opts = {
      "${controller_virtual_ip}:1993" => $haproxy_listen_bind_param,
    }
  }

  $mysql_vip = hiera('mysql_vip', $controller_virtual_ip)
  $mysql_bind_opts = {
    "${mysql_vip}:3306" => $haproxy_listen_bind_param,
  }

  $rabbitmq_vip = hiera('rabbitmq_vip', $controller_virtual_ip)
  $rabbitmq_bind_opts = {
    "${rabbitmq_vip}:5672" => $haproxy_listen_bind_param,
  }

  $redis_vip = hiera('redis_vip', $controller_virtual_ip)
  $redis_bind_opts = {
    "${redis_vip}:6379" => $haproxy_listen_bind_param,
  }

  $etcd_vip = hiera('etcd_vip', $controller_virtual_ip)
  $etcd_bind_opts = {
    "${etcd_vip}:2379" => $haproxy_listen_bind_param,
  }

  class { '::haproxy':
    service_manage   => $haproxy_service_manage,
    global_options   => {
      'log'                      => "${haproxy_log_address} local0",
      'pidfile'                  => '/var/run/haproxy.pid',
      'user'                     => 'haproxy',
      'group'                    => 'haproxy',
      'daemon'                   => '',
      'maxconn'                  => $haproxy_global_maxconn,
      'ssl-default-bind-ciphers' => $ssl_cipher_suite,
      'ssl-default-bind-options' => $ssl_options,
      'stats'                    => [
        'socket /var/lib/haproxy/stats mode 600 level user',
        'timeout 2m'
      ],
    },
    defaults_options => {
      'mode'    => 'tcp',
      'log'     => 'global',
      'retries' => '3',
      'timeout' => $haproxy_default_timeout,
      'maxconn' => $haproxy_default_maxconn,
    },
  }

  Tripleo::Haproxy::Endpoint {
    haproxy_listen_bind_param   => $haproxy_listen_bind_param,
    member_options              => $haproxy_member_options,
    public_certificate          => $service_certificate,
    use_internal_certificates   => $use_internal_certificates,
    internal_certificates_specs => $internal_certificates_specs,
  }

  $stats_base = ['enable', 'uri /']
  if $haproxy_stats_password {
    $stats_config = union($stats_base, ["auth ${haproxy_stats_user}:${haproxy_stats_password}"])
  } else {
    $stats_config = $stats_base
  }
  haproxy::listen { 'haproxy.stats':
    bind             => $haproxy_stats_bind_opts,
    mode             => 'http',
    options          => {
      'stats' => $stats_config,
    },
    collect_exported => false,
  }

  if $keystone_admin {
    ::tripleo::haproxy::endpoint { 'keystone_admin':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('keystone_admin_api_vip', $controller_virtual_ip),
      service_port      => $ports[keystone_admin_api_port],
      ip_addresses      => hiera('keystone_admin_api_node_ips', $controller_hosts_real),
      server_names      => hiera('keystone_admin_api_node_names', $controller_hosts_names_real),
      mode              => 'http',
      listen_options    => {
          'http-request' => [
            'set-header X-Forwarded-Proto https if { ssl_fc }',
            'set-header X-Forwarded-Proto http if !{ ssl_fc }'],
      },
      public_ssl_port   => $ports[keystone_admin_api_ssl_port],
      service_network   => $keystone_admin_network,
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  if $keystone_public {
    $keystone_listen_opts = {
      'http-request' => [
        'set-header X-Forwarded-Proto https if { ssl_fc }',
        'set-header X-Forwarded-Proto http if !{ ssl_fc }'],
    }
    if $service_certificate {
      $keystone_public_tls_listen_opts = {
        'rsprep'       => '^Location:\ http://(.*) Location:\ https://\1',
        # NOTE(jaosorior): We always redirect to https for the public_virtual_ip.
        'redirect'     => "scheme https code 301 if { hdr(host) -i ${public_virtual_ip} } !{ ssl_fc }",
        'option'       => 'forwardfor',
      }
    } else {
      $keystone_public_tls_listen_opts = {}
    }
    ::tripleo::haproxy::endpoint { 'keystone_public':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('keystone_public_api_vip', $controller_virtual_ip),
      service_port      => $ports[keystone_public_api_port],
      ip_addresses      => hiera('keystone_public_api_node_ips', $controller_hosts_real),
      server_names      => hiera('keystone_public_api_node_names', $controller_hosts_names_real),
      mode              => 'http',
      listen_options    => merge($keystone_listen_opts, $keystone_public_tls_listen_opts),
      public_ssl_port   => $ports[keystone_public_api_ssl_port],
      service_network   => $keystone_public_network,
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  if $neutron {
    ::tripleo::haproxy::endpoint { 'neutron':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('neutron_api_vip', $controller_virtual_ip),
      service_port      => $ports[neutron_api_port],
      ip_addresses      => hiera('neutron_api_node_ips', $controller_hosts_real),
      server_names      => hiera('neutron_api_node_names', $controller_hosts_names_real),
      mode              => 'http',
      listen_options    => {
          'http-request' => [
            'set-header X-Forwarded-Proto https if { ssl_fc }',
            'set-header X-Forwarded-Proto http if !{ ssl_fc }'],
      },
      public_ssl_port   => $ports[neutron_api_ssl_port],
      service_network   => $neutron_network,
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  if $cinder {
    ::tripleo::haproxy::endpoint { 'cinder':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('cinder_api_vip', $controller_virtual_ip),
      service_port      => $ports[cinder_api_port],
      ip_addresses      => hiera('cinder_api_node_ips', $controller_hosts_real),
      server_names      => hiera('cinder_api_node_names', $controller_hosts_names_real),
      mode              => 'http',
      listen_options    => {
          'http-request' => [
            'set-header X-Forwarded-Proto https if { ssl_fc }',
            'set-header X-Forwarded-Proto http if !{ ssl_fc }'],
      },
      public_ssl_port   => $ports[cinder_api_ssl_port],
      service_network   => $cinder_network,
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  if $congress {
    ::tripleo::haproxy::endpoint { 'congress':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('congress_api_vip', $controller_virtual_ip),
      service_port      => $ports[congress_api_port],
      ip_addresses      => hiera('congress_node_ips', $controller_hosts_real),
      server_names      => hiera('congress_api_node_names', $controller_hosts_names_real),
      mode              => 'http',
      listen_options    => {
          'http-request' => [
            'set-header X-Forwarded-Proto https if { ssl_fc }',
            'set-header X-Forwarded-Proto http if !{ ssl_fc }'],
      },
      public_ssl_port   => $ports[congress_api_ssl_port],
      service_network   => $congress_network,
    }
  }

  if $manila {
    ::tripleo::haproxy::endpoint { 'manila':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('manila_api_vip', $controller_virtual_ip),
      service_port      => $ports[manila_api_port],
      ip_addresses      => hiera('manila_api_node_ips', $controller_hosts_real),
      server_names      => hiera('manila_api_node_names', $controller_hosts_names_real),
      mode              => 'http',
      listen_options    => {
          'http-request' => [
            'set-header X-Forwarded-Proto https if { ssl_fc }',
            'set-header X-Forwarded-Proto http if !{ ssl_fc }'],
      },
      public_ssl_port   => $ports[manila_api_ssl_port],
      service_network   => $manila_network,
    }
  }

  if $sahara {
    ::tripleo::haproxy::endpoint { 'sahara':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('sahara_api_vip', $controller_virtual_ip),
      service_port      => $ports[sahara_api_port],
      ip_addresses      => hiera('sahara_api_node_ips', $controller_hosts_real),
      server_names      => hiera('sahara_api_node_names', $controller_hosts_names_real),
      public_ssl_port   => $ports[sahara_api_ssl_port],
      service_network   => $sahara_network,
    }
  }

  if $tacker {
    ::tripleo::haproxy::endpoint { 'tacker':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('tacker_api_vip', $controller_virtual_ip),
      service_port      => $ports[tacker_api_port],
      ip_addresses      => hiera('tacker_node_ips', $controller_hosts_real),
      server_names      => hiera('tacker_api_node_names', $controller_hosts_names_real),
      mode              => 'http',
      listen_options    => {
          'http-request' => [
            'set-header X-Forwarded-Proto https if { ssl_fc }',
            'set-header X-Forwarded-Proto http if !{ ssl_fc }'],
      },
      public_ssl_port   => $ports[tacker_api_ssl_port],
      service_network   => $tacker_network,
    }
  }

  if $trove {
    ::tripleo::haproxy::endpoint { 'trove':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('trove_api_vip', $controller_virtual_ip),
      service_port      => $ports[trove_api_port],
      ip_addresses      => hiera('trove_api_node_ips', $controller_hosts_real),
      server_names      => hiera('trove_api_node_names', $controller_hosts_names_real),
      public_ssl_port   => $ports[trove_api_ssl_port],
      service_network   => $trove_network,
    }
  }

  if $glance_api {
    ::tripleo::haproxy::endpoint { 'glance_api':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('glance_api_vip', $controller_virtual_ip),
      service_port      => $ports[glance_api_port],
      ip_addresses      => hiera('glance_api_node_ips', $controller_hosts_real),
      server_names      => hiera('glance_api_node_names', $controller_hosts_names_real),
      public_ssl_port   => $ports[glance_api_ssl_port],
      mode              => 'http',
      listen_options    => {
          'http-request' => [
            'set-header X-Forwarded-Proto https if { ssl_fc }',
            'set-header X-Forwarded-Proto http if !{ ssl_fc }'],
      },
      service_network   => $glance_api_network,
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  $nova_api_vip = hiera('nova_api_vip', $controller_virtual_ip)
  if $nova_osapi {
    ::tripleo::haproxy::endpoint { 'nova_osapi':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => $nova_api_vip,
      service_port      => $ports[nova_api_port],
      ip_addresses      => hiera('nova_api_node_ips', $controller_hosts_real),
      server_names      => hiera('nova_api_node_names', $controller_hosts_names_real),
      mode              => 'http',
      listen_options    => {
          'http-request' => [
            'set-header X-Forwarded-Proto https if { ssl_fc }',
            'set-header X-Forwarded-Proto http if !{ ssl_fc }'],
      },
      public_ssl_port   => $ports[nova_api_ssl_port],
      service_network   => $nova_osapi_network,
      #member_options    => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  $nova_placement_vip = hiera('nova_placement_vip', $controller_virtual_ip)
  if $nova_placement {
    ::tripleo::haproxy::endpoint { 'nova_placement':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => $nova_placement_vip,
      service_port      => $ports[nova_placement_port],
      ip_addresses      => hiera('nova_placement_node_ips', $controller_hosts_real),
      server_names      => hiera('nova_placement_node_names', $controller_hosts_names_real),
      mode              => 'http',
      listen_options    => {
          'http-request' => [
            'set-header X-Forwarded-Proto https if { ssl_fc }',
            'set-header X-Forwarded-Proto http if !{ ssl_fc }'],
      },
      public_ssl_port   => $ports[nova_placement_ssl_port],
      service_network   => $nova_placement_network,
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  if $nova_metadata {
    ::tripleo::haproxy::endpoint { 'nova_metadata':
      internal_ip     => hiera('nova_metadata_vip', $controller_virtual_ip),
      service_port    => $ports[nova_metadata_port],
      ip_addresses    => hiera('nova_metadata_node_ips', $controller_hosts_real),
      server_names    => hiera('nova_metadata_node_names', $controller_hosts_names_real),
      service_network => $nova_metadata_network,
    }
  }

  if $nova_novncproxy {
    ::tripleo::haproxy::endpoint { 'nova_novncproxy':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => $nova_api_vip,
      service_port      => $ports[nova_novnc_port],
      ip_addresses      => hiera('nova_api_node_ips', $controller_hosts_real),
      server_names      => hiera('nova_api_node_names', $controller_hosts_names_real),
      listen_options    => {
        'balance' => 'source',
        'timeout' => [ 'tunnel 1h' ],
      },
      public_ssl_port   => $ports[nova_novnc_ssl_port],
      service_network   => $nova_novncproxy_network,
    }
  }

  if $ec2_api {
    ::tripleo::haproxy::endpoint { 'ec2_api':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('ec2_api_vip', $controller_virtual_ip),
      service_port      => $ports[ec2_api_port],
      ip_addresses      => hiera('ec2_api_node_ips', $controller_hosts_real),
      server_names      => hiera('ec2_api_node_names', $controller_hosts_names_real),
      mode              => 'http',
      listen_options    => {
          'http-request' => [
            'set-header X-Forwarded-Proto https if { ssl_fc }',
            'set-header X-Forwarded-Proto http if !{ ssl_fc }'],
      },
      public_ssl_port   => $ports[ec2_api_ssl_port],
      service_network   => $ec2_api_network,
    }
  }

  if $ec2_api_metadata {
    ::tripleo::haproxy::endpoint { 'ec2_api_metadata':
      internal_ip     => hiera('ec2_api_vip', $controller_virtual_ip),
      service_port    => $ports[ec2_api_metadata_port],
      ip_addresses    => hiera('ec2_api_node_ips', $controller_hosts_real),
      server_names    => hiera('ec2_api_node_names', $controller_hosts_names_real),
      service_network => $ec2_api_metadata_network,
    }
  }

  if $ceilometer {
    ::tripleo::haproxy::endpoint { 'ceilometer':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('ceilometer_api_vip', $controller_virtual_ip),
      service_port      => $ports[ceilometer_api_port],
      ip_addresses      => hiera('ceilometer_api_node_ips', $controller_hosts_real),
      server_names      => hiera('ceilometer_api_node_names', $controller_hosts_names_real),
      mode              => 'http',
      listen_options    => {
          'http-request' => [
            'set-header X-Forwarded-Proto https if { ssl_fc }',
            'set-header X-Forwarded-Proto http if !{ ssl_fc }'],
      },
      public_ssl_port   => $ports[ceilometer_api_ssl_port],
      service_network   => $ceilometer_network,
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  if $aodh {
    ::tripleo::haproxy::endpoint { 'aodh':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('aodh_api_vip', $controller_virtual_ip),
      service_port      => $ports[aodh_api_port],
      ip_addresses      => hiera('aodh_api_node_ips', $controller_hosts_real),
      server_names      => hiera('aodh_api_node_names', $controller_hosts_names_real),
      mode              => 'http',
      listen_options    => {
          'http-request' => [
            'set-header X-Forwarded-Proto https if { ssl_fc }',
            'set-header X-Forwarded-Proto http if !{ ssl_fc }'],
      },
      public_ssl_port   => $ports[aodh_api_ssl_port],
      service_network   => $aodh_network,
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  if $panko {
    ::tripleo::haproxy::endpoint { 'panko':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('panko_api_vip', $controller_virtual_ip),
      service_port      => $ports[panko_api_port],
      ip_addresses      => hiera('panko_api_node_ips', $controller_hosts_real),
      server_names      => hiera('panko_api_node_names', $controller_hosts_names_real),
      listen_options    => {
          'http-request' => [
            'set-header X-Forwarded-Proto https if { ssl_fc }',
            'set-header X-Forwarded-Proto http if !{ ssl_fc }'],
      },
      public_ssl_port   => $ports[panko_api_ssl_port],
      service_network   => $panko_network,
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  if $barbican {
    ::tripleo::haproxy::endpoint { 'barbican':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('barbican_api_vip', $controller_virtual_ip),
      service_port      => $ports[barbican_api_port],
      ip_addresses      => hiera('barbican_api_node_ips', $controller_hosts_real),
      server_names      => hiera('barbican_api_node_names', $controller_hosts_names_real),
      public_ssl_port   => $ports[barbican_api_ssl_port],
      service_network   => $barbican_network,
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  if $gnocchi {
    ::tripleo::haproxy::endpoint { 'gnocchi':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('gnocchi_api_vip', $controller_virtual_ip),
      service_port      => $ports[gnocchi_api_port],
      ip_addresses      => hiera('gnocchi_api_node_ips', $controller_hosts_real),
      server_names      => hiera('gnocchi_api_node_names', $controller_hosts_names_real),
      mode              => 'http',
      listen_options    => {
          'http-request' => [
            'set-header X-Forwarded-Proto https if { ssl_fc }',
            'set-header X-Forwarded-Proto http if !{ ssl_fc }'],
      },
      public_ssl_port   => $ports[gnocchi_api_ssl_port],
      service_network   => $gnocchi_network,
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  if $mistral {
    ::tripleo::haproxy::endpoint { 'mistral':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('mistral_api_vip', $controller_virtual_ip),
      service_port      => $ports[mistral_api_port],
      ip_addresses      => hiera('mistral_api_node_ips', $controller_hosts_real),
      server_names      => hiera('mistral_api_node_names', $controller_hosts_names_real),
      public_ssl_port   => $ports[mistral_api_ssl_port],
      service_network   => $mistral_network,
    }
  }

  if $swift_proxy_server {
    $swift_proxy_server_listen_options = {
      'timeout client' => '2m',
      'timeout server' => '2m',
    }
    ::tripleo::haproxy::endpoint { 'swift_proxy_server':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('swift_proxy_vip', $controller_virtual_ip),
      service_port      => $ports[swift_proxy_port],
      ip_addresses      => hiera('swift_proxy_node_ips', $controller_hosts_real),
      server_names      => hiera('swift_proxy_node_names', $controller_hosts_names_real),
      listen_options    => $swift_proxy_server_listen_options,
      public_ssl_port   => $ports[swift_proxy_ssl_port],
      service_network   => $swift_proxy_server_network,
    }
  }

  $heat_api_vip = hiera('heat_api_vip', $controller_virtual_ip)
  $heat_ip_addresses = hiera('heat_api_node_ips', $controller_hosts_real)
  $heat_base_options = {
    'http-request' => [
      'set-header X-Forwarded-Proto https if { ssl_fc }',
      'set-header X-Forwarded-Proto http if !{ ssl_fc }']}
  if $service_certificate {
    $heat_ssl_options = {
      'rsprep' => "^Location:\\ http://${public_virtual_ip}(.*) Location:\\ https://${public_virtual_ip}\\1",
    }
    $heat_options = merge($heat_base_options, $heat_ssl_options)
  } else {
    $heat_options = $heat_base_options
  }

  if $heat_api {
    ::tripleo::haproxy::endpoint { 'heat_api':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => $heat_api_vip,
      service_port      => $ports[heat_api_port],
      ip_addresses      => $heat_ip_addresses,
      server_names      => hiera('heat_api_node_names', $controller_hosts_names_real),
      mode              => 'http',
      listen_options    => $heat_options,
      public_ssl_port   => $ports[heat_api_ssl_port],
      service_network   => $heat_api_network,
    }
  }

  if $heat_cloudwatch {
    ::tripleo::haproxy::endpoint { 'heat_cloudwatch':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => $heat_api_vip,
      service_port      => $ports[heat_cw_port],
      ip_addresses      => $heat_ip_addresses,
      server_names      => hiera('heat_api_node_names', $controller_hosts_names_real),
      mode              => 'http',
      listen_options    => $heat_options,
      public_ssl_port   => $ports[heat_cw_ssl_port],
      service_network   => $heat_cloudwatch_network,
    }
  }

  if $heat_cfn {
    ::tripleo::haproxy::endpoint { 'heat_cfn':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => $heat_api_vip,
      service_port      => $ports[heat_cfn_port],
      ip_addresses      => $heat_ip_addresses,
      server_names      => hiera('heat_api_node_names', $controller_hosts_names_real),
      mode              => 'http',
      listen_options    => $heat_options,
      public_ssl_port   => $ports[heat_cfn_ssl_port],
      service_network   => $heat_cfn_network,
    }
  }

  if $horizon {
    haproxy::listen { 'horizon':
      bind             => $horizon_bind_opts,
      options          => $horizon_options,
      mode             => 'http',
      collect_exported => false,
    }
    haproxy::balancermember { 'horizon':
      listening_service => 'horizon',
      ports             => '80',
      ipaddresses       => hiera('horizon_node_ips', $controller_hosts_real),
      server_names      => hiera('horizon_node_names', $controller_hosts_names_real),
      options           => union($haproxy_member_options, ["cookie ${::hostname}"]),
    }
  }

  if $ironic {
    ::tripleo::haproxy::endpoint { 'ironic':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('ironic_api_vip', $controller_virtual_ip),
      service_port      => $ports[ironic_api_port],
      ip_addresses      => hiera('ironic_api_node_ips', $controller_hosts_real),
      server_names      => hiera('ironic_api_node_names', $controller_hosts_names_real),
      public_ssl_port   => $ports[ironic_api_ssl_port],
      service_network   => $ironic_network,
    }
  }

  if $ironic_inspector {
    ::tripleo::haproxy::endpoint { 'ironic-inspector':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('ironic_inspector_vip', $controller_virtual_ip),
      service_port      => $ports[ironic_inspector_port],
      ip_addresses      => hiera('ironic_inspector_node_ips', $controller_hosts_real),
      server_names      => hiera('ironic_inspector_node_names', $controller_hosts_names_real),
      public_ssl_port   => $ports[ironic_inspector_ssl_port],
      service_network   => $ironic_inspector_network,
    }
  }

  if $mysql_clustercheck {
    $mysql_listen_options = {
      'option'         => [ 'tcpka', 'httpchk' ],
      'timeout client' => '90m',
      'timeout server' => '90m',
      'stick-table'    => 'type ip size 1000',
      'stick'          => 'on dst',
    }
    if $mysql_member_options {
        $mysql_member_options_real = $mysql_member_options
    } else {
        $mysql_member_options_real = ['backup', 'port 9200', 'on-marked-down shutdown-sessions', 'check', 'inter 1s']
    }
  } else {
    $mysql_listen_options = {
      'timeout client' => '90m',
      'timeout server' => '90m',
    }
    if $mysql_member_options {
        $mysql_member_options_real = $mysql_member_options
    } else {
        $mysql_member_options_real = union($haproxy_member_options, ['backup'])
    }
  }

  if $mysql {
    haproxy::listen { 'mysql':
      bind             => $mysql_bind_opts,
      options          => $mysql_listen_options,
      collect_exported => false,
    }
    haproxy::balancermember { 'mysql-backup':
      listening_service => 'mysql',
      ports             => '3306',
      ipaddresses       => hiera('mysql_node_ips', $controller_hosts_real),
      server_names      => hiera('mysql_node_names', $controller_hosts_names_real),
      options           => $mysql_member_options_real,
    }
    if hiera('manage_firewall', true) {
      include ::tripleo::firewall
      $mysql_firewall_rules = {
        '100 mysql_haproxy' => {
          'dport' => 3306,
        }
      }
      create_resources('tripleo::firewall::rule', $mysql_firewall_rules)
    }
  }

  if $rabbitmq {
    haproxy::listen { 'rabbitmq':
      bind             => $rabbitmq_bind_opts,
      options          => {
        'option'  => [ 'tcpka' ],
        'timeout' => [ 'client 0', 'server 0' ],
      },
      collect_exported => false,
    }
    haproxy::balancermember { 'rabbitmq':
      listening_service => 'rabbitmq',
      ports             => '5672',
      ipaddresses       => hiera('rabbitmq_network', $controller_hosts_real),
      server_names      => hiera('rabbitmq_node_names', $controller_hosts_names_real),
      options           => $haproxy_member_options,
    }
  }

  if $etcd {
    haproxy::listen { 'etcd':
      bind             => $etcd_bind_opts,
      options          => {
        'balance' => 'source',
      },
      collect_exported => false,
    }
    haproxy::balancermember { 'etcd':
      listening_service => 'etcd',
      ports             => '2379',
      ipaddresses       => hiera('etcd_node_ips', $controller_hosts_real),
      server_names      => hiera('etcd_node_names', $controller_hosts_names_real),
      options           => $haproxy_member_options,
    }
  }

  if $docker_registry {
    ::tripleo::haproxy::endpoint { 'docker-registry':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('docker_registry_vip', $controller_virtual_ip),
      service_port      => $ports[docker_registry_port],
      ip_addresses      => hiera('docker_registry_node_ips', $controller_hosts_real),
      server_names      => hiera('docker_registry_node_names', $controller_hosts_names_real),
      public_ssl_port   => $ports[docker_registry_ssl_port],
      service_network   => $docker_registry_network,
    }
  }

  if $redis {
    if $redis_password {
      $redis_tcp_check_options = ["send AUTH\\ ${redis_password}\\r\\n"]
    } else {
      $redis_tcp_check_options = []
    }
    haproxy::listen { 'redis':
      bind             => $redis_bind_opts,
      options          => {
        'balance'   => 'first',
        'option'    => ['tcp-check',],
        'tcp-check' => union($redis_tcp_check_options, ['send PING\r\n',
                                                        'expect string +PONG',
                                                        'send info\ replication\r\n',
                                                        'expect string role:master',
                                                        'send QUIT\r\n',
                                                        'expect string +OK']),
      },
      collect_exported => false,
    }
    haproxy::balancermember { 'redis':
      listening_service => 'redis',
      ports             => '6379',
      ipaddresses       => hiera('redis_node_ips', $controller_hosts_real),
      server_names      => hiera('redis_node_names', $controller_hosts_names_real),
      options           => $haproxy_member_options,
    }
    if hiera('manage_firewall', true) {
      include ::tripleo::firewall
      $redis_firewall_rules = {
        '100 redis_haproxy' => {
          'dport' => 6379,
        }
      }
      create_resources('tripleo::firewall::rule', $redis_firewall_rules)
    }
  }

  $midonet_cluster_vip = hiera('midonet_cluster_vip', $controller_virtual_ip)
  $midonet_bind_opts = {
    "${midonet_cluster_vip}:${ports[midonet_cluster_port]}" => [],
    "${public_virtual_ip}:${ports[midonet_cluster_port]}"   => [],
  }

  if $midonet_api {
    haproxy::listen { 'midonet_api':
      bind             => $midonet_bind_opts,
      collect_exported => false,
    }
    haproxy::balancermember { 'midonet_api':
      listening_service => 'midonet_api',
      ports             => $ports[midonet_cluster_port],
      ipaddresses       => hiera('midonet_api_node_ips', $controller_hosts_real),
      server_names      => hiera('midonet_api_node_names', $controller_hosts_names_real),
      options           => $haproxy_member_options,
    }
  }
  if $zaqar_api {
    ::tripleo::haproxy::endpoint { 'zaqar_api':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('zaqar_api_vip', $controller_virtual_ip),
      service_port      => $ports[zaqar_api_port],
      ip_addresses      => hiera('zaqar_api_node_ips', $controller_hosts_real),
      server_names      => hiera('zaqar_api_node_names', $controller_hosts_names_real),
      mode              => 'http',
      public_ssl_port   => $ports[zaqar_api_ssl_port],
      service_network   => $zaqar_api_network,
    }
  }

  if $ceph_rgw {
    ::tripleo::haproxy::endpoint { 'ceph_rgw':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('ceph_rgw_vip', $controller_virtual_ip),
      service_port      => $ports[ceph_rgw_port],
      ip_addresses      => hiera('ceph_rgw_node_ips', $controller_hosts_real),
      server_names      => hiera('ceph_rgw_node_names', $controller_hosts_names_real),
      public_ssl_port   => $ports[ceph_rgw_ssl_port],
      service_network   => $ceph_rgw_network,
    }
  }

  if $opendaylight {
    ::tripleo::haproxy::endpoint { 'opendaylight':
      internal_ip    => unique([hiera('opendaylight_api_vip', $controller_virtual_ip), $controller_virtual_ip]),
      service_port   => $ports[opendaylight_api_port],
      ip_addresses   => hiera('opendaylight_api_node_ips', $controller_hosts_real),
      server_names   => hiera('opendaylight_api_node_names', $controller_hosts_names_real),
      mode           => 'http',
      listen_options => {
        'balance' => 'source',
      },
    }
  }


  if $ovn_dbs {
    # FIXME: is this config enough to ensure we only hit the first node in
    # ovn_northd_node_ips ?
    $ovn_db_listen_options = {
      'option'         => [ 'tcpka' ],
      'timeout client' => '90m',
      'timeout server' => '90m',
      'stick-table'    => 'type ip size 1000',
      'stick'          => 'on dst',
    }
    ::tripleo::haproxy::endpoint { 'ovn_nbdb':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('ovn_dbs_vip', $controller_virtual_ip),
      service_port      => $ports[ovn_nbdb_port],
      ip_addresses      => hiera('ovn_dbs_node_ips', $controller_hosts_real),
      server_names      => hiera('ovn_dbs_node_names', $controller_hosts_names_real),
      service_network   => $ovn_dbs_network,
      listen_options    => $ovn_db_listen_options,
      mode              => 'tcp'
    }
    ::tripleo::haproxy::endpoint { 'ovn_sbdb':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('ovn_dbs_vip', $controller_virtual_ip),
      service_port      => $ports[ovn_sbdb_port],
      ip_addresses      => hiera('ovn_dbs_node_ips', $controller_hosts_real),
      server_names      => hiera('ovn_dbs_node_names', $controller_hosts_names_real),
      service_network   => $ovn_dbs_network,
      listen_options    => $ovn_db_listen_options,
      mode              => 'tcp'
    }
  }

  if $zaqar_ws {
    ::tripleo::haproxy::endpoint { 'zaqar_ws':
      public_virtual_ip         => $public_virtual_ip,
      internal_ip               => hiera('zaqar_ws_vip', $controller_virtual_ip),
      service_port              => $ports[zaqar_ws_port],
      ip_addresses              => hiera('zaqar_ws_node_ips', $controller_hosts_real),
      server_names              => hiera('zaqar_ws_node_names', $controller_hosts_names_real),
      mode                      => 'http',
      haproxy_listen_bind_param => [],  # We don't use a transparent proxy here
      listen_options            => {
        # NOTE(jaosorior): Websockets have more overhead in establishing
        # connections than regular HTTP connections. Also, since it begins
        # as an HTTP connection and then "upgrades" to a TCP connection, some
        # timeouts get overridden by others at certain times of the connection.
        # The following values were taken from the following site:
        # http://blog.haproxy.com/2012/11/07/websockets-load-balancing-with-haproxy/
        'timeout' => ['connect 5s', 'client 25s', 'server 25s', 'tunnel 3600s'],
      },
      public_ssl_port           => $ports[zaqar_ws_ssl_port],
      service_network           => $zaqar_api_network,
    }
  }

  if $ui {
    ::tripleo::haproxy::endpoint { 'ui':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('ui_vip', $controller_virtual_ip),
      service_port      => $ports[ui_port],
      ip_addresses      => hiera('ui_ips', $controller_hosts_real),
      server_names      => $controller_hosts_names_real,
      mode              => 'http',
      public_ssl_port   => $ports[ui_ssl_port],
      listen_options    => {
        # NOTE(dtrainor): in addition to the zaqar_ws endpoint, the HTTPS
        # (443/tcp) endpoint that answers for the UI must also use a long-lived
        # tunnel timeout for the same reasons mentioned above.
        'timeout' => ['tunnel 3600s'],
      },
    }
  }
  if $contrail_config {
    ::tripleo::haproxy::endpoint { 'contrail_config':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('contrail_config_vip', $controller_virtual_ip),
      service_port      => $ports[contrail_config_port],
      ip_addresses      => hiera('contrail_config_node_ips'),
      server_names      => hiera('contrail_config_node_ips'),
      public_ssl_port   => $ports[contrail_config_ssl_port],
    }
    ::tripleo::haproxy::endpoint { 'contrail_discovery':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('contrail_config_vip', $controller_virtual_ip),
      service_port      => $ports[contrail_discovery_port],
      ip_addresses      => hiera('contrail_config_node_ips'),
      server_names      => hiera('contrail_config_node_ips'),
      public_ssl_port   => $ports[contrail_discovery_ssl_port],
    }
  }
  if $contrail_analytics {
    ::tripleo::haproxy::endpoint { 'contrail_analytics':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('contrail_analytics_vip', $controller_virtual_ip),
      service_port      => $ports[contrail_analytics_port],
      ip_addresses      => hiera('contrail_config_node_ips'),
      server_names      => hiera('contrail_config_node_ips'),
      public_ssl_port   => $ports[contrail_analytics_ssl_port],
    }
  }
  if $contrail_webui {
    ::tripleo::haproxy::endpoint { 'contrail_webui_http':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('contrail_webui_vip', $controller_virtual_ip),
      service_port      => $ports[contrail_webui_http_port],
      ip_addresses      => hiera('contrail_config_node_ips'),
      server_names      => hiera('contrail_config_node_ips'),
      public_ssl_port   => $ports[contrail_webui_http_port],
    }
    ::tripleo::haproxy::endpoint { 'contrail_webui_https':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('contrail_webui_vip', $controller_virtual_ip),
      service_port      => $ports[contrail_webui_https_port],
      ip_addresses      => hiera('contrail_config_node_ips'),
      server_names      => hiera('contrail_config_node_ips'),
      public_ssl_port   => $ports[contrail_webui_https_port],
    }
  }
}

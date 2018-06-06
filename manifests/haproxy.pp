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
# [*activate_httplog*]
#  Globally activate "httplog" option (in defaults section)
#  In case the listener is NOT set to "http" mode, HAProxy will fallback to "tcplog".
#  Defaults to false
#
# [*haproxy_globals_override*]
#  HAProxy global option we can append to the default base set in this class.
#  If you enter an already existing key, it will override the default.
#  Defaults to {}
#
# [*haproxy_defaults_override*]
#  HAProxy defaults option we can append to the default base set in this class.
#  If you enter an already existing key, it will override the default.
#  Defaults to {}
#
# [*haproxy_daemon*]
#  Should haproxy run in daemon mode or not
#  Defaults to true
#
# [*haproxy_socket_access_level*]
#  Access level for HAProxy socket.
#  Can be "user" or "admin"
#  Defaults to "user"
#
# [*manage_firewall*]
#  (optional) Enable or disable firewall settings for ports exposed by HAProxy
#  (false means disabled, and true means enabled)
#  Defaults to hiera('tripleo::firewall::manage_firewall', true)
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
# [*public_virtual_ip*]
#  Public IP or group of IPs to bind the pools
#  Can be a string or an array.
#  Defaults to undef
#
# [*haproxy_stats_user*]
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
#  Defaults to 'no-sslv3 no-tlsv10'
#
# [*ca_bundle*]
#  Path to the CA bundle to be used for HAProxy to validate the certificates of
#  the servers it balances
#  Defaults to '/etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt'
#
# [*crl_file*]
#  Path to the CRL file to be used for checking revoked certificates.
#  Defaults to undef
#
# [*haproxy_stats_certificate*]
#  Filename of an HAProxy-compatible certificate and key file
#  When set, enables SSL on the haproxy stats endpoint using the specified file.
#  Defaults to undef
#
# [*haproxy_stats*]
#  (optional) Enable or not the haproxy stats interface
#  Defaults to true
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
# [*designate*]
#  (optional) Enable or not Designate API binding
#  Defaults to hiera('designate_api_enabled', false)
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
# [*kubernetes_master*]
#  (optional) Enable or not Kubernetes API binding
#  Defaults to hiera('kubernetes_master_enabled', false)
#
# [*octavia*]
#  (optional) Enable or not Octavia APII binding
#  Defaults to hiera('octavia_api_enabled', false)
#
# [*mysql*]
#  (optional) Enable or not MySQL Galera binding
#  Defaults to hiera('mysql_enabled', false)
#
# [*mysql_clustercheck*]
#  (optional) Enable check via clustercheck for mysql
#  Defaults to false
#
# [*mysql_max_conn*]
#  (optional) Set the maxconn parameter for mysql
#  Defaults to undef
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
# [*ovn_dbs_manage_lb*]
#  (optional) Whether or not haproxy should configure OVN dbs for load balancing
#  if ovn_dbs is enabled.
#  Defaults to false
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
# [*designate_network*]
#  (optional) Specify the network designate is running on.
#  Defaults to hiera('designate_api_network', undef)
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
# [*horizon_network*]
#  (optional) Specify the network horizon is running on.
#  Defaults to hiera('horizon_network', undef)
#
# [*ironic_inspector_network*]
#  (optional) Specify the network ironic_inspector is running on.
#  Defaults to hiera('ironic_inspector_network', undef)
#
# [*kubernetes_master_network*]
#  (optional) Specify the network kubernetes_master is running on.
#  Defaults to hiera('kubernetes_master_network', undef)
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
# [*etcd_network*]
#  (optional) Specify the network etcd is running on.
#  Defaults to hiera('etcd_network', undef)
#
# [*octavia_network*]
#  (optional) Specify the network octavia is running on.
#  Defaults to hiera('octavia_api_network', undef)
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
#    'kubernetes_master_port' (Defaults to 6443)
#    'kubernetes_master_ssl_port' (Defaults to 13443)
#    'keystone_admin_api_port' (Defaults to 35357)
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
#    'octavia_api_port' (Defaults to 9876)
#    'octavia_api_ssl_port' (Defaults to 13876)
#    'opendaylight_api_port' (Defaults to 8081)
#    'panko_api_port' (Defaults to 8977)
#    'panko_api_ssl_port' (Defaults to 13977)
#    'ovn_nbdb_port' (Defaults to 6641)
#    'ovn_nbdb_ssl_port' (Defaults to 13641)
#    'ovn_sbdb_port' (Defaults to 6642)
#    'ovn_sbdb_ssl_port' (Defaults to 13642)
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
  $activate_httplog            = false,
  $haproxy_globals_override    = {},
  $haproxy_defaults_override   = {},
  $haproxy_daemon              = true,
  $haproxy_socket_access_level = 'user',
  $haproxy_stats_user          = 'admin',
  $haproxy_stats_password      = undef,
  $manage_firewall             = hiera('tripleo::firewall::manage_firewall', true),
  $controller_hosts            = hiera('controller_node_ips'),
  $controller_hosts_names      = hiera('controller_node_names', undef),
  $service_certificate         = undef,
  $use_internal_certificates   = false,
  $internal_certificates_specs = {},
  $enable_internal_tls         = hiera('enable_internal_tls', false),
  $ssl_cipher_suite            = '!SSLv2:kEECDH:kRSA:kEDH:kPSK:+3DES:!aNULL:!eNULL:!MD5:!EXP:!RC4:!SEED:!IDEA:!DES',
  $ssl_options                 = 'no-sslv3 no-tlsv10',
  $ca_bundle                   = '/etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt',
  $crl_file                    = undef,
  $haproxy_stats_certificate   = undef,
  $haproxy_stats               = true,
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
  $aodh                        = hiera('aodh_api_enabled', false),
  $panko                       = hiera('panko_api_enabled', false),
  $barbican                    = hiera('barbican_api_enabled', false),
  $gnocchi                     = hiera('gnocchi_api_enabled', false),
  $mistral                     = hiera('mistral_api_enabled', false),
  $swift_proxy_server          = hiera('swift_proxy_enabled', false),
  $heat_api                    = hiera('heat_api_enabled', false),
  $heat_cfn                    = hiera('heat_api_cfn_enabled', false),
  $horizon                     = hiera('horizon_enabled', false),
  $ironic                      = hiera('ironic_api_enabled', false),
  $ironic_inspector            = hiera('ironic_inspector_enabled', false),
  $octavia                     = hiera('octavia_api_enabled', false),
  $designate                   = hiera('designate_api_enabled', false),
  $mysql                       = hiera('mysql_enabled', false),
  $kubernetes_master           = hiera('kubernetes_master_enabled', false),
  $mysql_clustercheck          = false,
  $mysql_max_conn              = undef,
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
  $ovn_dbs_manage_lb           = false,
  $zaqar_ws                    = hiera('zaqar_api_enabled', false),
  # For backward compatibility with instack-undercloud, keep enable_ui support)
  $ui                          = pick(hiera('tripleo_ui_enabled', undef), hiera('enable_ui', undef), false),
  $aodh_network                = hiera('aodh_api_network', undef),
  $barbican_network            = hiera('barbican_api_network', false),
  $ceph_rgw_network            = hiera('ceph_rgw_network', undef),
  $cinder_network              = hiera('cinder_api_network', undef),
  $congress_network            = hiera('congress_api_network', undef),
  $designate_network           = hiera('designate_api_network', undef),
  $docker_registry_network     = hiera('docker_registry_network', undef),
  $glance_api_network          = hiera('glance_api_network', undef),
  $gnocchi_network             = hiera('gnocchi_api_network', undef),
  $heat_api_network            = hiera('heat_api_network', undef),
  $heat_cfn_network            = hiera('heat_api_cfn_network', undef),
  $horizon_network             = hiera('horizon_network', undef),
  $ironic_inspector_network    = hiera('ironic_inspector_network', undef),
  $ironic_network              = hiera('ironic_api_network', undef),
  $kubernetes_master_network    = hiera('kubernetes_master_network', undef),
  $keystone_admin_network      = hiera('keystone_admin_api_network', undef),
  $keystone_public_network     = hiera('keystone_public_api_network', undef),
  $manila_network              = hiera('manila_api_network', undef),
  $mistral_network             = hiera('mistral_api_network', undef),
  $neutron_network             = hiera('neutron_api_network', undef),
  $nova_metadata_network       = hiera('nova_api_network', undef),
  $nova_novncproxy_network     = hiera('nova_vnc_proxy_network', undef),
  $nova_osapi_network          = hiera('nova_api_network', undef),
  $nova_placement_network      = hiera('nova_placement_network', undef),
  $octavia_network             = hiera('octavia_api_network', undef),
  $opendaylight_network        = hiera('opendaylight_api_network', undef),
  $panko_network               = hiera('panko_api_network', undef),
  $ovn_dbs_network             = hiera('ovn_dbs_network', undef),
  $ec2_api_network             = hiera('ec2_api_network', undef),
  $ec2_api_metadata_network    = hiera('ec2_api_network', undef),
  $etcd_network                = hiera('etcd_network', undef),
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
    cinder_api_port => 8776,
    cinder_api_ssl_port => 13776,
    congress_api_port => 1789,
    congress_api_ssl_port => 13789,
    designate_api_port => 9001,
    designate_api_ssl_port => 13001,
    docker_registry_port => 8787,
    docker_registry_ssl_port => 13787,
    etcd_port => 2379,
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
    kubernetes_master_port => 6443,
    kubernetes_master_ssl_port => 13443,
    keystone_admin_api_port => 35357,
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
    octavia_api_port => 9876,
    octavia_api_ssl_port => 13876,
    opendaylight_api_port => 8081,
    opendaylight_ws_port => 8185,
    panko_api_port => 8977,
    panko_api_ssl_port => 13977,
    ovn_nbdb_port => 6641,
    ovn_nbdb_ssl_port => 13641,
    ovn_sbdb_port => 6642,
    ovn_sbdb_ssl_port => 13642,
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
    $base_internal_tls_member_options = ['ssl', 'verify required', "ca-file ${ca_bundle}"]

    if $crl_file {
      $internal_tls_member_options = concat($base_internal_tls_member_options, "crl-file ${crl_file}")
    } else {
      $internal_tls_member_options = $base_internal_tls_member_options
    }
    Haproxy::Balancermember {
      verifyhost => true
    }
  } else {
    $internal_tls_member_options = []
  }

  $controller_hosts_real = any2array(split($controller_hosts, ','))
  if ! $controller_hosts_names {
    $controller_hosts_names_real = $controller_hosts_real
  } else {
    $controller_hosts_names_real = downcase(any2array(split($controller_hosts_names, ',')))
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

  $haproxy_global_options = {
    'log'                      => "${haproxy_log_address} local0",
    'pidfile'                  => '/var/run/haproxy.pid',
    'user'                     => 'haproxy',
    'group'                    => 'haproxy',
    'maxconn'                  => $haproxy_global_maxconn,
    'ssl-default-bind-ciphers' => $ssl_cipher_suite,
    'ssl-default-bind-options' => $ssl_options,
    'stats'                    => [
      "socket /var/lib/haproxy/stats mode 600 level ${haproxy_socket_access_level}",
      'timeout 2m'
    ],
  }
  if $haproxy_daemon == true {
    $haproxy_daemonize = {
      'daemon' => '',
    }
  } else {
    $haproxy_daemonize = {}
  }

  $haproxy_defaults_options = {
    'mode'    => 'tcp',
    'log'     => 'global',
    'retries' => '3',
    'timeout' => $haproxy_default_timeout,
    'maxconn' => $haproxy_default_maxconn,
  }
  if $activate_httplog {
    $httplog = {'option' => 'httplog'}
  } else {
    $httplog = {}
  }

  class { '::haproxy':
    service_manage   => $haproxy_service_manage,
    global_options   => merge($haproxy_global_options, $haproxy_daemonize, $haproxy_globals_override),
    defaults_options => merge($haproxy_defaults_options, $httplog, $haproxy_defaults_override),
  }


  $default_listen_options = {
    'option'       => [ 'httpchk', 'httplog', ],
    'http-request' => [
      'set-header X-Forwarded-Proto https if { ssl_fc }',
      'set-header X-Forwarded-Proto http if !{ ssl_fc }'],
  }
  Tripleo::Haproxy::Endpoint {
    haproxy_listen_bind_param   => $haproxy_listen_bind_param,
    member_options              => $haproxy_member_options,
    public_certificate          => $service_certificate,
    use_internal_certificates   => $use_internal_certificates,
    internal_certificates_specs => $internal_certificates_specs,
    listen_options              => $default_listen_options,
    manage_firewall             => $manage_firewall,
  }

  $service_names = hiera('enabled_services', [])
  tripleo::haproxy::service_endpoints { $service_names: }

  if $haproxy_stats {
    if $haproxy_stats_certificate {
      $haproxy_stats_certificate_real = $haproxy_stats_certificate
    } elsif $use_internal_certificates {
      # NOTE(jaosorior): Right now it's hardcoded to use the ctlplane network
      $haproxy_stats_certificate_real = $internal_certificates_specs["haproxy-ctlplane"]['service_pem']
    } else {
      $haproxy_stats_certificate_real = undef
    }
    class { '::tripleo::haproxy::stats':
      haproxy_listen_bind_param => $haproxy_listen_bind_param,
      ip                        => $controller_virtual_ip,
      password                  => $haproxy_stats_password,
      certificate               => $haproxy_stats_certificate_real,
      user                      => $haproxy_stats_user,
    }
  }

  if $keystone_admin {
    ::tripleo::haproxy::endpoint { 'keystone_admin':
      internal_ip     => hiera('keystone_admin_api_vip', $controller_virtual_ip),
      service_port    => $ports[keystone_admin_api_port],
      ip_addresses    => hiera('keystone_admin_api_node_ips', $controller_hosts_real),
      server_names    => hiera('keystone_admin_api_node_names', $controller_hosts_names_real),
      mode            => 'http',
      listen_options  => merge($default_listen_options, { 'option' => [ 'httpchk GET /v3' ] }),
      service_network => $keystone_admin_network,
      member_options  => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  if $keystone_public {
    $keystone_listen_opts = {
      'option' => [ 'httpchk GET /v3', ],
    }
    ::tripleo::haproxy::endpoint { 'keystone_public':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('keystone_public_api_vip', $controller_virtual_ip),
      service_port      => $ports[keystone_public_api_port],
      ip_addresses      => hiera('keystone_public_api_node_ips', $controller_hosts_real),
      server_names      => hiera('keystone_public_api_node_names', $controller_hosts_names_real),
      mode              => 'http',
      listen_options    => merge($default_listen_options, $keystone_listen_opts),
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
      mode              => 'http',
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
      mode              => 'http',
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
      listen_options    => merge($default_listen_options, { 'option' => [ 'httpchk GET /healthcheck', ]}),
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
      public_ssl_port   => $ports[nova_api_ssl_port],
      service_network   => $nova_osapi_network,
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
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
      mode            => 'http',
      service_network => $nova_metadata_network,
      member_options  => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  if $nova_novncproxy {
    ::tripleo::haproxy::endpoint { 'nova_novncproxy':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => $nova_api_vip,
      service_port      => $ports[nova_novnc_port],
      ip_addresses      => hiera('nova_api_node_ips', $controller_hosts_real),
      server_names      => hiera('nova_api_node_names', $controller_hosts_names_real),
      listen_options    => merge($default_listen_options, {
        'option'  => [ 'tcpka', 'tcplog' ],
        'balance' => 'source',
        'timeout' => [ 'tunnel 1h' ],
      }),
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
      public_ssl_port   => $ports[ec2_api_ssl_port],
      listen_options    => merge($default_listen_options, {
        'option' => [ 'tcpka' ]
      }),
      service_network   => $ec2_api_network,
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  if $ec2_api_metadata {
    ::tripleo::haproxy::endpoint { 'ec2_api_metadata':
      internal_ip     => hiera('ec2_api_vip', $controller_virtual_ip),
      service_port    => $ports[ec2_api_metadata_port],
      ip_addresses    => hiera('ec2_api_node_ips', $controller_hosts_real),
      server_names    => hiera('ec2_api_node_names', $controller_hosts_names_real),
      mode            => 'http',
      service_network => $ec2_api_metadata_network,
      member_options  => union($haproxy_member_options, $internal_tls_member_options),
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
      public_ssl_port   => $ports[panko_api_ssl_port],
      mode              => 'http',
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
      mode              => 'http',
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
      mode              => 'http',
      public_ssl_port   => $ports[mistral_api_ssl_port],
      service_network   => $mistral_network,
    }
  }

  if $swift_proxy_server {
    $swift_proxy_server_listen_options = {
      'option'         => [ 'httpchk GET /healthcheck', ],
      'timeout client' => '2m',
      'timeout server' => '2m',
    }
    ::tripleo::haproxy::endpoint { 'swift_proxy_server':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('swift_proxy_vip', $controller_virtual_ip),
      service_port      => $ports[swift_proxy_port],
      ip_addresses      => hiera('swift_proxy_node_ips', $controller_hosts_real),
      server_names      => hiera('swift_proxy_node_names', $controller_hosts_names_real),
      listen_options    => merge($default_listen_options, $swift_proxy_server_listen_options),
      public_ssl_port   => $ports[swift_proxy_ssl_port],
      service_network   => $swift_proxy_server_network,
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  $heat_api_vip = hiera('heat_api_vip', $controller_virtual_ip)
  $heat_ip_addresses = hiera('heat_api_node_ips', $controller_hosts_real)
  $heat_timeout_options = {
    'timeout client' => '10m',
    'timeout server' => '10m',
  }
  if $service_certificate {
    $heat_ssl_options = {
      'rsprep' => "^Location:\\ http://${public_virtual_ip}(.*) Location:\\ https://${public_virtual_ip}\\1",
    }
    $heat_options = merge($default_listen_options, $heat_ssl_options, $heat_timeout_options)
  } else {
    $heat_options = merge($default_listen_options, $heat_timeout_options)
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
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
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
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  if $horizon {
    class { '::tripleo::haproxy::horizon_endpoint':
      public_virtual_ip           => $public_virtual_ip,
      internal_ip                 => hiera('horizon_vip', $controller_virtual_ip),
      haproxy_listen_bind_param   => $haproxy_listen_bind_param,
      ip_addresses                => hiera('horizon_node_ips', $controller_hosts_real),
      server_names                => hiera('horizon_node_names', $controller_hosts_names_real),
      member_options              => union($haproxy_member_options, $internal_tls_member_options),
      public_certificate          => $service_certificate,
      use_internal_certificates   => $use_internal_certificates,
      internal_certificates_specs => $internal_certificates_specs,
      service_network             => $horizon_network,
    }
  }

  if $ironic {
    ::tripleo::haproxy::endpoint { 'ironic':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('ironic_api_vip', $controller_virtual_ip),
      service_port      => $ports[ironic_api_port],
      ip_addresses      => hiera('ironic_api_node_ips', $controller_hosts_real),
      server_names      => hiera('ironic_api_node_names', $controller_hosts_names_real),
      mode              => 'http',
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
      mode              => 'http',
      listen_options    => { 'http-check' => ['expect rstring .*200.*'], },
    }
  }

  if $designate {
    ::tripleo::haproxy::endpoint { 'designate':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('designate_api_vip', $controller_virtual_ip),
      service_port      => $ports[designate_api_port],
      ip_addresses      => hiera('designate_api_node_ips', $controller_hosts_real),
      server_names      => hiera('designate_api_node_names', $controller_hosts_names_real),
      mode              => 'http',
      public_ssl_port   => $ports[designate_api_ssl_port],
      service_network   => $designate_network,
    }
  }

  if $mysql_clustercheck {
    $mysql_listen_options = {
      'option'         => [ 'tcpka', 'httpchk', 'tcplog' ],
      'timeout client' => '90m',
      'timeout server' => '90m',
      'stick-table'    => 'type ip size 1000',
      'stick'          => 'on dst',
      'maxconn'        => $mysql_max_conn
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
      'maxconn'        => $mysql_max_conn
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
    if $manage_firewall {
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
        'option'  => [ 'tcpka', 'tcplog' ],
        'timeout' => [ 'client 0', 'server 0' ],
      },
      collect_exported => false,
    }
    haproxy::balancermember { 'rabbitmq':
      listening_service => 'rabbitmq',
      ports             => '5672',
      ipaddresses       => hiera('rabbitmq_node_ips', $controller_hosts_real),
      server_names      => hiera('rabbitmq_node_names', $controller_hosts_names_real),
      options           => $haproxy_member_options,
    }
  }

  if $etcd {
    ::tripleo::haproxy::endpoint { 'etcd':
      internal_ip     => hiera('etcd_vip', $controller_virtual_ip),
      service_port    => $ports[etcd_port],
      ip_addresses    => hiera('etcd_node_ips', $controller_hosts_real),
      server_names    => hiera('etcd_node_names', $controller_hosts_names_real),
      service_network => $etcd_network,
      member_options  => union($haproxy_member_options, $internal_tls_member_options),
      listen_options  => {
        'balance' => 'source',
      }
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
    if $enable_internal_tls {
      $redis_tcp_check_ssl_options = ['connect ssl']
      $redis_ssl_member_options = ['check-ssl', "ca-file ${ca_bundle}"]
    } else {
      $redis_tcp_check_ssl_options = []
      $redis_ssl_member_options = []
    }
    if $redis_password {
      $redis_tcp_check_password_options = ["send AUTH\\ ${redis_password}\\r\\n"]
    } else {
      $redis_tcp_check_password_options = []
    }
    $redis_tcp_check_options = union($redis_tcp_check_ssl_options, $redis_tcp_check_password_options)
    haproxy::listen { 'redis':
      bind             => $redis_bind_opts,
      options          => {
        'balance'   => 'first',
        'option'    => [ 'tcp-check', 'tcplog', ],
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
      options           => union($haproxy_member_options, ['on-marked-down shutdown-sessions'], $redis_ssl_member_options),
      verifyhost        => false,
    }
    if $manage_firewall {
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
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
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
      listen_options    => merge($default_listen_options, { 'option' => [ 'httpchk HEAD /' ] }),
    }
  }

  if $opendaylight {
    ::tripleo::haproxy::endpoint { 'opendaylight':
      internal_ip     => unique([hiera('opendaylight_api_vip', $controller_virtual_ip), $controller_virtual_ip]),
      service_port    => $ports[opendaylight_api_port],
      ip_addresses    => hiera('opendaylight_api_node_ips', $controller_hosts_real),
      server_names    => hiera('opendaylight_api_node_names', $controller_hosts_names_real),
      mode            => 'http',
      member_options  => union($haproxy_member_options, $internal_tls_member_options),
      service_network => $opendaylight_network,
      listen_options  => merge($default_listen_options,
        { 'option' => [ 'httpchk GET /controller/nb/v2/neutron', 'httplog' ] }),
    }

    ::tripleo::haproxy::endpoint { 'opendaylight_ws':
      internal_ip     => unique([hiera('opendaylight_api_vip', $controller_virtual_ip), $controller_virtual_ip]),
      service_port    => $ports[opendaylight_ws_port],
      ip_addresses    => hiera('opendaylight_api_node_ips', $controller_hosts_real),
      server_names    => hiera('opendaylight_api_node_names', $controller_hosts_names_real),
      mode            => 'http',
      service_network => $opendaylight_network,
      listen_options  => {
        # NOTE(jaosorior): Websockets have more overhead in establishing
        # connections than regular HTTP connections. Also, since it begins
        # as an HTTP connection and then "upgrades" to a TCP connection, some
        # timeouts get overridden by others at certain times of the connection.
        # The following values were taken from the following site:
        # http://blog.haproxy.com/2012/11/07/websockets-load-balancing-with-haproxy/
        'timeout' => ['connect 5s', 'client 25s', 'server 25s', 'tunnel 3600s'],
      },
    }
  }

  if $octavia {
    ::tripleo::haproxy::endpoint { 'octavia':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('octavia_api_vip', $controller_virtual_ip),
      service_port      => $ports[octavia_api_port],
      ip_addresses      => hiera('octavia_api_node_ips'),
      server_names      => hiera('octavia_api_node_names'),
      public_ssl_port   => $ports[octavia_api_ssl_port],
      service_network   => $octavia_network,
    }
  }

  if $ovn_dbs and $ovn_dbs_manage_lb {
    # FIXME: is this config enough to ensure we only hit the first node in
    # ovn_northd_node_ips ?
    # We only configure ovn_dbs_vip in haproxy if HA for OVN DB servers is
    # disabled.
    # If HA is enabled, pacemaker configures the OVN DB servers accordingly.
    $ovn_db_listen_options = {
      'option'         => [ 'tcpka', 'tcplog' ],
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
      public_ssl_port   => $ports[ovn_nbdb_ssl_port],
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
      public_ssl_port   => $ports[ovn_sbdb_ssl_port],
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

  if $kubernetes_master {
    ::tripleo::haproxy::endpoint { 'kubernetes-master':
      # Note we don't expose the kubernetes endpoint via public_virtual_ip
      internal_ip     => hiera('kubernetes_master_vip', $controller_virtual_ip),
      service_port    => $ports[kubernetes_master_port],
      ip_addresses    => hiera('kubernetes_master_node_ips', $controller_hosts_real),
      server_names    => hiera('kubernetes_master_node_names', $controller_hosts_names_real),
      public_ssl_port => $ports[kubernetes_master_ssl_port],
      service_network => $kubernetes_master_network,
      listen_options  => {
        'balance' => 'roundrobin',
      }
    }
  }

}

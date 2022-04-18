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
# [*haproxy_log_facility*]
#  The syslog facility for HAProxy.
#  Defaults to 'local0'
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
# [*haproxy_lb_mode_longrunning*]
#  HAProxy LB mode to use with the services the clients of which may have the notion
#  of the longrunning requests, like RPC or just API requests that take time.
#  The HAProxy's default roundrobin balance algorithm can be replaced with it.
#  Defaults to "leastconn".
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
# [*use_backend_syntax*]
#  (optional) When set to true, generate a config with frontend and
#  backend sections, otherwise use listen sections.
#  Defaults to hiera('haproxy_backend_syntax', false)
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
# [*haproxy_stats_bind_address*]
#  Bind address for where the haproxy stats web interface should listen on in addition
#  to the controller_virtual_ip
#  A string.or an array
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
# [*manila*]
#  (optional) Enable or not Manila API binding
#  Defaults to hiera('manila_api_enabled', false)
#
# [*glance_api*]
#  (optional) Enable or not Glance API binding
#  Defaults to hiera('glance_api_enabled', false)
#
# [*nova_osapi*]
#  (optional) Enable or not Nova API binding
#  Defaults to hiera('nova_api_enabled', false)
#
# [*placement*]
#  (optional) Enable or not Placement API binding
#  Defaults to hiera('placement_enabled', false)
#
# [*nova_metadata*]
#  (optional) Enable or not Nova metadata binding
#  Defaults to hiera('nova_metadata_enabled', false)
#
# [*nova_novncproxy*]
#  (optional) Enable or not Nova novncproxy binding
#  Defaults to hiera('nova_vnc_proxy_enabled', false)
#
# [*aodh*]
#  (optional) Enable or not Aodh API binding
#  Defaults to hiera('aodh_api_enabled', false)
#
# [*barbican*]
#  (optional) Enable or not Barbican API binding
#  Defaults to hiera('barbican_api_enabled', false)
#
# [*designate*]
#  (optional) Enable or not Designate API binding
#  Defaults to hiera('designate_api_enabled', false)
#
# [*metrics_qdr*]
#  (optional) Enable or not Metrics QDR binding
#  Defaults to hiera('metrics_qdr_enabled', false)
#
# [*gnocchi*]
#  (optional) Enable or not Gnocchi API binding
#  Defaults to hiera('gnocchi_api_enabled', false)
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
# [*mysql_custom_listen_options*]
#  Hash to pass to the mysql haproxy listen stanza to be deepmerged with the other options
#  Defaults to {}
#
# [*mysql_custom_frontend_options*]
#  Hash to pass to the mysql haproxy frontend stanza to be deepmerged with the other options
#  Defaults to {}
#
# [*mysql_custom_backend_options*]
#  Hash to pass to the mysql haproxy backend stanza to be deepmerged with the other options
#  Defaults to {}
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
# [*ceph_rgw*]
#  (optional) Enable or not Ceph RadosGW binding
#  Defaults to hiera('ceph_rgw_enabled', false)
#
# [*ceph_grafana*]
#  (optional) Enable or not Ceph Grafana dashboard binding
#  Defaults to hiera('ceph_grafana_enabled', false)
#
# [*ceph_dashboard*]
#  (optional) Enable or not Ceph Dashboard binding
#  Defaults to hiera('ceph_grafana_enabled', false)
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
# [*ceph_grafana_network*]
#  (optional) Specify the network ceph_grafana is running on.
#  Defaults to hiera('ceph_grafana_network', undef)
#
# [*ceph_dashboard_network*]
#  (optional) Specify the network ceph_dashboard is running on.
#  Defaults to hiera('ceph_dashboard_network', undef)
#
# [*cinder_network*]
#  (optional) Specify the network cinder is running on.
#  Defaults to hiera('cinder_api_network', undef)
#
# [*designate_network*]
#  (optional) Specify the network designate is running on.
#  Defaults to hiera('designate_api_network', undef)
#
# [*metrics_qdr_network*]
#  (optional) Specify the network metrics_qdr is running on.
#  Defaults to hiera('metrics_qdr_network', undef)
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
# [*keystone_sticky_sessions*]
#  (optional) Use cookie-based session persistence for the Keystone
#  public API.
#  Defaults to hiera('keystone_sticky_sessions', false)
#
# [*keystone_session_cookie*]
#  (optional) Use a specified name for the Keystone sticky session cookie.
#  Defaults to hiera('keystone_session_cookie', 'KEYSTONESESSION')
#
# [*manila_network*]
#  (optional) Specify the network manila is running on.
#  Defaults to hiera('manila_api_network', undef)
#
# [*neutron_network*]
#  (optional) Specify the network neutron is running on.
#  Defaults to hiera('neutron_api_network', undef)
#
# [*nova_metadata_network*]
#  (optional) Specify the network nova_metadata is running on.
#  Defaults to hiera('nova_metadata_network', undef)
#
# [*nova_novncproxy_network*]
#  (optional) Specify the network nova_novncproxy is running on.
#  Defaults to hiera('nova_vnc_proxy_network', hiera('nova_libvirt_network', undef))
#
# [*nova_osapi_network*]
#  (optional) Specify the network nova_osapi is running on.
#  Defaults to hiera('nova_api_network', undef)
#
# [*placement_network*]
#  (optional) Specify the network placement is running on.
#  Defaults to hiera('placement_network', undef)
#
# [*etcd_network*]
#  (optional) Specify the network etcd is running on.
#  Defaults to hiera('etcd_network', undef)
#
# [*octavia_network*]
#  (optional) Specify the network octavia is running on.
#  Defaults to hiera('octavia_api_network', undef)
#
# [*ovn_dbs_network*]
#  (optional) Specify the network ovn_dbs is running on.
#  Defaults to hiera('ovn_dbs_network', undef)
#
# [*swift_proxy_server_network*]
#  (optional) Specify the network swift_proxy_server is running on.
#  Defaults to hiera('swift_proxy_network', undef)
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
#    'heat_api_port' (Defaults to 8004)
#    'heat_api_ssl_port' (Defaults to 13004)
#    'heat_cfn_port' (Defaults to 8000)
#    'heat_cfn_ssl_port' (Defaults to 13005)
#    'ironic_api_port' (Defaults to 6385)
#    'ironic_api_ssl_port' (Defaults to 13385)
#    'ironic_inspector_port' (Defaults to 5050)
#    'ironic_inspector_ssl_port' (Defaults to 13050)
#    'keystone_admin_api_port' (Defaults to 35357)
#    'keystone_public_api_port' (Defaults to 5000)
#    'keystone_public_api_ssl_port' (Defaults to 13000)
#    'manila_api_port' (Defaults to 8786)
#    'manila_api_ssl_port' (Defaults to 13786)
#    'metrics_qdr_port' (Defaults to 5666)
#    'neutron_api_port' (Defaults to 9696)
#    'neutron_api_ssl_port' (Defaults to 13696)
#    'nova_api_port' (Defaults to 8774)
#    'nova_api_ssl_port' (Defaults to 13774)
#    'nova_metadata_port' (Defaults to 8775)
#    'nova_novnc_port' (Defaults to 6080)
#    'nova_novnc_ssl_port' (Defaults to 13080)
#    'octavia_api_port' (Defaults to 9876)
#    'octavia_api_ssl_port' (Defaults to 13876)
#    'placement_port' (Defaults to 8778)
#    'placement_ssl_port' (Defaults to 13778)
#    'ovn_nbdb_port' (Defaults to 6641)
#    'ovn_nbdb_ssl_port' (Defaults to 13641)
#    'ovn_sbdb_port' (Defaults to 6642)
#    'ovn_sbdb_ssl_port' (Defaults to 13642)
#    'swift_proxy_port' (Defaults to 8080)
#    'swift_proxy_ssl_port' (Defaults to 13808)
#    'ceph_rgw_port' (Defaults to 8080)
#    'ceph_rgw_ssl_port' (Defaults to 13808)
#    'ceph_grafana_port' (Defaults to 3100)
#    'ceph_grafana_ssl_port' (Defaults to 3100)
#    'ceph_dashboard_port' (Defaults to 8444)
#    'ceph_dashboard_ssl_port' (Defaults to 8444)
#  Defaults to {}
#
class tripleo::haproxy (
  $controller_virtual_ip,
  $public_virtual_ip,
  $use_backend_syntax            = hiera('haproxy_backend_syntax', false),
  $haproxy_service_manage        = true,
  $haproxy_global_maxconn        = 20480,
  $haproxy_default_maxconn       = 4096,
  $haproxy_default_timeout       = [ 'http-request 10s', 'queue 2m', 'connect 10s', 'client 2m', 'server 2m', 'check 30s' ],
  $haproxy_listen_bind_param     = [ 'transparent' ],
  $haproxy_member_options        = [ 'check', 'inter 2000', 'rise 2', 'fall 5' ],
  $haproxy_log_address           = '/dev/log',
  $haproxy_log_facility          = 'local0',
  $activate_httplog              = false,
  $haproxy_globals_override      = {},
  $haproxy_defaults_override     = {},
  $haproxy_lb_mode_longrunning   = 'leastconn',
  $haproxy_daemon                = true,
  $haproxy_socket_access_level   = 'user',
  $haproxy_stats_user            = 'admin',
  $haproxy_stats_password        = undef,
  $haproxy_stats_bind_address    = undef,
  $manage_firewall               = hiera('tripleo::firewall::manage_firewall', true),
  $controller_hosts              = hiera('controller_node_ips'),
  $controller_hosts_names        = hiera('controller_node_names', undef),
  $service_certificate           = undef,
  $use_internal_certificates     = false,
  $internal_certificates_specs   = {},
  $enable_internal_tls           = hiera('enable_internal_tls', false),
  $ssl_cipher_suite              = '!SSLv2:kEECDH:kRSA:kEDH:kPSK:+3DES:!aNULL:!eNULL:!MD5:!EXP:!RC4:!SEED:!IDEA:!DES',
  $ssl_options                   = 'no-sslv3 no-tlsv10',
  $ca_bundle                     = '/etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt',
  $crl_file                      = undef,
  $haproxy_stats_certificate     = undef,
  $haproxy_stats                 = true,
  $keystone_admin                = hiera('keystone_enabled', false),
  $keystone_public               = hiera('keystone_enabled', false),
  $neutron                       = hiera('neutron_api_enabled', false),
  $cinder                        = hiera('cinder_api_enabled', false),
  $manila                        = hiera('manila_api_enabled', false),
  $glance_api                    = hiera('glance_api_enabled', false),
  $nova_osapi                    = hiera('nova_api_enabled', false),
  $placement                     = hiera('placement_enabled', false),
  $nova_metadata                 = hiera('nova_metadata_enabled', false),
  $nova_novncproxy               = hiera('nova_vnc_proxy_enabled', false),
  $aodh                          = hiera('aodh_api_enabled', false),
  $barbican                      = hiera('barbican_api_enabled', false),
  $ceph_grafana                  = hiera('ceph_grafana_enabled', false),
  $ceph_dashboard                = hiera('ceph_grafana_enabled', false),
  $gnocchi                       = hiera('gnocchi_api_enabled', false),
  $swift_proxy_server            = hiera('swift_proxy_enabled', false),
  $heat_api                      = hiera('heat_api_enabled', false),
  $heat_cfn                      = hiera('heat_api_cfn_enabled', false),
  $horizon                       = hiera('horizon_enabled', false),
  $ironic                        = hiera('ironic_api_enabled', false),
  $ironic_inspector              = hiera('ironic_inspector_enabled', false),
  $octavia                       = hiera('octavia_api_enabled', false),
  $designate                     = hiera('designate_api_enabled', false),
  $metrics_qdr                   = hiera('metrics_qdr_enabled', false),
  $mysql                         = hiera('mysql_enabled', false),
  $mysql_clustercheck            = false,
  $mysql_max_conn                = undef,
  $mysql_member_options          = undef,
  $mysql_custom_listen_options   = {},
  $mysql_custom_frontend_options = {},
  $mysql_custom_backend_options  = {},
  $rabbitmq                      = false,
  $etcd                          = hiera('etcd_enabled', false),
  $docker_registry               = hiera('enable_docker_registry', false),
  $redis                         = hiera('redis_enabled', false),
  $redis_password                = undef,
  $ceph_rgw                      = hiera('ceph_rgw_enabled', false),
  $ovn_dbs                       = hiera('ovn_dbs_enabled', false),
  $ovn_dbs_manage_lb             = false,
  $aodh_network                  = hiera('aodh_api_network', undef),
  $barbican_network              = hiera('barbican_api_network', false),
  $ceph_rgw_network              = hiera('ceph_rgw_network', undef),
  $cinder_network                = hiera('cinder_api_network', undef),
  $designate_network             = hiera('designate_api_network', undef),
  $metrics_qdr_network           = hiera('metrics_qdr_network', undef),
  $docker_registry_network       = hiera('docker_registry_network', undef),
  $glance_api_network            = hiera('glance_api_network', undef),
  $gnocchi_network               = hiera('gnocchi_api_network', undef),
  $heat_api_network              = hiera('heat_api_network', undef),
  $ceph_grafana_network          = hiera('ceph_grafana_network', undef),
  $ceph_dashboard_network        = hiera('ceph_dashboard_network', undef),
  $heat_cfn_network              = hiera('heat_api_cfn_network', undef),
  $horizon_network               = hiera('horizon_network', undef),
  $ironic_inspector_network      = hiera('ironic_inspector_network', undef),
  $ironic_network                = hiera('ironic_api_network', undef),
  $keystone_admin_network        = hiera('keystone_admin_api_network', undef),
  $keystone_public_network       = hiera('keystone_public_api_network', undef),
  $keystone_sticky_sessions      = hiera('keystone_sticky_sessions', false),
  $keystone_session_cookie       = hiera('keystone_session_cookie,', 'KEYSTONESESSION'),
  $manila_network                = hiera('manila_api_network', undef),
  $neutron_network               = hiera('neutron_api_network', undef),
  $nova_metadata_network         = hiera('nova_metadata_network', undef),
  $nova_novncproxy_network       = hiera('nova_vnc_proxy_network', hiera('nova_libvirt_network', undef)),
  $nova_osapi_network            = hiera('nova_api_network', undef),
  $placement_network             = hiera('placement_network', undef),
  $octavia_network               = hiera('octavia_api_network', undef),
  $ovn_dbs_network               = hiera('ovn_dbs_network', undef),
  $etcd_network                  = hiera('etcd_network', undef),
  $swift_proxy_server_network    = hiera('swift_proxy_network', undef),
  $service_ports                 = {}
) {
  $default_service_ports = {
    aodh_api_port => 8042,
    aodh_api_ssl_port => 13042,
    barbican_api_port => 9311,
    barbican_api_ssl_port => 13311,
    cinder_api_port => 8776,
    cinder_api_ssl_port => 13776,
    designate_api_port => 9001,
    designate_api_ssl_port => 13001,
    docker_registry_port => 8787,
    docker_registry_ssl_port => 13787,
    etcd_port => 2379,
    glance_api_port => 9292,
    glance_api_ssl_port => 13292,
    gnocchi_api_port => 8041,
    gnocchi_api_ssl_port => 13041,
    heat_api_port => 8004,
    heat_api_ssl_port => 13004,
    heat_cfn_port => 8000,
    heat_cfn_ssl_port => 13005,
    ironic_api_port => 6385,
    ironic_api_ssl_port => 13385,
    ironic_inspector_port => 5050,
    ironic_inspector_ssl_port => 13050,
    keystone_admin_api_port => 35357,
    keystone_public_api_port => 5000,
    keystone_public_api_ssl_port => 13000,
    manila_api_port => 8786,
    manila_api_ssl_port => 13786,
    metrics_qdr_port => 5666,
    neutron_api_port => 9696,
    neutron_api_ssl_port => 13696,
    nova_api_port => 8774,
    nova_api_ssl_port => 13774,
    nova_metadata_port => 8775,
    nova_novnc_port => 6080,
    nova_novnc_ssl_port => 13080,
    octavia_api_port => 9876,
    octavia_api_ssl_port => 13876,
    placement_port => 8778,
    placement_ssl_port => 13778,
    ovn_nbdb_port => 6641,
    ovn_nbdb_ssl_port => 13641,
    ovn_sbdb_port => 6642,
    ovn_sbdb_ssl_port => 13642,
    swift_proxy_port => 8080,
    swift_proxy_ssl_port => 13808,
    ceph_rgw_port => 8080,
    ceph_rgw_ssl_port => 13808,
    ceph_grafana_port => 3100,
    ceph_grafana_ssl_port => 3100,
    ceph_prometheus_port => 9092,
    ceph_prometheus_ssl_port => 9092,
    ceph_alertmanager_port => 9093,
    ceph_alertmanager_ssl_port => 9093,
    ceph_dashboard_port => 8444,
    ceph_dashboard_ssl_port => 8444,
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


  $haproxy_global_options = {
    'log'                      => "${haproxy_log_address} ${haproxy_log_facility}",
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

  class { 'haproxy':
    service_manage   => $haproxy_service_manage,
    global_options   => merge($haproxy_global_options, $haproxy_daemonize, $haproxy_globals_override),
    defaults_options => merge($haproxy_defaults_options, $httplog, $haproxy_defaults_override),
  }


  # NOTE(bogdando): the rule is: *log is only needed for frontend usually,
  # but tcpka and other "durability" related options should be set for both
  # sides, based on a service case by case.
  $default_frontend_options = {
    'option'       => [ 'httplog', 'forwardfor'],
    'http-request' => [
      'set-header X-Forwarded-Proto https if { ssl_fc }',
      'set-header X-Forwarded-Proto http if !{ ssl_fc }',
      'set-header X-Forwarded-Port %[dst_port]'],
  }
  $default_backend_options = {
    'option' => [ 'httpchk' ],
  }
  $default_listen_options = merge_hash_values($default_frontend_options,
                                              $default_backend_options)
  Tripleo::Haproxy::Endpoint {
    haproxy_listen_bind_param   => $haproxy_listen_bind_param,
    member_options              => $haproxy_member_options,
    public_certificate          => $service_certificate,
    use_internal_certificates   => $use_internal_certificates,
    internal_certificates_specs => $internal_certificates_specs,
    listen_options              => $default_listen_options,
    frontend_options            => $default_frontend_options,
    backend_options             => $default_backend_options,
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
    $haproxy_stats_ips_raw = union(any2array($controller_virtual_ip), any2array($haproxy_stats_bind_address))
    $haproxy_stats_ips = delete_undef_values($haproxy_stats_ips_raw)

    class { 'tripleo::haproxy::stats':
      haproxy_listen_bind_param => $haproxy_listen_bind_param,
      ip                        => $haproxy_stats_ips,
      password                  => $haproxy_stats_password,
      certificate               => $haproxy_stats_certificate_real,
      user                      => $haproxy_stats_user,
    }
  }

  $keystone_frontend_opts = {
    'option' => [ 'httplog', 'forwardfor' ]
  }
  $keystone_backend_opts = {
    'option' => [ 'httpchk GET /healthcheck' ]
  }
  $keystone_listen_opts = merge_hash_values($keystone_frontend_opts,
                                              $keystone_backend_opts)
  if $keystone_admin {
    # NOTE(jaosorior): Given that the admin endpoint is in the same vhost
    # nowadays as the public/internal one. We can just loadbalance towards the
    # same IP.
    ::tripleo::haproxy::endpoint { 'keystone_admin':
      internal_ip      => hiera('keystone_admin_api_vip', $controller_virtual_ip),
      service_port     => $ports[keystone_public_api_port],
      haproxy_port     => $ports[keystone_admin_api_port],
      ip_addresses     => hiera('keystone_public_api_node_ips', $controller_hosts_real),
      server_names     => hiera('keystone_public_api_node_names', $controller_hosts_names_real),
      mode             => 'http',
      listen_options   => merge($default_listen_options, $keystone_listen_opts),
      frontend_options => merge($default_frontend_options, $keystone_frontend_opts),
      backend_options  => merge($default_backend_options, $keystone_backend_opts),
      service_network  => $keystone_admin_network,
      member_options   => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  if $keystone_public {
    ::tripleo::haproxy::endpoint { 'keystone_public':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('keystone_public_api_vip', $controller_virtual_ip),
      service_port      => $ports[keystone_public_api_port],
      ip_addresses      => hiera('keystone_public_api_node_ips', $controller_hosts_real),
      server_names      => hiera('keystone_public_api_node_names', $controller_hosts_names_real),
      mode              => 'http',
      listen_options    => merge($default_listen_options, $keystone_listen_opts),
      frontend_options  => merge($default_frontend_options, $keystone_frontend_opts),
      backend_options   => merge($default_backend_options, $keystone_backend_opts),
      public_ssl_port   => $ports[keystone_public_api_ssl_port],
      service_network   => $keystone_public_network,
      sticky_sessions   => $keystone_sticky_sessions,
      session_cookie    => $keystone_session_cookie,
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  if $neutron {
    $neutron_frontend_opts = {
      'option'  => [ 'httplog', 'forwardfor' ]
    }
    $neutron_backend_opts = {
      'balance' => $haproxy_lb_mode_longrunning,
      'option'  => [ 'httpchk GET /healthcheck' ]
    }
    $neutron_listen_opts = merge_hash_values($neutron_frontend_opts,
                                                $neutron_backend_opts)
    ::tripleo::haproxy::endpoint { 'neutron':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('neutron_api_vip', $controller_virtual_ip),
      service_port      => $ports[neutron_api_port],
      ip_addresses      => hiera('neutron_api_node_ips', $controller_hosts_real),
      server_names      => hiera('neutron_api_node_names', $controller_hosts_names_real),
      mode              => 'http',
      listen_options    => merge($default_listen_options, $neutron_listen_opts),
      frontend_options  => merge($default_frontend_options, $neutron_frontend_opts),
      backend_options   => merge($default_backend_options, $neutron_backend_opts),
      public_ssl_port   => $ports[neutron_api_ssl_port],
      service_network   => $neutron_network,
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  if $cinder {
    $cinder_frontend_opts = {
      'option'  => [ 'httplog', 'forwardfor' ],
    }
    $cinder_backend_opts = {
      'option'  => [ 'httpchk GET /healthcheck' ],
      'balance' => $haproxy_lb_mode_longrunning,
    }
    $cinder_listen_opts = merge_hash_values($cinder_frontend_opts,
                                              $cinder_backend_opts)
    ::tripleo::haproxy::endpoint { 'cinder':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('cinder_api_vip', $controller_virtual_ip),
      service_port      => $ports[cinder_api_port],
      ip_addresses      => hiera('cinder_api_node_ips', $controller_hosts_real),
      server_names      => hiera('cinder_api_node_names', $controller_hosts_names_real),
      mode              => 'http',
      listen_options    => merge($default_listen_options, $cinder_listen_opts),
      frontend_options  => merge($default_frontend_options, $cinder_frontend_opts),
      backend_options   => merge($default_backend_options, $cinder_backend_opts),
      public_ssl_port   => $ports[cinder_api_ssl_port],
      service_network   => $cinder_network,
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  if $manila {
    $manila_frontend_opts = {
      'option' => [ 'httplog', 'forwardfor' ],
    }
    $manila_backend_opts = {
      'option' => [ 'httpchk GET /healthcheck' ],
    }
    $manila_listen_opts = merge_hash_values($manila_frontend_opts,
                                              $manila_backend_opts)
    ::tripleo::haproxy::endpoint { 'manila':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('manila_api_vip', $controller_virtual_ip),
      service_port      => $ports[manila_api_port],
      ip_addresses      => hiera('manila_api_node_ips', $controller_hosts_real),
      server_names      => hiera('manila_api_node_names', $controller_hosts_names_real),
      mode              => 'http',
      listen_options    => merge($default_listen_options, $manila_listen_opts),
      frontend_options  => merge($default_frontend_options, $manila_frontend_opts),
      backend_options   => merge($default_backend_options, $manila_backend_opts),
      public_ssl_port   => $ports[manila_api_ssl_port],
      service_network   => $manila_network,
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  if $glance_api {
    $glance_frontend_opts = {
      'option' => [ 'httplog', 'forwardfor' ],
    }
    $glance_backend_opts = {
      'option' => [ 'httpchk GET /healthcheck' ],
    }
    $glance_listen_opts = merge_hash_values($glance_frontend_opts,
                                              $glance_backend_opts)
    ::tripleo::haproxy::endpoint { 'glance_api':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('glance_api_vip', $controller_virtual_ip),
      service_port      => $ports[glance_api_port],
      ip_addresses      => hiera('glance_api_node_ips', $controller_hosts_real),
      server_names      => hiera('glance_api_node_names', $controller_hosts_names_real),
      public_ssl_port   => $ports[glance_api_ssl_port],
      mode              => 'http',
      listen_options    => merge($default_listen_options, $glance_listen_opts),
      frontend_options  => merge($default_frontend_options, $glance_frontend_opts),
      backend_options   => merge($default_backend_options, $glance_backend_opts),
      service_network   => $glance_api_network,
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  if $ceph_grafana {
    ::tripleo::haproxy::endpoint { 'ceph_grafana':
      internal_ip      => hiera('ceph_dashboard_vip', $controller_virtual_ip),
      service_port     => $ports[ceph_grafana_port],
      ip_addresses     => hiera('ceph_grafana_node_ips', $controller_hosts_real),
      server_names     => hiera('ceph_grafana_node_names', $controller_hosts_names_real),
      mode             => 'http',
      public_ssl_port  => $ports[ceph_grafana_ssl_port],
      listen_options   => merge($default_listen_options, {
        'option'  => [ 'httpchk HEAD /', 'httplog', 'forwardfor' ],
        'balance' => 'source',
      }),
      frontend_options => $default_frontend_options,
      backend_options  => merge($default_backend_options, {
        'option'  => [ 'httpchk HEAD /' ],
        'balance' => 'source',
      }),
      service_network  => $ceph_grafana_network,
      member_options   => union($haproxy_member_options, $internal_tls_member_options),
    }
    ::tripleo::haproxy::endpoint { 'ceph_prometheus':
      internal_ip      => hiera('ceph_grafana_vip', $controller_virtual_ip),
      service_port     => $ports[ceph_prometheus_port],
      ip_addresses     => hiera('ceph_grafana_node_ips', $controller_hosts_real),
      server_names     => hiera('ceph_grafana_node_names', $controller_hosts_names_real),
      mode             => 'http',
      public_ssl_port  => $ports[ceph_prometheus_ssl_port],
      listen_options   => merge($default_listen_options, {
        'option'  => [ 'httpchk GET /metrics', 'httplog', 'forwardfor' ],
        'balance' => 'source',
      }),
      frontend_options => $default_frontend_options,
      backend_options  => merge($default_backend_options, {
        'option'  => [ 'httpchk GET /metrics' ],
        'balance' => 'source',
      }),
      service_network  => $ceph_grafana_network,
      member_options   => $haproxy_member_options,
    }
    ::tripleo::haproxy::endpoint { 'ceph_alertmanager':
      internal_ip      => hiera('ceph_grafana_vip', $controller_virtual_ip),
      service_port     => $ports[ceph_alertmanager_port],
      ip_addresses     => hiera('ceph_grafana_node_ips', $controller_hosts_real),
      server_names     => hiera('ceph_grafana_node_names', $controller_hosts_names_real),
      mode             => 'http',
      public_ssl_port  => $ports[ceph_alertmanager_ssl_port],
      listen_options   => merge($default_listen_options, {
        'option'  => [ 'httpchk GET /', 'httplog', 'forwardfor' ],
        'balance' => 'source',
      }),
      frontend_options => $default_frontend_options,
      backend_options  => merge($default_backend_options, {
        'option'  => [ 'httpchk GET /' ],
        'balance' => 'source',
      }),
      service_network  => $ceph_grafana_network,
      member_options   => $haproxy_member_options,
    }
  }

  if $ceph_dashboard {
    if $enable_internal_tls {
      $ceph_dashboard_tls_member_options = ['ssl check verify none']
    } else {
      $ceph_dashboard_tls_member_options = []
    }
    $ceph_dashboard_backend_opts = {
      'option'     => [ 'httpchk HEAD /' ],
      'balance'    => 'source',
      'http-check' => 'expect rstatus 2[0-9][0-9]',
    }
    $ceph_dashboard_listen_opts = merge_hash_values($default_frontend_options,
                                                      $ceph_dashboard_backend_opts)
    ::tripleo::haproxy::endpoint { 'ceph_dashboard':
      internal_ip      => hiera('ceph_dashboard_vip', $controller_virtual_ip),
      service_port     => $ports[ceph_dashboard_port],
      ip_addresses     => hiera('ceph_grafana_node_ips', $controller_hosts_real),
      server_names     => hiera('ceph_grafana_node_names', $controller_hosts_names_real),
      mode             => 'http',
      public_ssl_port  => $ports[ceph_dashboard_ssl_port],
      listen_options   => merge($default_listen_options, $ceph_dashboard_listen_opts),
      frontend_options => $default_frontend_options,
      backend_options  => merge($default_backend_options, $ceph_dashboard_backend_opts),
      service_network  => $ceph_dashboard_network,
      member_options   => union($haproxy_member_options, $ceph_dashboard_tls_member_options),
    }
  }

  $nova_api_vip = hiera('nova_api_vip', $controller_virtual_ip)
  if $nova_osapi {
    # NOTE(tkajinam): Nova doesn't provide healthcheck API
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

  $placement_vip = hiera('placement_vip', $controller_virtual_ip)
  if $placement {
    # NOTE(tkajinam): Placement doesn't provide healthcheck API
    ::tripleo::haproxy::endpoint { 'placement':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => $placement_vip,
      service_port      => $ports[placement_port],
      ip_addresses      => hiera('placement_node_ips', $controller_hosts_real),
      server_names      => hiera('placement_node_names', $controller_hosts_names_real),
      mode              => 'http',
      public_ssl_port   => $ports[placement_ssl_port],
      service_network   => $placement_network,
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  if $nova_metadata {
    # NOTE(tkajinam): Nova doesn't provide healthcheck API
    if hiera('nova_is_additional_cell', undef) {
      $nova_metadata_server_names_real = hiera('nova_metadata_cell_node_names', $controller_hosts_names_real)
    } else {
      $nova_metadata_server_names_real = hiera('nova_metadata_node_names', $controller_hosts_names_real)
    }
    $nova_metadata_backend_opts = {
      'balance'   => 'source',
      'hash-type' => 'consistent',
    }
    $nova_metadata_listen_opts = merge_hash_values($default_listen_options,
                                                      $nova_metadata_backend_opts)
    ::tripleo::haproxy::endpoint { 'nova_metadata':
      internal_ip      => hiera('nova_metadata_vip', $controller_virtual_ip),
      service_port     => $ports[nova_metadata_port],
      ip_addresses     => hiera('nova_metadata_node_ips', $controller_hosts_real),
      server_names     => $nova_metadata_server_names_real,
      mode             => 'http',
      service_network  => $nova_metadata_network,
      member_options   => union($haproxy_member_options, $internal_tls_member_options),
      listen_options   => merge($default_listen_options, $nova_metadata_listen_opts),
      frontend_options => $default_frontend_options,
      backend_options  => merge($default_backend_options, $nova_metadata_backend_opts),
    }
  }

  $nova_vnc_proxy_vip = hiera('nova_vnc_proxy_vip', $controller_virtual_ip)
  if $nova_novncproxy {
    # NOTE(tkajinam): Nova-VNCProxy doesn't provide healthcheck API
    if $enable_internal_tls {
      # we need to make sure we use ssl for checks.
      $haproxy_member_options_real   = delete($haproxy_member_options, 'check')
      $novncproxy_ssl_member_options = ['check-ssl']
    } else {
      $haproxy_member_options_real   = $haproxy_member_options
      $novncproxy_ssl_member_options = []
    }
    if hiera('nova_is_additional_cell', undef) {
      $novncproxy_server_names_real = hiera('nova_vnc_proxy_cell_node_names', $controller_hosts_names_real)
    } else {
      $novncproxy_server_names_real = hiera('nova_vnc_proxy_node_names', $controller_hosts_names_real)
    }
    $nova_vncproxy_frontend_opts = {
      'option'  => [ 'tcpka', 'tcplog' ],
    }
    $nova_vncproxy_backend_opts = {
      'option'  => [ 'tcpka' ],
      'balance' => 'source',
      'timeout' => [ 'tunnel 1h' ],
    }
    $nova_vncproxy_listen_opts = merge_hash_values($nova_vncproxy_frontend_opts,
                                                      $nova_vncproxy_backend_opts)
    ::tripleo::haproxy::endpoint { 'nova_novncproxy':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => $nova_vnc_proxy_vip,
      service_port      => $ports[nova_novnc_port],
      ip_addresses      => hiera('nova_vnc_proxy_node_ips', $controller_hosts_real),
      server_names      => $novncproxy_server_names_real,
      mode              => 'http',
      listen_options    => merge($default_listen_options, $nova_vncproxy_listen_opts),
      frontend_options  => merge($default_frontend_options, $nova_vncproxy_frontend_opts),
      backend_options   => merge($default_backend_options, $nova_vncproxy_backend_opts),
      public_ssl_port   => $ports[nova_novnc_ssl_port],
      service_network   => $nova_novncproxy_network,
      member_options    => union($haproxy_member_options_real, $internal_tls_member_options, $novncproxy_ssl_member_options),
    }
  }

  if $aodh {
    $aodh_frontend_opts = {
      'option' => [ 'httplog', 'forwardfor' ],
    }
    $aodh_backend_opts = {
      'option' => [ 'httpchk GET /healthcheck' ],
    }
    $aodh_listen_opts = merge_hash_values($aodh_frontend_opts,
                                            $aodh_backend_opts)
    ::tripleo::haproxy::endpoint { 'aodh':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('aodh_api_vip', $controller_virtual_ip),
      service_port      => $ports[aodh_api_port],
      ip_addresses      => hiera('aodh_api_node_ips', $controller_hosts_real),
      server_names      => hiera('aodh_api_node_names', $controller_hosts_names_real),
      mode              => 'http',
      listen_options    => merge($default_listen_options, $aodh_listen_opts),
      frontend_options  => merge($default_frontend_options, $aodh_frontend_opts),
      backend_options   => merge($default_backend_options, $aodh_backend_opts),
      public_ssl_port   => $ports[aodh_api_ssl_port],
      service_network   => $aodh_network,
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  if $barbican {
    $barbican_frontend_opts = {
      'option' => [ 'httplog', 'forwardfor' ],
    }
    $barbican_backend_opts = {
      'option' => [ 'httpchk GET /healthcheck' ],
    }
    $barbican_listen_opts = merge_hash_values($barbican_frontend_opts,
                                                $barbican_backend_opts)
    ::tripleo::haproxy::endpoint { 'barbican':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('barbican_api_vip', $controller_virtual_ip),
      service_port      => $ports[barbican_api_port],
      ip_addresses      => hiera('barbican_api_node_ips', $controller_hosts_real),
      server_names      => hiera('barbican_api_node_names', $controller_hosts_names_real),
      public_ssl_port   => $ports[barbican_api_ssl_port],
      service_network   => $barbican_network,
      mode              => 'http',
      listen_options    => merge($default_listen_options, $barbican_listen_opts),
      frontend_options  => merge($default_frontend_options, $barbican_frontend_opts),
      backend_options   => merge($default_backend_options, $barbican_backend_opts),
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  if $gnocchi {
    # NOTE(tkajinam): Gnocchi doesn't provide healthcheck API
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

  if $swift_proxy_server {
    $swift_proxy_server_frontend_options = {
      'option'         => [ 'httplog', 'forwardfor' ],
      'timeout client' => '2m',
    }
    $swift_proxy_server_backend_options = {
      'option'         => [ 'httpchk GET /healthcheck' ],
      'balance'        => $haproxy_lb_mode_longrunning,
      'timeout server' => '2m',
    }
    $swift_proxy_server_listen_options = merge_hash_values($swift_proxy_server_frontend_options,
                                                              $swift_proxy_server_backend_options)
    ::tripleo::haproxy::endpoint { 'swift_proxy_server':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('swift_proxy_vip', $controller_virtual_ip),
      service_port      => $ports[swift_proxy_port],
      ip_addresses      => hiera('swift_proxy_node_ips', $controller_hosts_real),
      server_names      => hiera('swift_proxy_node_names', $controller_hosts_names_real),
      mode              => 'http',
      listen_options    => merge($default_listen_options, $swift_proxy_server_listen_options),
      frontend_options  => merge($default_frontend_options, $swift_proxy_server_frontend_options),
      backend_options   => merge($default_backend_options, $swift_proxy_server_backend_options),
      public_ssl_port   => $ports[swift_proxy_ssl_port],
      service_network   => $swift_proxy_server_network,
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  $heat_api_vip = hiera('heat_api_vip', $controller_virtual_ip)
  $heat_ip_addresses = hiera('heat_api_node_ips', $controller_hosts_real)
  $heat_frontend_options = {
    'option'         => [ 'httplog', 'forwardfor' ],
    'timeout client' => '10m',
  }
  $heat_durability_options = {
    'option'         => [ 'tcpka', 'httpchk GET /healthcheck' ],
    'balance'        => $haproxy_lb_mode_longrunning,
    'timeout server' => '10m',
  }
  if $service_certificate {
    $heat_ssl_options = {
      'http-response' => "replace-header Location http://${public_virtual_ip}(.*) https://${public_virtual_ip}\\1",
    }
    $heat_listen_options = merge($default_listen_options, $heat_ssl_options, $heat_frontend_options)
    $heat_frontend_options_real = merge($default_frontend_options, $heat_ssl_options, $heat_frontend_options)
  } else {
    $heat_listen_options = merge($default_listen_options, $heat_frontend_options)
    $heat_frontend_options_real = merge($default_frontend_options, $heat_frontend_options)
  }
  $heat_listen_options_real = merge_hash_values($heat_listen_options, $heat_durability_options)
  $heat_backend_options = merge($default_backend_options, $heat_durability_options)

  if $heat_api {
    ::tripleo::haproxy::endpoint { 'heat_api':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => $heat_api_vip,
      service_port      => $ports[heat_api_port],
      ip_addresses      => $heat_ip_addresses,
      server_names      => hiera('heat_api_node_names', $controller_hosts_names_real),
      mode              => 'http',
      listen_options    => $heat_listen_options_real,
      frontend_options  => $heat_frontend_options_real,
      backend_options   => $heat_backend_options,
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
      listen_options    => $heat_listen_options_real,
      frontend_options  => $heat_frontend_options_real,
      backend_options   => $heat_backend_options,
      public_ssl_port   => $ports[heat_cfn_ssl_port],
      service_network   => $heat_cfn_network,
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  if $horizon {
    class { 'tripleo::haproxy::horizon_endpoint':
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
      manage_firewall             => $manage_firewall,
    }
  }

  if $ironic {
    $ironic_frontend_opts = {
      'option' => [ 'httplog', 'forwardfor' ],
    }
    $ironic_backend_opts = {
      'option' => [ 'httpchk GET /healthcheck' ],
    }
    $ironic_listen_opts = merge_hash_values($ironic_frontend_opts,
                                            $ironic_backend_opts)
    ::tripleo::haproxy::endpoint { 'ironic':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('ironic_api_vip', $controller_virtual_ip),
      service_port      => $ports[ironic_api_port],
      ip_addresses      => hiera('ironic_api_node_ips', $controller_hosts_real),
      server_names      => hiera('ironic_api_node_names', $controller_hosts_names_real),
      mode              => 'http',
      frontend_options  => merge($default_frontend_options, $ironic_frontend_opts),
      backend_options   => merge($default_backend_options, $ironic_backend_opts),
      listen_options    => merge($default_listen_options, $ironic_listen_opts),
      public_ssl_port   => $ports[ironic_api_ssl_port],
      service_network   => $ironic_network,
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  if $ironic_inspector {
    $ironic_inspector_frontend_opts = {
      'option' => [ 'httplog', 'forwardfor' ],
    }
    $ironic_inspector_backend_opts = {
      'option'  => [ 'httpchk' ],
      'balance' => $haproxy_lb_mode_longrunning
    }
    $ironic_inspector_listen_opts = merge_hash_values($ironic_inspector_frontend_opts,
                                                        $ironic_inspector_backend_opts)
    # NOTE(tkajinam): Ironic-inspector doesn't provide healthcheck API
    ::tripleo::haproxy::endpoint { 'ironic-inspector':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('ironic_inspector_vip', $controller_virtual_ip),
      service_port      => $ports[ironic_inspector_port],
      ip_addresses      => hiera('ironic_inspector_node_ips', $controller_hosts_real),
      server_names      => hiera('ironic_inspector_node_names', $controller_hosts_names_real),
      public_ssl_port   => $ports[ironic_inspector_ssl_port],
      service_network   => $ironic_inspector_network,
      mode              => 'http',
      listen_options    => merge($default_listen_options, $ironic_inspector_listen_opts),
      frontend_options  => merge($default_frontend_options, $ironic_inspector_frontend_opts),
      backend_options   => merge($default_backend_options, $ironic_inspector_backend_opts),
    }
  }

  if $designate {
    $designate_frontend_opts = {
      'option' => [ 'httplog', 'forwardfor' ],
    }
    $designate_backend_opts = {
      'option' => [ 'httpchk GET /healthcheck' ],
    }
    $designate_listen_opts = merge_hash_values($designate_frontend_opts,
                                                  $designate_backend_opts)
    ::tripleo::haproxy::endpoint { 'designate':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('designate_api_vip', $controller_virtual_ip),
      service_port      => $ports[designate_api_port],
      ip_addresses      => hiera('designate_api_node_ips', $controller_hosts_real),
      server_names      => hiera('designate_api_node_names', $controller_hosts_names_real),
      mode              => 'http',
      listen_options    => merge($default_listen_options, $designate_listen_opts),
      frontend_options  => merge($default_frontend_options, $designate_frontend_opts),
      backend_options   => merge($default_backend_options, $designate_backend_opts),
      public_ssl_port   => $ports[designate_api_ssl_port],
      service_network   => $designate_network,
    }
  }

  if $metrics_qdr {
    $metrics_bind_opts = {
      "${public_virtual_ip}:${ports[metrics_qdr_port]}" => $haproxy_listen_bind_param,
    }
    if $use_backend_syntax {
      haproxy::frontend { 'metrics_qdr':
        bind             => $metrics_bind_opts,
        options          => {
          'default_backend' => 'metrics_qdr_be',
          'option'          => [ 'tcplog' ],
        },
        collect_exported => false,
      }
      haproxy::backend { 'metrics_qdr_be':
        options => {
          'option'    => [ 'tcp-check' ],
          'tcp-check' => ["connect port ${ports[metrics_qdr_port]}"],
        },
      }
      $metrics_qdr_service = 'metrics_qdr_be'
    } else {
      haproxy::listen { 'metrics_qdr':
        bind             => $metrics_bind_opts,
        options          => {
          'option'    => [ 'tcp-check', 'tcplog' ],
          'tcp-check' => ["connect port ${ports[metrics_qdr_port]}"],
        },
        collect_exported => false,
      }
      $metrics_qdr_service = 'metrics_qdr'
    }
    # Note(mmagr): while MetricsQdr service runs on all overcloud nodes, we need load balancing
    # only on controllers as those are only QDRs forming mesh (listening on connection
    # from QDRs running other nodes [storage, compute, etc.]). Sadly we don't have another
    # reasonable way to get list of internal_api interfaces of controllers than using list
    # of other services running only on controllers and also using internal_api network.
    # MetricsQdr will be refactored (split to QDR running on controller or on other node)
    # to better integrate, but for now we need this hack to enable the feature
    haproxy::balancermember { 'metrics_qdr':
      listening_service => $metrics_qdr_service,
      ports             => $ports[metrics_qdr_port],
      ipaddresses       => hiera('pacemaker_node_ips', $controller_hosts_real),
      server_names      => hiera('pacemaker_node_names', $controller_hosts_names_real),
      options           => union($haproxy_member_options, ['on-marked-down shutdown-sessions']),
      verifyhost        => false,
    }
  }

  if $mysql_clustercheck {
    $mysql_frontend_opts = {
      'option'         => [ 'tcpka', 'tcplog' ],
      'timeout client' => '90m',
      'maxconn'        => $mysql_max_conn
    }
    $mysql_backend_opts = {
      'option'         => [ 'tcpka', 'httpchk' ],
      'stick-table'    => 'type ip size 1000',
      'stick'          => 'on dst',
      'timeout server' => '90m',
    }
    $mysql_listen_opts = merge_hash_values($mysql_frontend_opts,
                                              $mysql_backend_opts)
    if $mysql_member_options {
        $mysql_member_options_real = $mysql_member_options
    } else {
        $mysql_member_options_real = ['backup', 'port 9200', 'on-marked-down shutdown-sessions', 'check', 'inter 1s']
    }
  } else {
    $mysql_frontend_opts = {
      'timeout client' => '90m',
      'maxconn'        => $mysql_max_conn
    }
    $mysql_backend_opts = {
      'timeout server' => '90m',
    }
    $mysql_listen_opts = merge_hash_values($mysql_frontend_opts,
                                              $mysql_backend_opts)
    if $mysql_member_options {
        $mysql_member_options_real = $mysql_member_options
    } else {
        $mysql_member_options_real = union($haproxy_member_options, ['backup'])
    }
  }

  if $mysql {
    if hiera('nova_is_additional_cell', undef) {
      $mysql_server_names_real = hiera('mysql_cell_node_names', $controller_hosts_names_real)
    } else {
      $mysql_server_names_real = hiera('mysql_node_names', $controller_hosts_names_real)
    }
    if $use_backend_syntax {
      haproxy::frontend { 'mysql':
        bind             => $mysql_bind_opts,
        options          => deep_merge($mysql_frontend_opts,
                                          { 'default_backend' => 'mysql_be' },
                                          $mysql_custom_frontend_options),
        collect_exported => false,
      }
      haproxy::backend { 'mysql_be':
        options => deep_merge($mysql_backend_opts, $mysql_custom_backend_options),
      }
      $mysql_service = 'mysql_be'
    } else {
      haproxy::listen { 'mysql':
        bind             => $mysql_bind_opts,
        options          => deep_merge($mysql_listen_opts, $mysql_custom_listen_options),
        collect_exported => false,
      }
      $mysql_service = 'mysql'
    }
    haproxy::balancermember { 'mysql-backup':
      listening_service => $mysql_service,
      ports             => '3306',
      ipaddresses       => hiera('mysql_node_ips', $controller_hosts_real),
      server_names      => $mysql_server_names_real,
      options           => $mysql_member_options_real,
    }
    if $manage_firewall {
      include tripleo::firewall
      $mysql_firewall_rules = {
        '100 mysql_haproxy' => {
          'dport' => 3306,
        }
      }
      create_resources('tripleo::firewall::rule', $mysql_firewall_rules)
    }
  }

  if $rabbitmq {
    if $use_backend_syntax {
      haproxy::frontend { 'rabbitmq':
        bind             => $rabbitmq_bind_opts,
        collect_exported => false,
        options          => {
          'default_backend' => 'rabbitmq_be',
          'option'          => [ 'tcpka', 'tcplog' ],
          'timeout'         => [ 'client 0' ],
        },
      }
      haproxy::backend { 'rabbitmq_be':
        options => {
          'option'  => [ 'tcpka' ],
          'timeout' => [ 'server 0' ],
        },
      }
      $rabbitmq_service = 'rabbitmq_be'
    } else {
      haproxy::listen { 'rabbitmq':
        bind             => $rabbitmq_bind_opts,
        options          => {
          'option'  => [ 'tcpka', 'tcplog' ],
          'timeout' => [ 'client 0', 'server 0' ],
        },
        collect_exported => false,
      }
      $rabbitmq_service = 'rabbitmq'
    }
    haproxy::balancermember { 'rabbitmq':
      listening_service => $rabbitmq_service,
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
      },
      backend_options => {
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
    $redis_vip = hiera('redis_vip', $controller_virtual_ip)
    $redis_bind_opts = {
      "${redis_vip}:6379" => $haproxy_listen_bind_param,
    }

    if $enable_internal_tls {
      $redis_tcp_check_ssl_options = ['connect port 6379 ssl']
      $redis_ssl_member_options = ['check-ssl', "ca-file ${ca_bundle}"]
    } else {
      $redis_tcp_check_ssl_options = ['connect port 6379']
      $redis_ssl_member_options = []
    }
    if $redis_password {
      $redis_tcp_check_password_options = ["send AUTH\\ ${redis_password}\\r\\n",
                                            'expect string +OK']
    } else {
      $redis_tcp_check_password_options = []
    }
    $redis_tcp_check_connect_options = union($redis_tcp_check_ssl_options, $redis_tcp_check_password_options)
    $redis_tcp_check_common_options = ['send PING\r\n',
                                        'expect string +PONG',
                                        'send info\ replication\r\n',
                                        'expect string role:master',
                                        'send QUIT\r\n',
                                        'expect string +OK']
    $redis_tcp_check_options = $redis_tcp_check_connect_options + $redis_tcp_check_common_options
    if $use_backend_syntax {
      haproxy::frontend { 'redis':
        bind             => $redis_bind_opts,
        collect_exported => false,
        options          => {
          'timeout client'  => '90m',
          'default_backend' => 'redis_be',
          'option'          => [ 'tcplog' ],
        },
      }
      haproxy::backend { 'redis_be':
        options => {
          'timeout server' => '90m',
          'balance'        => 'first',
          'option'         => [ 'tcp-check' ],
          'tcp-check'      => $redis_tcp_check_options,
        },
      }
      $redis_service = 'redis_be'
    } else {
      haproxy::listen { 'redis':
        bind             => $redis_bind_opts,
        options          => {
          'balance'        => 'first',
          'timeout client' => '90m',
          'timeout server' => '90m',
          'option'         => [ 'tcp-check', 'tcplog' ],
          'tcp-check'      => $redis_tcp_check_options,
        },
        collect_exported => false,
      }
      $redis_service = 'redis'
    }
    haproxy::balancermember { 'redis':
      listening_service => $redis_service,
      ports             => '6379',
      ipaddresses       => hiera('redis_node_ips', $controller_hosts_real),
      server_names      => hiera('redis_node_names', $controller_hosts_names_real),
      options           => union($haproxy_member_options, ['on-marked-down shutdown-sessions'], $redis_ssl_member_options),
      verifyhost        => false,
    }
    if $manage_firewall {
      include tripleo::firewall
      $redis_firewall_rules = {
        '100 redis_haproxy' => {
          'dport' => 6379,
        }
      }
      create_resources('tripleo::firewall::rule', $redis_firewall_rules)
    }
  }

  if $ceph_rgw {
    $ceph_rgw_backend_opts = {
      'option'  => [ 'httpchk GET /swift/healthcheck' ],
      'balance' => $haproxy_lb_mode_longrunning
    }
    $ceph_rgw_listen_opts = merge_hash_values($default_frontend_options,
                                                $ceph_rgw_backend_opts)
    ::tripleo::haproxy::endpoint { 'ceph_rgw':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('ceph_rgw_vip', $controller_virtual_ip),
      service_port      => $ports[ceph_rgw_port],
      ip_addresses      => hiera('ceph_rgw_node_ips', $controller_hosts_real),
      server_names      => hiera('ceph_rgw_node_names', $controller_hosts_names_real),
      mode              => 'http',
      public_ssl_port   => $ports[ceph_rgw_ssl_port],
      service_network   => $ceph_rgw_network,
      listen_options    => merge($default_listen_options, $ceph_rgw_listen_opts),
      frontend_options  => $default_frontend_options,
      backend_options   => merge($default_backend_options, $ceph_rgw_backend_opts),
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
    }
  }

  if $octavia {
    $octavia_frontend_opts = {
      'option'    => [ 'httplog', 'forwardfor' ],
    }
    $octavia_backend_opts = {
      'hash-type' => 'consistent',
      'option'    => [ 'httpchk GET /healthcheck' ],
      'balance'   => 'source',
    }
    $octavia_listen_opts = merge_hash_values($octavia_frontend_opts,
                                                $octavia_backend_opts)
    ::tripleo::haproxy::endpoint { 'octavia':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('octavia_api_vip', $controller_virtual_ip),
      service_port      => $ports[octavia_api_port],
      ip_addresses      => hiera('octavia_api_node_ips'),
      server_names      => hiera('octavia_api_node_names'),
      public_ssl_port   => $ports[octavia_api_ssl_port],
      service_network   => $octavia_network,
      mode              => 'http',
      member_options    => union($haproxy_member_options, $internal_tls_member_options),
      listen_options    => merge($default_listen_options, $octavia_listen_opts),
      frontend_options  => merge($default_frontend_options, $octavia_frontend_opts),
      backend_options   => $octavia_backend_opts,
    }
  }

  if $ovn_dbs and $ovn_dbs_manage_lb {
    # FIXME: is this config enough to ensure we only hit the first node in
    # ovn_northd_node_ips ?
    # We only configure ovn_dbs_vip in haproxy if HA for OVN DB servers is
    # disabled.
    # If HA is enabled, pacemaker configures the OVN DB servers accordingly.
    $ovn_db_frontend_opts = {
      'option'         => [ 'tcpka', 'tcplog' ],
      'timeout client' => '90m',
    }
    $ovn_db_backend_opts = {
      'option'         => [ 'tcpka' ],
      'timeout server' => '90m',
      'stick-table'    => 'type ip size 1000',
      'stick'          => 'on dst',
    }
    $ovn_db_listen_opts = merge_hash_values($ovn_db_frontend_opts,
                                              $ovn_db_backend_opts)
    ::tripleo::haproxy::endpoint { 'ovn_nbdb':
      public_virtual_ip => $public_virtual_ip,
      internal_ip       => hiera('ovn_dbs_vip', $controller_virtual_ip),
      service_port      => $ports[ovn_nbdb_port],
      ip_addresses      => hiera('ovn_dbs_node_ips', $controller_hosts_real),
      server_names      => hiera('ovn_dbs_node_names', $controller_hosts_names_real),
      service_network   => $ovn_dbs_network,
      public_ssl_port   => $ports[ovn_nbdb_ssl_port],
      listen_options    => $ovn_db_listen_opts,
      frontend_options  => $ovn_db_frontend_opts,
      backend_options   => $ovn_db_backend_opts,
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
      listen_options    => $ovn_db_listen_opts,
      frontend_options  => $ovn_db_frontend_opts,
      backend_options   => $ovn_db_backend_opts,
      mode              => 'tcp'
    }
  }
}

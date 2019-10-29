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
# == class: tripleo::profile::base::certmonger_user
#
# Profile that ensures that the relevant certmonger certificates have been
# requested. The certificates come from the hiera set by the specific profiles
# and come in a pre-defined format.
# For a service that has several certificates (one per network name):
#   apache_certificates_specs:
#     httpd-internal_api:
#       hostname: <overcloud controller fqdn>
#       service_certificate: <service certificate path>
#       service_key: <service key path>
#       principal: "HTTP/<overcloud controller fqdn>"
# For a service that uses a single certificate:
#   mysql_certificates_specs:
#     hostname: <overcloud controller fqdn>
#     service_certificate: <service certificate path>
#     service_key: <service key path>
#     principal: "mysql/<overcloud controller fqdn>"
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step', 1)
#
# [*apache_certificates_specs*]
#   (Optional) The specifications to give to certmonger for the certificate(s)
#   it will create.
#   Defaults to hiera('apache_certificate_specs', {}).
#
# [*haproxy_certificates_specs*]
#   (Optional) The specifications to give to certmonger for the certificate(s)
#   it will create.
#   Defaults to hiera('tripleo::profile::base::haproxy::certificate_specs', {}).
#
# [*libvirt_certificates_specs*]
#   (Optional) The specifications to give to certmonger for the certificate(s)
#   it will create.
#   Defaults to hiera('libvirt_certificates_specs', {}).
#
# [*libvirt_postsave_cmd*]
#   (Optional) If set, it overrides the default way to restart libvirt when the
#   certificate is renewed.
#   Defaults to undef
#
# [*libvirt_vnc_certificates_specs*]
#   (Optional) The specifications to give to certmonger for the certificate(s)
#   it will create.
#   Defaults to hiera('libvirt_vnc_certificates_specs', {}).
#
# [*libvirt_vnc_postsave_cmd*]
#   (Optional) If set, it overrides the default way to restart services when the
#   certificate is renewed.
#   Defaults to undef
#
# [*mongodb_certificate_specs*]
#   (Optional) The specifications to give to certmonger for the certificate(s)
#   it will create.
#   Defaults to hiera('mongodb_certificate_specs',{})
#
# [*qdr_certificate_specs*]
#   (Optional) The specifications to give to certmonger fot the certificate(s)
#   it will create.
#   Defaults to hiera('tripleo::profile::base::metrics::qdr::certificate_specs', {}).
#
# [*mysql_certificate_specs*]
#   (Optional) The specifications to give to certmonger for the certificate(s)
#   it will create.
#   Defaults to hiera('tripleo::profile::base::database::mysql::certificate_specs', {}).
#
# [*rabbitmq_certificate_specs*]
#   (Optional) The specifications to give to certmonger for the certificate(s)
#   it will create.
#   Defaults to hiera('tripleo::profile::base::rabbitmq::certificate_specs', {}).
#
# [*redis_certificate_specs*]
#   (Optional) The specifications to give to certmonger for the certificate(s)
#   it will create.
#   Defaults to hiera('redis_certificate_specs', {}).
#
# [*etcd_certificate_specs*]
#   (Optional) The specifications to give to certmonger for the certificate(s)
#   it will create.
#   Defaults to hiera('tripleo::profile::base::etcd::certificate_specs', {}).
#
# [*odl_certificate_specs*]
#   (Optional) The specifications to give to certmonger for the certificate(s)
#   it will create.
#   Defaults to hiera('tripleo::profile::base::odl::certificate_specs', {}).
#
# [*ovs_certificate_specs*]
#   (Optional) The specifications to give to certmonger for the certificate(s)
#   it will create.
#   Defaults to hiera('tripleo::profile::base::ovs::certificate_specs', {}).
#
# [*neutron_certificate_specs*]
#   (Optional) The specifications to give to certmonger for the certificate(s)
#   it will create.
#   Defaults to hiera('tripleo::profile::base::neutron::certificate_specs', {}).
#
# [*novnc_proxy_certificates_specs*]
#   (Optional) The specifications to give to certmonger for the certificate(s)
#   it will create.
#   Defaults to hiera('novnc_proxy_certificates_specs',{})
#
# [*novnc_proxy_postsave_cmd*]
#   (Optional) If set, it overrides the default way to restart novnc proxy when the
#   certificate is renewed.
#   Defaults to undef
#
# === Deprecated
#
# [*haproxy_postsave_cmd*]
#   (Optional) If set, it overrides the default way to restart haproxy when the
#   certificate is renewed.
#   Defaults to undef
#
# [*apache_postsave_cmd*]
#   (Optional) If set, it overrides the default way to restart apache when the
#   certificate is renewed.
#   Defaults to undef
#
class tripleo::profile::base::certmonger_user (
  $step                       = Integer(hiera('step', 1)),
  $apache_certificates_specs  = hiera('apache_certificates_specs', {}),
  $haproxy_certificates_specs = hiera('tripleo::profile::base::haproxy::certificates_specs', {}),
  $libvirt_certificates_specs = hiera('libvirt_certificates_specs', {}),
  $libvirt_postsave_cmd       = undef,
  $libvirt_vnc_certificates_specs = hiera('libvirt_vnc_certificates_specs', {}),
  $libvirt_vnc_postsave_cmd       = undef,
  $mongodb_certificate_specs  = hiera('mongodb_certificate_specs',{}),
  $qdr_certificate_specs      = hiera('tripleo::profile::base::metrics::qdr::certificate_specs', {}),
  $mysql_certificate_specs    = hiera('tripleo::profile::base::database::mysql::certificate_specs', {}),
  $rabbitmq_certificate_specs = hiera('tripleo::profile::base::rabbitmq::certificate_specs', {}),
  $redis_certificate_specs    = hiera('redis_certificate_specs', {}),
  $etcd_certificate_specs     = hiera('tripleo::profile::base::etcd::certificate_specs', {}),
  $odl_certificate_specs      = hiera('tripleo::profile::base::neutron::opendaylight::certificate_specs', {}),
  $ovs_certificate_specs      = hiera('tripleo::profile::base::neutron::plugins::ovs::opendaylight::certificate_specs', {}),
  $neutron_certificate_specs  = hiera('tripleo::profile::base::neutron::certificate_specs', {}),
  $novnc_proxy_certificates_specs = hiera('novnc_proxy_certificates_specs',{}),
  $novnc_proxy_postsave_cmd   = undef,
  # Deprecated
  $haproxy_postsave_cmd       = undef,
  $apache_postsave_cmd        = undef,
) {
  if $step == 1  {
    unless empty($haproxy_certificates_specs) {
      $reload_haproxy = ['systemctl reload haproxy']
      Class['::tripleo::certmonger::ca::crl'] ~> Haproxy::Balancermember<||>
      if defined(Class['::haproxy']) {
        Class['::tripleo::certmonger::ca::crl'] ~> Class['::haproxy']
      }
    } else {
      $reload_haproxy = []
    }
    class { '::tripleo::certmonger::ca::crl' :
      reload_cmds => $reload_haproxy,
    }
    Certmonger_certificate<||> -> Class['::tripleo::certmonger::ca::crl']
    include ::tripleo::certmonger::ca::libvirt
    include ::tripleo::certmonger::ca::libvirt_vnc

    # Remove apache_certificates_specs where hostname is empty.
    # Workaround bug: https://bugs.launchpad.net/tripleo/+bug/1811207
    $apache_certificates_specs_filtered = $apache_certificates_specs.filter | $specs, $keys | { ! empty($keys[hostname]) }
    unless empty($apache_certificates_specs_filtered) {
      include ::tripleo::certmonger::apache_dirs
      ensure_resources('tripleo::certmonger::httpd', $apache_certificates_specs_filtered)
    }
    unless empty($libvirt_certificates_specs) {
      include ::tripleo::certmonger::libvirt_dirs
      ensure_resources('tripleo::certmonger::libvirt', $libvirt_certificates_specs,
                        {'postsave_cmd' => $libvirt_postsave_cmd})
    }
    unless empty($libvirt_vnc_certificates_specs) {
      include ::tripleo::certmonger::libvirt_vnc_dirs
      ensure_resources('tripleo::certmonger::libvirt_vnc', $libvirt_vnc_certificates_specs,
                        {'postsave_cmd' => $libvirt_vnc_postsave_cmd})
    }
    unless empty($haproxy_certificates_specs) {
      include ::tripleo::certmonger::haproxy_dirs
      ensure_resources('tripleo::certmonger::haproxy', $haproxy_certificates_specs)
      # The haproxy fronends (or listen resources) depend on the certificate
      # existing and need to be refreshed if it changed.
      Tripleo::Certmonger::Haproxy<||> ~> Haproxy::Listen<||>
    }
    unless empty($mongodb_certificate_specs) {
      ensure_resource('class', 'tripleo::certmonger::mongodb', $mongodb_certificate_specs)
    }
    unless empty($qdr_certificate_specs) {
      ensure_resource('class', 'tripleo::certmonger::metrics_qdr', $qdr_certificate_specs)
    }
    unless empty($mysql_certificate_specs) {
      ensure_resource('class', 'tripleo::certmonger::mysql', $mysql_certificate_specs)
    }
    unless empty($rabbitmq_certificate_specs) {
      ensure_resource('class', 'tripleo::certmonger::rabbitmq', $rabbitmq_certificate_specs)
    }
    unless empty($redis_certificate_specs) {
      ensure_resource('class', 'tripleo::certmonger::redis', $redis_certificate_specs)
    }
    unless empty($etcd_certificate_specs) {
      ensure_resource('class', 'tripleo::certmonger::etcd', $etcd_certificate_specs)
    }
    unless empty($odl_certificate_specs) {
      ensure_resource('class', 'tripleo::certmonger::opendaylight', $odl_certificate_specs)
    }
    unless empty($ovs_certificate_specs) {
      ensure_resource('class', 'tripleo::certmonger::openvswitch', $ovs_certificate_specs)
    }
    unless empty($neutron_certificate_specs) {
      ensure_resource('class', 'tripleo::certmonger::neutron', $neutron_certificate_specs)
    }
    unless empty($novnc_proxy_certificates_specs) {
      ensure_resource('class', 'tripleo::certmonger::novnc_proxy', $novnc_proxy_certificates_specs,
                        {'postsave_cmd' => $novnc_proxy_postsave_cmd})
    }
  }
}

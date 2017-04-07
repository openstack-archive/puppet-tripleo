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
# [*etcd_certificate_specs*]
#   (Optional) The specifications to give to certmonger for the certificate(s)
#   it will create.
#   Defaults to hiera('tripleo::profile::base::etcd::certificate_specs', {}).
#
class tripleo::profile::base::certmonger_user (
  $apache_certificates_specs  = hiera('apache_certificates_specs', {}),
  $haproxy_certificates_specs = hiera('tripleo::profile::base::haproxy::certificates_specs', {}),
  $libvirt_certificates_specs = hiera('libvirt_certificates_specs', {}),
  $mysql_certificate_specs    = hiera('tripleo::profile::base::database::mysql::certificate_specs', {}),
  $rabbitmq_certificate_specs = hiera('tripleo::profile::base::rabbitmq::certificate_specs', {}),
  $etcd_certificate_specs     = hiera('tripleo::profile::base::etcd::certificate_specs', {}),
) {
  include ::tripleo::certmonger::ca::libvirt

  unless empty($apache_certificates_specs) {
    ensure_resources('tripleo::certmonger::httpd', $apache_certificates_specs)
  }
  unless empty($libvirt_certificates_specs) {
    include ::tripleo::certmonger::libvirt_dirs
    ensure_resources('tripleo::certmonger::libvirt', $libvirt_certificates_specs)
  }
  unless empty($haproxy_certificates_specs) {
    ensure_resources('tripleo::certmonger::haproxy', $haproxy_certificates_specs)
    # The haproxy fronends (or listen resources) depend on the certificate
    # existing and need to be refreshed if it changed.
    Tripleo::Certmonger::Haproxy<||> ~> Haproxy::Listen<||>
  }
  unless empty($mysql_certificate_specs) {
    ensure_resource('class', 'tripleo::certmonger::mysql', $mysql_certificate_specs)
  }
  unless empty($rabbitmq_certificate_specs) {
    ensure_resource('class', 'tripleo::certmonger::rabbitmq', $rabbitmq_certificate_specs)
  }
  unless empty($etcd_certificate_specs) {
    ensure_resource('class', 'tripleo::certmonger::etcd', $etcd_certificate_specs)
  }
}

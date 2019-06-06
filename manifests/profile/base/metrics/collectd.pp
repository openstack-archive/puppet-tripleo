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
# == Class: tripleo::profile::base::metrics::collectd
#
# Collectd configuration for TripleO
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*enable_file_logging*]
#   (Optional) Boolean. Whether to enable logfile plugin.
#   which we should send metrics.
#   Defaults to false
#
# [*collectd_server*]
#   (Optional) String. The name or address of a collectd server to
#   which we should send metrics.
#
# [*collectd_port*]
#   (Optional) Integer. The port to which we will connect on the
#   collectd server.
#
# [*collectd_username*]
#   (Optional) String.  Username for authenticating to the remote
#   collectd server.
#
# [*collectd_password*]
#   (Optional) String. Password for authenticating to the remote
#   collectd server.
#
# [*collectd_securitylevel*]
#   (Optional) String.
#
# [*gnocchi_auth_mode*]
#   (Optional) String. Type of authentication Gnocchi server is using.
#   Supported values are 'basic' and 'keystone'.
#   Defaults to 'basic'
#
# [*gnocchi_protocol*]
#   (Optional) String. API protocol Gnocchi server is using.
#   Defaults to 'http'
#
# [*gnocchi_server*]
#   (Optional) String. The name or address of a gnocchi endpoint to
#   which we should send metrics.
#   Defaults to undef
#
# [*gnocchi_port*]
#   (Optional) Integer. The port to which we will connect on the
#   Gnocchi server.
#   Defaults to 8041
#
# [*gnocchi_user*]
#   (Optional) String. Username for authenticating to the remote
#   Gnocchi server using simple authentication.
#   Defaults to undef
#
# [*gnocchi_keystone_auth_url*]
#   (Optional) String. Keystone endpoint URL to authenticate to.
#   Defaults to undef
#
# [*gnocchi_keystone_user_name*]
#   (Optional) String. Username for authenticating to Keystone.
#   Defaults to undef
#
# [*gnocchi_keystone_user_id*]
#   (Optional) String. User ID for authenticating to Keystone.
#   Defaults to undef
#
# [*gnocchi_keystone_password*]
#   (Optional) String. Password for authenticating to Keystone
#   Defaults to undef
#
# [*gnocchi_keystone_project_id*]
#   (Optional) String. Project ID for authenticating to Keystone.
#   Defaults to undef
#
# [*gnocchi_keystone_project_name*]
#   (Optional) String. Project name for authenticating to Keystone.
#   Defaults to undef
#
# [*gnocchi_keystone_user_domain_id*]
#   (Optional) String. User domain ID for authenticating to Keystone.
#   Defaults to undef
#
# [*gnocchi_keystone_user_domain_name*]
#   (Optional) String. User domain name for authenticating to Keystone.
#   Defaults to undef
#
# [*gnocchi_keystone_project_domain_id*]
#   (Optional) String. Project domain ID for authenticating to Keystone.
#   Defaults to undef
#
# [*gnocchi_keystone_project_domain_name*]
#   (Optional) String. Project domain name for authenticating to Keystone.
#   Defaults to undef
#
# [*gnocchi_keystone_region_name*]
#   (Optional) String. Region name for authenticating to Keystone.
#   Defaults to undef
#
# [*gnocchi_keystone_interface*]
#   (Optional) String. Type of Keystone endpoint to authenticate to.
#   Defaults to undef
#
# [*gnocchi_keystone_endpoint*]
#   (Optional) String. Explicitly state Gnocchi server URL if you want
#   to override Keystone value
#   Defaults to undef
#
# [*gnocchi_resource_type*]
#   (Optional) String. Default resource type created by the collectd-gnocchi
#   plugin in Gnocchi to store hosts.
#   Defaults to 'collectd'
#
# [*gnocchi_batch_size*]
#   (Optional) String. Minimum number of values Gnocchi should batch.
#   Defaults to 10
#
# [*service_names*]
#   (Optional) List of strings.  A list of active services in this tripleo
#   deployment. This is used to look up service-specific plugins that
#   need to be installed.
#
# [*collectd_manage_repo*]
#   (Optional) Boolean. Whether let collectd enable manage repositories.
#   If it is set to true the epel repository will be used
#
class tripleo::profile::base::metrics::collectd (
  $step = Integer(hiera('step')),

  $enable_file_logging = false,
  $collectd_server = undef,
  $collectd_port = undef,
  $collectd_username = undef,
  $collectd_password = undef,
  $collectd_securitylevel = undef,
  $gnocchi_auth_mode = 'basic',
  $gnocchi_protocol = 'http',
  $gnocchi_server = undef,
  $gnocchi_port = 8041,
  $gnocchi_user = undef,
  $gnocchi_keystone_auth_url = undef,
  $gnocchi_keystone_user_name = undef,
  $gnocchi_keystone_user_id = undef,
  $gnocchi_keystone_password = undef,
  $gnocchi_keystone_project_id = undef,
  $gnocchi_keystone_project_name = undef,
  $gnocchi_keystone_user_domain_id = undef,
  $gnocchi_keystone_user_domain_name = undef,
  $gnocchi_keystone_project_domain_id = undef,
  $gnocchi_keystone_project_domain_name = undef,
  $gnocchi_keystone_region_name = undef,
  $gnocchi_keystone_interface = undef,
  $gnocchi_keystone_endpoint = undef,
  $gnocchi_resource_type = 'collectd',
  $gnocchi_batch_size = 10,
  $service_names = hiera('service_names', []),
  $collectd_manage_repo = false
) {
  if $step >= 3 {
    class {'::collectd':
      manage_repo => $collectd_manage_repo
    }
    if $enable_file_logging {
      include ::collectd::plugin::logfile
    }

    if ! ($collectd_securitylevel in [undef, 'None', 'Sign', 'Encrypt']) {
      fail('collectd_securitylevel must be one of (None, Sign, Encrypt).')
    }

    # Load per-service plugin configuration
    ::tripleo::profile::base::metrics::collectd::collectd_service {
      $service_names: }

    # Because THT doesn't allow us to default values to undef, we need
    # to perform a number of transformations here to avoid passing a bunch of
    # empty strings to the collectd plugins.

    $_collectd_username = empty($collectd_username) ? {
      true    => undef,
      default => $collectd_username
    }

    $_collectd_password = empty($collectd_password) ? {
      true    => undef,
      default => $collectd_password
    }

    $_collectd_port = empty($collectd_port) ? {
      true    => undef,
      default => $collectd_port
    }

    $_collectd_securitylevel = empty($collectd_securitylevel) ? {
      true    => undef,
      default => $collectd_securitylevel
    }

    if ! empty($collectd_server) {
      ::collectd::plugin::network::server { $collectd_server:
        username      => $_collectd_username,
        password      => $_collectd_password,
        port          => $_collectd_port,
        securitylevel => $_collectd_securitylevel,
      }
    } elsif !empty($gnocchi_server) or !empty($gnocchi_keystone_auth_url) {
      if !empty($gnocchi_server) {
        $gci_server = $gnocchi_server
      } else {
        $gci_server = $gnocchi_keystone_auth_url
      }
      ::tripleo::profile::base::metrics::collectd::gnocchi { $gci_server:
        auth_mode                    => $gnocchi_auth_mode,
        protocol                     => $gnocchi_protocol,
        server                       => $gnocchi_server,
        port                         => $gnocchi_port,
        user                         => $gnocchi_user,
        keystone_auth_url            => $gnocchi_keystone_auth_url,
        keystone_user_name           => $gnocchi_keystone_user_name,
        keystone_user_id             => $gnocchi_keystone_user_id,
        keystone_password            => $gnocchi_keystone_password,
        keystone_project_id          => $gnocchi_keystone_project_id,
        keystone_project_name        => $gnocchi_keystone_project_name,
        keystone_user_domain_id      => $gnocchi_keystone_user_domain_id,
        keystone_user_domain_name    => $gnocchi_keystone_user_domain_name,
        keystone_project_domain_id   => $gnocchi_keystone_project_domain_id,
        keystone_project_domain_name => $gnocchi_keystone_project_domain_name,
        keystone_region_name         => $gnocchi_keystone_region_name,
        keystone_interface           => $gnocchi_keystone_interface,
        keystone_endpoint            => $gnocchi_keystone_endpoint,
        resource_type                => $gnocchi_resource_type,
        batch_size                   => $gnocchi_batch_size,
      }
    }
  }
}

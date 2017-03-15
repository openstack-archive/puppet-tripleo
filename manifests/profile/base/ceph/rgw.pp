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
# == Class: tripleo::profile::base::ceph::rgw
#
# Ceph RadosGW profile for tripleo
#
# === Parameters
#
# [*civetweb_bind_ip*]
#   IP address where to bind the RGW civetweb instance
#   (Optional) Defaults to 127.0.0.1
#
# [*civetweb_bind_port*]
#   PORT where to bind the RGW civetweb instance
#   (Optional) Defaults to 8080
#
# [*keystone_admin_token*]
#   The keystone admin token
#
# [*rgw_keystone_version*] The api version for keystone.
#   Possible values 'v2.0', 'v3'
#   Optional. Default is 'v2.0'
#
# [*keystone_url*]
#   The internal or admin url for keystone
#
# [*rgw_key*]
#   The cephx key for the RGW client service
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::ceph::rgw (
  $keystone_admin_token,
  $keystone_url,
  $rgw_key,
  $civetweb_bind_ip            = '127.0.0.1',
  $civetweb_bind_port          = '8080',
  $rgw_keystone_version        = 'v2.0',
  $step                        = hiera('step'),
) {

  include ::tripleo::profile::base::ceph

  if $step >= 3 {
    $rgw_name = hiera('ceph::profile::params::rgw_name', 'radosgw.gateway')
    $civetweb_bind_ip_real = normalize_ip_for_uri($civetweb_bind_ip)
    include ::ceph::params
    include ::ceph::profile::client
    ceph::rgw { $rgw_name:
      frontend_type => 'civetweb',
      rgw_frontends => "civetweb port=${civetweb_bind_ip_real}:${civetweb_bind_port}",
      user          => 'ceph',
    }
    ceph::key { "client.${rgw_name}":
      secret  => $rgw_key,
      cap_mon => 'allow *',
      cap_osd => 'allow *',
      inject  => true,
    }
  }

  if $step >= 4 {
    if $rgw_keystone_version == 'v2.0' {
      ceph::rgw::keystone { $rgw_name:
        rgw_keystone_accepted_roles => ['admin', '_member_', 'Member'],
        use_pki                     => false,
        rgw_keystone_admin_token    => $keystone_admin_token,
        rgw_keystone_url            => $keystone_url,
        user                        => 'ceph',
      }
    }
    else
    {
      ceph::rgw::keystone { $rgw_name:
        rgw_keystone_accepted_roles => ['admin', '_member_', 'Member'],
        use_pki                     => false,
        rgw_keystone_url            => $keystone_url,
        rgw_keystone_version        => $rgw_keystone_version,
        user                        => 'ceph',
      }
    }
  }
}

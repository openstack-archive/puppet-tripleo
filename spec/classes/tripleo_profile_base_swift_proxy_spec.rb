#
# Copyright (C) 2016 Red Hat Inc.
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

require 'spec_helper'

describe 'tripleo::profile::base::swift::proxy' do

  shared_examples_for 'tripleo::profile::base::swift::proxy' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    let :pre_condition do
      "class { 'swift':
         swift_hash_path_prefix => 'foo',
       }
       include memcached
       class { 'swift::proxy':
         proxy_local_net_ip => '127.0.0.1',
       }
       include swift::proxy::tempauth
      "
    end

    context 'with ipv4 memcache servers' do
      let(:params) { {
        :step             => 4,
        :memcache_servers => ['192.168.0.1', '192.168.0.2'],
      } }

      it 'configure swift proxy cache with ipv4 ips' do
        is_expected.to contain_class('swift::config')
        is_expected.to contain_class('swift::proxy')
        is_expected.to contain_class('swift::proxy::catch_errors')
        is_expected.to contain_class('swift::proxy::gatekeeper')
        is_expected.to contain_class('swift::proxy::healthcheck')
        is_expected.to contain_class('swift::proxy::proxy_logging')
        is_expected.to contain_class('swift::proxy::cache').with({
          :memcache_servers => ['192.168.0.1:11211', '192.168.0.2:11211']
        })
        is_expected.to contain_class('swift::proxy::listing_formats')
        is_expected.to contain_class('swift::proxy::ratelimit')
        is_expected.to contain_class('swift::proxy::bulk')
        is_expected.to contain_class('swift::proxy::tempurl')
        is_expected.to contain_class('swift::proxy::formpost')
        is_expected.to contain_class('swift::proxy::authtoken')
        is_expected.to contain_class('swift::proxy::s3api')
        is_expected.to contain_class('swift::proxy::s3token')
        is_expected.to contain_class('swift::proxy::keystone')
        is_expected.to contain_class('swift::proxy::staticweb')
        is_expected.to contain_class('swift::proxy::copy')
        is_expected.to contain_class('swift::proxy::container_quotas')
        is_expected.to contain_class('swift::proxy::account_quotas')
        is_expected.to contain_class('swift::proxy::slo')
        is_expected.to contain_class('swift::proxy::dlo')
        is_expected.to contain_class('swift::proxy::versioned_writes')
        is_expected.to contain_class('swift::proxy::ceilometer')
        is_expected.to contain_class('swift::proxy::kms_keymaster')
        is_expected.to contain_class('swift::proxy::encryption')
        is_expected.to contain_class('swift::keymaster')
        is_expected.to_not contain_class('swift::proxy::audit')
      end
    end

    context 'with ipv6 memcache servers' do
      let(:params) { {
          :step             => 4,
          :memcache_servers => ['::1', '::2'],
      } }

      it 'configure swift proxy cache with ipv6 ips' do
        is_expected.to contain_class('swift::proxy::cache').with({
          :memcache_servers => ['[::1]:11211', '[::2]:11211']
        })
      end
    end

    context 'with ipv4, ipv6 and fqdn memcache servers' do
      let(:params) { {
          :step             => 4,
          :memcache_servers => ['192.168.0.1', '::2', 'myserver.com'],
      } }

      it 'configure swift proxy cache with ips and fqdn' do
        is_expected.to contain_class('swift::proxy::cache').with({
          :memcache_servers => ['192.168.0.1:11211', '[::2]:11211', 'myserver.com:11211']
        })
      end
    end

    context 'with ceilometer middleare disabled' do
      let(:params) { {
        :step               => 4,
        :memcache_servers   => ['192.168.0.1', '192.168.0.2'],
        :ceilometer_enabled => false
      } }

      it 'does not configure the ceilometer middleware' do
        is_expected.to_not contain_class('swift::proxy::ceilometer')
      end
    end

    context 'with audit middleare enabled' do
      let(:params) { {
        :step             => 4,
        :memcache_servers => ['192.168.0.1', '192.168.0.2'],
        :audit_enabled    => true
      } }

      it 'configures audit middleware' do
        is_expected.to contain_class('swift::proxy::audit')
      end
    end

  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(OSDefaults.get_facts({ :hostname => 'node.example.com' }))
      end

      it_behaves_like 'tripleo::profile::base::swift::proxy'
    end
  end
end

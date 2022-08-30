#
# Copyright (C) 2016 Red Hat, Inc.
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

require 'spec_helper'

describe 'tripleo::profile::base::ceilometer' do
  shared_examples_for 'tripleo::profile::base::ceilometer' do
    context 'with step less than 3' do
      let(:params) { { :step => 1 } }
      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::ceilometer')
        is_expected.to_not contain_class('ceilometer')
        is_expected.to_not contain_class('ceilometer::cache')
        is_expected.to_not contain_class('ceilometer::config')
        is_expected.to_not contain_class('ceilometer::db')
      end
    end

    context 'with step 3' do
      let(:params) { {
        :step                 => 3,
        :oslomsg_rpc_hosts    => [ '127.0.0.1' ],
        :oslomsg_rpc_username => 'ceilometer',
        :oslomsg_rpc_password => 'foo',
      } }

      it 'should trigger complete configuration' do
        is_expected.to contain_class('ceilometer').with(
          :default_transport_url => 'rabbit://ceilometer:foo@127.0.0.1:5672/?ssl=0'
        )
        is_expected.to contain_class('ceilometer::cache').with(
          :memcache_servers => ['controller-1:11211']
        )
        is_expected.to contain_class('ceilometer::config')
        is_expected.to contain_class('ceilometer::db')
      end
    end

    context 'with step 3 and memcache ipv6' do
      let(:params) { {
        :step            => 3,
        :memcached_hosts => '::1',
      } }

      it 'should format the memcache_server parameter' do
        is_expected.to contain_class('ceilometer::cache').with(
          :memcache_servers => ['[::1]:11211']
        )
      end
    end

    context 'with step 3 and memcache ipv6 and memcached backend' do
      let(:params) { {
        :step            => 3,
        :memcached_hosts => '::1',
        :cache_backend   => 'dogpile.cache.memcached',
      } }

      it 'should format the memcache_server parameter' do
        is_expected.to contain_class('ceilometer::cache').with(
          :memcache_servers => ['inet6:[::1]:11211']
        )
      end
    end

    context 'with step 3 and the ipv6 parameter' do
      let(:params) { {
        :step            => 3,
        :memcached_hosts => 'node.example.com',
        :memcached_ipv6  => true,
      } }

      it 'should format the memcache_server parameter' do
        is_expected.to contain_class('ceilometer::cache').with(
          :memcache_servers => ['node.example.com:11211']
        )
      end
    end

    context 'with step 3 and the ipv6 parameter and memcached backend' do
      let(:params) { {
        :step            => 3,
        :memcached_hosts => 'node.example.com',
        :memcached_ipv6  => true,
        :cache_backend   => 'dogpile.cache.memcached',
      } }

      it 'should format the memcache_server parameter' do
        is_expected.to contain_class('ceilometer::cache').with(
          :memcache_servers => ['inet6:[node.example.com]:11211']
        )
      end
    end
  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(OSDefaults.get_facts({ :hostname => 'node.example.com' }))
      end

      it_behaves_like 'tripleo::profile::base::ceilometer'
    end
  end
end

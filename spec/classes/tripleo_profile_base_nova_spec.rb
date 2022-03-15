#
# Copyright (C) 2017 Red Hat, Inc.
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

describe 'tripleo::profile::base::nova' do
  shared_examples_for 'tripleo::profile::base::nova' do

    context 'with step less than 3' do
      let(:params) { {
        :step => 1,
        :oslomsg_rpc_hosts => [ 'localhost' ],
        :oslomsg_rpc_password => 'foo'
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova')
        is_expected.to_not contain_class('nova')
        is_expected.to_not contain_class('nova::config')
        is_expected.to_not contain_class('nova::logging')
        is_expected.to_not contain_class('nova::cache')
        is_expected.to_not contain_class('nova::cinder')
        is_expected.to_not contain_class('nova::glance')
        is_expected.to_not contain_class('nova::placement')
        is_expected.to_not contain_class('nova::keystone::service_user')
      }
    end

    context 'with step 3 on bootstrap node' do
      let(:params) { {
        :step => 3,
        :bootstrap_node => 'node.example.com',
        :oslomsg_rpc_hosts => [ 'localhost' ],
        :oslomsg_rpc_username => 'nova',
        :oslomsg_rpc_password => 'foo',
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova')
        is_expected.to contain_class('nova').with(
          :default_transport_url => 'rabbit://nova:foo@localhost:5672/?ssl=0'
        )
        is_expected.to contain_class('nova::config')
        is_expected.to contain_class('nova::logging')
        is_expected.to contain_class('nova::cache').with(
          :memcache_servers => ['controller-1:11211']
        )
        is_expected.to contain_class('nova::cinder')
        is_expected.to contain_class('nova::glance')
        is_expected.to contain_class('nova::placement')
        is_expected.to contain_class('nova::keystone::service_user')
      }
    end

    context 'with step 3 not on bootstrap node' do
      let(:params) { {
        :step           => 3,
        :bootstrap_node => 'other.example.com',
        :oslomsg_rpc_hosts => [ 'localhost' ],
        :oslomsg_rpc_password => 'foo'
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova')
        is_expected.to_not contain_class('nova')
        is_expected.to_not contain_class('nova::config')
        is_expected.to_not contain_class('nova::logging')
        is_expected.to_not contain_class('nova::cache')
        is_expected.to_not contain_class('nova::cinder')
        is_expected.to_not contain_class('nova::glance')
        is_expected.to_not contain_class('nova::placement')
        is_expected.to_not contain_class('nova::keystone::service_user')
      }
    end

    context 'with step 4' do
      let(:params) { {
        :step           => 4,
        :bootstrap_node => 'other.example.com',
        :oslomsg_rpc_hosts => [ 'localhost' ],
        :oslomsg_rpc_password => 'foo',
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova')
        is_expected.to contain_class('nova').with(
          :default_transport_url => /.+/,
          :notification_transport_url => /.+/,
          :nova_public_key => nil,
          :nova_private_key => nil,
        )
        is_expected.to contain_class('nova::config')
        is_expected.to contain_class('nova::logging')
        is_expected.to contain_class('nova::cache')
        is_expected.to contain_class('nova::cinder')
        is_expected.to contain_class('nova::glance')
        is_expected.to contain_class('nova::placement')
        is_expected.to contain_class('nova::keystone::service_user')
        is_expected.to_not contain_class('nova::migration::libvirt')
        is_expected.to_not contain_file('/etc/nova/migration/authorized_keys')
        is_expected.to_not contain_file('/etc/nova/migration/identity')
      }
    end

    context 'with step 4 and memcache ipv6' do
      let(:params) { {
        :step            => 4,
        :memcached_hosts => '::1',
      } }

      it 'should format the memcache_server parameter' do
        is_expected.to contain_class('nova::cache').with(
          :memcache_servers => ['[::1]:11211']
        )
      end
    end

    context 'with step 4, memcache ipv6 and memcached backend' do
      let(:params) { {
        :step            => 4,
        :memcached_hosts => '::1',
        :cache_backend   => 'dogpile.cache.memcached',
      } }

      it 'should format the memcache_server parameter' do
        is_expected.to contain_class('nova::cache').with(
          :memcache_servers => ['inet6:[::1]:11211']
        )
      end
    end

    context 'with step 4 and the ipv6 parameter' do
      let(:params) { {
        :step            => 4,
        :memcached_hosts => 'node.example.com',
        :memcached_ipv6  => true,
      } }

      it 'should format the memcache_server parameter' do
        is_expected.to contain_class('nova::cache').with(
          :memcache_servers => ['node.example.com:11211']
        )
      end
    end

    context 'with step 4, the ipv6 parameter and memcached backend' do
      let(:params) { {
        :step            => 4,
        :memcached_hosts => 'node.example.com',
        :memcached_ipv6  => true,
        :cache_backend   => 'dogpile.cache.memcached',
      } }

      it 'should format the memcache_server parameter' do
        is_expected.to contain_class('nova::cache').with(
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

      it_behaves_like 'tripleo::profile::base::nova'
    end
  end
end

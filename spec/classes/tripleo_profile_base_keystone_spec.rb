#
# Copyright (C) 2019 Red Hat, Inc.
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

describe 'tripleo::profile::base::keystone' do

  let :params do
    {
      :step                    => 5,
      :bootstrap_node          => 'node.example.com',
      :oslomsg_rpc_hosts       => [ '192.168.0.1' ],
      :oslomsg_rpc_username    => 'keystone1',
      :oslomsg_rpc_password    => 'foo',
      :oslomsg_rpc_port        => '1234',
      :oslomsg_notify_hosts    => [ '192.168.0.2' ],
      :oslomsg_notify_username => 'keystone2',
      :oslomsg_notify_password => 'baa',
      :oslomsg_notify_port     => '5678',
      :memcached_ips           => [ '192.168.0.3', '192.168.0.4', '192.168.0.5' ],
    }
  end

  shared_examples_for 'tripleo::profile::base::keystone' do
    context 'with step less than 3' do
      before do
        params.merge!({ :step => 1 })
      end

      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::keystone')
        is_expected.to_not contain_class('keystone')
        is_expected.to_not contain_class('keystone::config')
        is_expected.to_not contain_class('keystone::logging')
        is_expected.to_not contain_class('tripleo::profile::base::apache')
        is_expected.to_not contain_class('keystone::wsgi::apache')
        is_expected.to_not contain_class('keystone::cors')
        is_expected.to_not contain_class('keystone::security_compliance')
        is_expected.to_not contain_class('keystone::ldap_backend')
        is_expected.to_not contain_class('keystone::federation::openidc')
        is_expected.to_not contain_class('keystone::cron::token_flush')
        is_expected.to_not contain_class('keystone::cron::trust_flush')
      end
    end

    context 'with step 3 on bootstrap node' do
      before do
        params.merge!({ :step => 3 })
      end

      it 'should trigger complete configuration' do
        is_expected.to contain_class('keystone').with(
          :default_transport_url => 'rabbit://keystone1:foo@192.168.0.1:1234/?ssl=0',
          :notification_transport_url => 'rabbit://keystone2:baa@192.168.0.2:5678/?ssl=0',
          :cache_memcache_servers => [ '192.168.0.3:11211', '192.168.0.4:11211', '192.168.0.5:11211' ],
        )
        is_expected.to contain_class('keystone::config')
        is_expected.to contain_class('keystone::logging')
        is_expected.to contain_class('tripleo::profile::base::apache')
        is_expected.to contain_class('keystone::wsgi::apache')
        is_expected.to contain_class('keystone::cors')
        is_expected.to contain_class('keystone::security_compliance')
        is_expected.to_not contain_class('keystone::ldap_backend')
        is_expected.to_not contain_class('keystone::federation::openidc')
        is_expected.to_not contain_class('keystone::cron::token_flush')
        is_expected.to_not contain_class('keystone::cron::trust_flush')
      end
    end

    context 'with step 3 not on bootstrap node' do
      before do
        params.merge!(
          { :step           => 3,
            :bootstrap_node => 'other.example.com'
          }
        )
      end

      it 'should not trigger any configuration' do
        is_expected.to contain_class('tripleo::profile::base::keystone')
        is_expected.to_not contain_class('keystone')
        is_expected.to_not contain_class('keystone::config')
        is_expected.to_not contain_class('keystone::logging')
        is_expected.to_not contain_class('tripleo::profile::base::apache')
        is_expected.to_not contain_class('keystone::wsgi::apache')
        is_expected.to_not contain_class('keystone::cors')
        is_expected.to_not contain_class('keystone::security_compliance')
        is_expected.to_not contain_class('keystone::ldap_backend')
        is_expected.to_not contain_class('keystone::federation::openidc')
        is_expected.to_not contain_class('keystone::cron::token_flush')
        is_expected.to_not contain_class('keystone::cron::trust_flush')
      end
    end

    context 'with step 4 on bootstrap node' do
      before do
        params.merge!({ :step => 4 })
      end

      it 'should trigger keystone configuration' do
        is_expected.to contain_class('keystone').with(
          :default_transport_url => 'rabbit://keystone1:foo@192.168.0.1:1234/?ssl=0',
          :notification_transport_url => 'rabbit://keystone2:baa@192.168.0.2:5678/?ssl=0',
          :cache_memcache_servers => [ '192.168.0.3:11211', '192.168.0.4:11211', '192.168.0.5:11211' ],
        )
        is_expected.to contain_class('keystone::config')
        is_expected.to contain_class('keystone::logging')
        is_expected.to contain_class('tripleo::profile::base::apache')
        is_expected.to contain_class('keystone::wsgi::apache')
        is_expected.to contain_class('keystone::cors')
        is_expected.to contain_class('keystone::security_compliance')
        is_expected.to_not contain_class('keystone::ldap_backend')
        is_expected.to_not contain_class('keystone::federation::openidc')
        is_expected.to_not contain_class('keystone::cron::token_flush')
        is_expected.to_not contain_class('keystone::cron::trust_flush')
      end
    end

    context 'with step 4 on other node' do
      before do
        params.merge!(
          { :step           => 4,
            :bootstrap_node => 'other.example.com'
          }
        )
      end

      it 'should trigger keystone configuration' do
        is_expected.to contain_class('keystone').with(
          :default_transport_url => 'rabbit://keystone1:foo@192.168.0.1:1234/?ssl=0',
          :notification_transport_url => 'rabbit://keystone2:baa@192.168.0.2:5678/?ssl=0',
          :cache_memcache_servers => [ '192.168.0.3:11211', '192.168.0.4:11211', '192.168.0.5:11211' ],
        )
        is_expected.to contain_class('keystone::config')
        is_expected.to contain_class('keystone::logging')
        is_expected.to contain_class('tripleo::profile::base::apache')
        is_expected.to contain_class('keystone::wsgi::apache')
        is_expected.to contain_class('keystone::cors')
        is_expected.to contain_class('keystone::security_compliance')
        is_expected.to_not contain_class('keystone::ldap_backend')
        is_expected.to_not contain_class('keystone::federation::openidc')
        is_expected.to_not contain_class('keystone::cron::token_flush')
        is_expected.to_not contain_class('keystone::cron::trust_flush')
      end
    end

    context 'with step less than 4 and db_purge enabled' do
      before do
        params.merge!(
          { :step            => 3,
            :bootstrap_node  => 'other.example.com',
            :manage_db_purge => true
          }
        )
      end

      it 'should not trigger purge configuration' do
        is_expected.to_not contain_class('keystone::cron::token_flush')
        is_expected.to_not contain_class('keystone::cron::trust_flush')
      end
    end

    context 'with step 4 and db_purge enabled' do
      before do
        params.merge!(
          { :step            => 4,
            :bootstrap_node  => 'other.example.com',
            :manage_db_purge => true
          }
        )
      end

      it 'should trigger purge configuration' do
        is_expected.to contain_class('keystone::cron::token_flush')
        is_expected.to contain_class('keystone::cron::trust_flush')
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::keystone'
    end
  end
end

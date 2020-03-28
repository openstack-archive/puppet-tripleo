#
# Copyright (C) 2020 Red Hat, Inc.
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

describe 'tripleo::profile::base::heat' do
  shared_examples_for 'tripleo::profile::base::heat' do

    let(:pre_condition) do
      <<-eos
      class { 'tripleo::profile::base::heat::authtoken':
        step => #{params[:step]},
      }
eos
    end

    context 'with step less than 3' do
      let(:params) { { :step => 1 } }
      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::heat')
        is_expected.to contain_class('tripleo::profile::base::heat::authtoken')
        is_expected.to_not contain_class('heat::keystone::domain')
        is_expected.to_not contain_class('heat')
        is_expected.to_not contain_class('heat::config')
        is_expected.to_not contain_class('heat::cors')
        is_expected.to_not contain_class('heat::logging')
        is_expected.to_not contain_class('heat::cache')
        is_expected.to_not contain_class('heat::cron::purge_deleted')
      end
    end

    context 'with step 3' do
      let(:params) { {
        :step                    => 3,
        :oslomsg_rpc_hosts       => [ '192.168.0.1' ],
        :oslomsg_rpc_username    => 'heat1',
        :oslomsg_rpc_password    => 'foo',
        :oslomsg_rpc_port        => '1234',
        :oslomsg_notify_hosts    => [ '192.168.0.2' ],
        :oslomsg_notify_username => 'heat2',
        :oslomsg_notify_password => 'baa',
        :oslomsg_notify_port     => '5678',
        :memcached_ips           => '127.0.0.1',
      } }

      it 'should trigger complete configuration without db_purge' do
        is_expected.to contain_class('tripleo::profile::base::heat')
        is_expected.to contain_class('tripleo::profile::base::heat::authtoken')
        is_expected.to contain_class('heat::keystone::domain').with(
          :manage_domain => false,
          :manage_user   => false,
          :manage_role   => false
        )
        is_expected.to contain_class('heat').with(
          :default_transport_url      => 'rabbit://heat1:foo@192.168.0.1:1234/?ssl=0',
          :notification_transport_url => 'rabbit://heat2:baa@192.168.0.2:5678/?ssl=0'
        )
        is_expected.to contain_class('heat::config')
        is_expected.to contain_class('heat::cors')
        is_expected.to contain_class('heat::logging')
        is_expected.to contain_class('heat::cache').with(
          :memcache_servers => ['127.0.0.1:11211']
        )
        is_expected.to_not contain_class('heat::cron::purge_deleted')
      end
    end

    context 'with step 5' do
      let(:params) { {
        :step                    => 5,
        :oslomsg_rpc_hosts       => [ '192.168.0.1' ],
        :oslomsg_rpc_username    => 'heat1',
        :oslomsg_rpc_password    => 'foo',
        :oslomsg_rpc_port        => '1234',
        :oslomsg_notify_hosts    => [ '192.168.0.2' ],
        :oslomsg_notify_username => 'heat2',
        :oslomsg_notify_password => 'baa',
        :oslomsg_notify_port     => '5678',
        :memcached_ips           => '127.0.0.1',
      } }

      it 'should trigger complete configuration' do
        is_expected.to contain_class('tripleo::profile::base::heat')
        is_expected.to contain_class('tripleo::profile::base::heat::authtoken')
        is_expected.to contain_class('heat::keystone::domain').with(
          :manage_domain => false,
          :manage_user   => false,
          :manage_role   => false
        )
        is_expected.to contain_class('heat').with(
          :default_transport_url      => 'rabbit://heat1:foo@192.168.0.1:1234/?ssl=0',
          :notification_transport_url => 'rabbit://heat2:baa@192.168.0.2:5678/?ssl=0'
        )
        is_expected.to contain_class('heat::config')
        is_expected.to contain_class('heat::cors')
        is_expected.to contain_class('heat::logging')
        is_expected.to contain_class('heat::cache')
        is_expected.to contain_class('heat::cache').with(
          :memcache_servers => ['127.0.0.1:11211']
        )
        is_expected.to contain_class('heat::cron::purge_deleted')
      end
    end

    context 'with step 5 without db_purge' do
      let(:params) { {
        :step                    => 3,
        :bootstrap_node          => 'node.example.com',
        :oslomsg_rpc_hosts       => [ '192.168.0.1' ],
        :oslomsg_rpc_username    => 'heat1',
        :oslomsg_rpc_password    => 'foo',
        :oslomsg_rpc_port        => '1234',
        :oslomsg_notify_hosts    => [ '192.168.0.2' ],
        :oslomsg_notify_username => 'heat2',
        :oslomsg_notify_password => 'baa',
        :oslomsg_notify_port     => '5678',
        :manage_db_purge         => false,
        :memcached_ips           => '::1',
      } }

      it 'should trigger complete configuration without db_purge' do
        is_expected.to contain_class('tripleo::profile::base::heat')
        is_expected.to contain_class('tripleo::profile::base::heat::authtoken')
        is_expected.to contain_class('heat::keystone::domain').with(
          :manage_domain => false,
          :manage_user   => false,
          :manage_role   => false
        )
        is_expected.to contain_class('heat').with(
          :default_transport_url      => 'rabbit://heat1:foo@192.168.0.1:1234/?ssl=0',
          :notification_transport_url => 'rabbit://heat2:baa@192.168.0.2:5678/?ssl=0'
        )
        is_expected.to contain_class('heat::config')
        is_expected.to contain_class('heat::cors')
        is_expected.to contain_class('heat::logging')
        is_expected.to contain_class('heat::cache').with(
          :memcache_servers => ['[::1]:11211']
        )
        is_expected.to_not contain_class('heat::cron::purge_deleted')
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::heat'
    end
  end
end

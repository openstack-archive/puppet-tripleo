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

describe 'tripleo::profile::base::cinder' do
  shared_examples_for 'tripleo::profile::base::cinder' do
    context 'with step less than 3' do
      let(:params) { { :step => 1 } }
      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::cinder')
        is_expected.to_not contain_class('cinder')
        is_expected.to_not contain_class('cinder::config')
        is_expected.to_not contain_class('cinder::glance')
        is_expected.to_not contain_class('cinder::nova')
        is_expected.to_not contain_class('cinder::logging')
        is_expected.to_not contain_class('cinder::keystone::service_user')
        is_expected.to_not contain_class('cinder::key_manager')
        is_expected.to_not contain_class('cinder::key_manager::barbican')
        is_expected.to_not contain_class('cinder:::cron::db_purge')
      end
    end

    context 'with step 3 on bootstrap node' do
      let(:params) { {
        :step                    => 3,
        :bootstrap_node          => 'node.example.com',
        :oslomsg_rpc_hosts       => [ '192.168.0.1' ],
        :oslomsg_rpc_username    => 'cinder1',
        :oslomsg_rpc_password    => 'foo',
        :oslomsg_rpc_port        => '1234',
        :oslomsg_notify_hosts    => [ '192.168.0.2' ],
        :oslomsg_notify_username => 'cinder2',
        :oslomsg_notify_password => 'baa',
        :oslomsg_notify_port     => '5678'
      } }

      it 'should trigger complete configuration' do
        is_expected.to contain_class('cinder').with(
          :default_transport_url => 'rabbit://cinder1:foo@192.168.0.1:1234/?ssl=0',
          :notification_transport_url => 'rabbit://cinder2:baa@192.168.0.2:5678/?ssl=0'
        )
        is_expected.to contain_class('cinder::config')
        is_expected.to contain_class('cinder::glance')
        is_expected.to contain_class('cinder::nova')
        is_expected.to contain_class('cinder::logging')
        is_expected.to contain_class('cinder::keystone::service_user')
        is_expected.to contain_class('cinder::key_manager')
        is_expected.to contain_class('cinder::key_manager::barbican')
        is_expected.to_not contain_class('cinder::cron::db_purge')
      end
    end

    context 'with step 3 not on bootstrap node' do
      let(:params) { {
        :step => 3,
        :bootstrap_node => 'soemthingelse.example.com'
      } }

      it 'should not trigger any configuration' do
        is_expected.to_not contain_class('cinder')
        is_expected.to_not contain_class('cinder::config')
        is_expected.to_not contain_class('cinder::glance')
        is_expected.to_not contain_class('cinder::nova')
        is_expected.to_not contain_class('cinder::logging')
        is_expected.to_not contain_class('cinder::keystone::service_user')
        is_expected.to_not contain_class('cinder::key_manager')
        is_expected.to_not contain_class('cinder::key_manager::barbican')
        is_expected.to_not contain_class('cinder:::cron::db_purge')
      end
    end

    context 'with step 4 on other node' do
      let(:params) { {
        :step                    => 4,
        :bootstrap_node          => 'somethingelse.example.com',
        :oslomsg_rpc_hosts       => [ '192.168.0.1' ],
        :oslomsg_rpc_username    => 'cinder1',
        :oslomsg_rpc_password    => 'foo',
        :oslomsg_rpc_port        => '1234',
        :oslomsg_notify_hosts    => [ '192.168.0.2' ],
        :oslomsg_notify_username => 'cinder2',
        :oslomsg_notify_password => 'baa',
        :oslomsg_notify_port     => '5678'
      } }

      it 'should trigger cinder configuration without mysql grant' do
        is_expected.to contain_class('cinder').with(
          :default_transport_url => 'rabbit://cinder1:foo@192.168.0.1:1234/?ssl=0',
          :notification_transport_url => 'rabbit://cinder2:baa@192.168.0.2:5678/?ssl=0'
        )
        is_expected.to contain_class('cinder::config')
        is_expected.to contain_class('cinder::glance')
        is_expected.to contain_class('cinder::nova')
        is_expected.to contain_class('cinder::logging')
        is_expected.to contain_class('cinder::keystone::service_user')
        is_expected.to contain_class('cinder::key_manager')
        is_expected.to contain_class('cinder::key_manager::barbican')
        is_expected.to_not contain_class('cinder:::cron::db_purge')
      end
    end

    context 'with step 5' do
      let(:params) { {
        :step                 => 5,
        :bootstrap_node       => 'node.example.com',
        :oslomsg_rpc_hosts    => [ '127.0.0.1' ],
        :oslomsg_rpc_username => 'cinder',
        :oslomsg_rpc_password => 'foo',
      } }

      it 'should trigger complete configuration' do
        is_expected.to contain_class('cinder').with(
          :default_transport_url => 'rabbit://cinder:foo@127.0.0.1:5672/?ssl=0'
        )
        is_expected.to contain_class('cinder::config')
        is_expected.to contain_class('cinder::glance')
        is_expected.to contain_class('cinder::nova')
        is_expected.to contain_class('cinder::logging')
        is_expected.to contain_class('cinder::keystone::service_user')
        is_expected.to contain_class('cinder::key_manager')
        is_expected.to contain_class('cinder::key_manager::barbican')
        is_expected.to contain_class('cinder::cron::db_purge')
      end
    end

    context 'with step 5 without db_purge' do
      let(:params) { {
        :step                   => 5,
        :bootstrap_node         => 'node.example.com',
        :oslomsg_rpc_hosts      => [ '127.0.0.1' ],
        :oslomsg_rpc_username   => 'cinder',
        :oslomsg_rpc_password   => 'foo',
        :cinder_enable_db_purge => false
      } }

      it 'should trigger complete configuration' do
        is_expected.to contain_class('cinder').with(
          :default_transport_url => 'rabbit://cinder:foo@127.0.0.1:5672/?ssl=0'
        )
        is_expected.to contain_class('cinder::config')
        is_expected.to contain_class('cinder::glance')
        is_expected.to contain_class('cinder::nova')
        is_expected.to contain_class('cinder::logging')
        is_expected.to contain_class('cinder::keystone::service_user')
        is_expected.to contain_class('cinder::key_manager')
        is_expected.to contain_class('cinder::key_manager::barbican')
        is_expected.to_not contain_class('cinder::cron::db_purge')
      end
    end

  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::cinder'
    end
  end
end

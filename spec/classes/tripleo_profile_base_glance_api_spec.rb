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

describe 'tripleo::profile::base::glance::api' do
  shared_examples_for 'tripleo::profile::base::glance::api' do

    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'with step less than 3' do
      let(:params) { {
        :step => 1,
      } }

      it 'should not configure glance' do
        is_expected.to contain_class('tripleo::profile::base::glance::api')
        is_expected.to_not contain_class('glance')
        is_expected.to_not contain_class('glance::config')
        is_expected.to_not contain_class('glance::healthcheck')
        is_expected.to_not contain_class('glance::api::logging')
        is_expected.to_not contain_class('glance::api')
        is_expected.to_not contain_class('glance::key_manager')
        is_expected.to_not contain_class('glance::key_manager::barbican')
        is_expected.to_not contain_class('glance::notify::rabbitmq')
        is_expected.to_not contain_class('glance::cron::db_purge')
        is_expected.to_not contain_class('glance::cache::cleaner')
        is_expected.to_not contain_class('glance::cache::pruner')
      end
    end

    context 'with step 3 on bootstrap node' do
      let(:params) { {
        :step                    => 3,
        :bootstrap_node          => 'node.example.com',
        :oslomsg_rpc_hosts       => [ '192.168.0.1' ],
        :oslomsg_rpc_username    => 'glance1',
        :oslomsg_rpc_password    => 'foo',
        :oslomsg_rpc_port        => '1234',
        :oslomsg_notify_hosts    => [ '192.168.0.2' ],
        :oslomsg_notify_username => 'glance2',
        :oslomsg_notify_password => 'baa',
        :oslomsg_notify_port     => '5678',
      } }

      it 'should configure glance' do
        is_expected.to contain_class('tripleo::profile::base::glance::api')
        is_expected.to contain_class('glance')
        is_expected.to contain_class('glance::config')
        is_expected.to contain_class('glance::healthcheck')
        is_expected.to contain_class('glance::api::logging')
        is_expected.to contain_class('glance::api')
        is_expected.to contain_class('glance::key_manager')
        is_expected.to contain_class('glance::key_manager::barbican')
        is_expected.to contain_class('glance::notify::rabbitmq').with(
          :default_transport_url      => 'rabbit://glance1:foo@192.168.0.1:1234/?ssl=0',
          :notification_transport_url => 'rabbit://glance2:baa@192.168.0.2:5678/?ssl=0',
        )
        is_expected.to_not contain_class('glance::cron::db_purge')
        is_expected.to_not contain_class('glance::cache::cleaner')
        is_expected.to_not contain_class('glance::cache::pruner')
      end
    end

    context 'with step 3 not on bootstrap node' do
      let(:params) { {
        :step           => 3,
        :bootstrap_node => 'other.example.com',
      } }

      it 'should not configure glance' do
        is_expected.to contain_class('tripleo::profile::base::glance::api')
        is_expected.to_not contain_class('glance')
        is_expected.to_not contain_class('glance::config')
        is_expected.to_not contain_class('glance::healthcheck')
        is_expected.to_not contain_class('glance::api::logging')
        is_expected.to_not contain_class('glance::api')
        is_expected.to_not contain_class('glance::key_manager')
        is_expected.to_not contain_class('glance::key_manager::barbican')
        is_expected.to_not contain_class('glance::notify::rabbitmq')
        is_expected.to_not contain_class('glance::cron::db_purge')
        is_expected.to_not contain_class('glance::cache::cleaner')
        is_expected.to_not contain_class('glance::cache::pruner')
      end
    end

    context 'with step 4' do
      let(:params) { {
        :step                    => 4,
        :bootstrap_node          => 'node.example.com',
        :oslomsg_rpc_hosts       => [ '192.168.0.1' ],
        :oslomsg_rpc_username    => 'glance1',
        :oslomsg_rpc_password    => 'foo',
        :oslomsg_rpc_port        => '1234',
        :oslomsg_notify_hosts    => [ '192.168.0.2' ],
        :oslomsg_notify_username => 'glance2',
        :oslomsg_notify_password => 'baa',
        :oslomsg_notify_port     => '5678',
      } }

      it 'should configure glance' do
        is_expected.to contain_class('tripleo::profile::base::glance::api')
        is_expected.to contain_class('glance')
        is_expected.to contain_class('glance::config')
        is_expected.to contain_class('glance::healthcheck')
        is_expected.to contain_class('glance::api::logging')
        is_expected.to contain_class('glance::api').with(
          :enabled_backends => ['default_backend:swift'],
          :default_backend  => 'default_backend',
        )
        is_expected.to contain_class('glance::key_manager')
        is_expected.to contain_class('glance::key_manager::barbican')
        is_expected.to_not contain_class('tripleo::profile::base::glance::backend::cinder')
        is_expected.to_not contain_class('tripleo::profile::base::glance::backend::file')
        is_expected.to_not contain_class('tripleo::profile::base::glance::backend::rbd')
        is_expected.to contain_class('tripleo::profile::base::glance::backend::swift').with(
          :backend_names => ['default_backend'],
        )
        is_expected.to contain_class('glance::notify::rabbitmq').with(
          :default_transport_url      => 'rabbit://glance1:foo@192.168.0.1:1234/?ssl=0',
          :notification_transport_url => 'rabbit://glance2:baa@192.168.0.2:5678/?ssl=0',
        )
        is_expected.to_not contain_class('glance::cron::db_purge')
        is_expected.to_not contain_class('glance::cache::cleaner')
        is_expected.to_not contain_class('glance::cache::pruner')
      end

      context 'with multistore_config' do
        before :each do
          params.merge!({
            :glance_backend    => 'cinder',
            :glance_backend_id => 'my_cinder',
            :multistore_config => {
              'my_file' => {
                'GlanceBackend' => 'file',
              },
              'rbd1' => {
                'GlanceBackend'      => 'rbd',
                'CephClusterName'    => 'ceph1',
                'CephClientUserName' => 'user1',
                'GlanceRbdPoolName'  => 'pool1',
              },
              'rbd2' => {
                'GlanceBackend'      => 'rbd',
                'CephClusterName'    => 'ceph2',
                'CephClientUserName' => 'user2',
                'GlanceRbdPoolName'  => 'pool2',
              },
              'my_swift' => {
                'GlanceBackend' => 'swift',
              },
            },
          })
        end
        it 'should configure multiple backends' do
          is_expected.to contain_class('glance::api').with(
            :enabled_backends => [
              'my_cinder:cinder',
              'my_file:file',
              'rbd1:rbd',
              'rbd2:rbd',
              'my_swift:swift'
            ],
            :default_backend  => 'my_cinder',
          )
          is_expected.to contain_class('tripleo::profile::base::glance::backend::cinder').with(
            :backend_names => ['my_cinder'],
          )
          is_expected.to contain_class('tripleo::profile::base::glance::backend::file').with(
            :backend_names => ['my_file'],
          )
          is_expected.to contain_class('tripleo::profile::base::glance::backend::rbd').with(
            :backend_names => ['rbd1', 'rbd2'],
          )
          is_expected.to contain_class('tripleo::profile::base::glance::backend::swift').with(
            :backend_names => ['my_swift'],
          )
        end
      end
      context 'with invalid multistore_config' do
        before :each do
          params.merge!({
            :multistore_config  => {
              'rbd' => {
                'GlanceBackend_typo' => 'rbd',
              },
            },
          })
        end
        it_raises 'a Puppet::Error', / does not specify a glance_backend./
      end
    end

    context 'with step 5' do
      let(:params) { {
        :step           => 5,
        :bootstrap_node => 'node.example.com',
      } }

      it 'should configure db_purge' do
        is_expected.to contain_class('glance::cron::db_purge')
      end

      it 'should not configure cache' do
        is_expected.to_not contain_class('glance::cache::cleaner')
        is_expected.to_not contain_class('glance::cache::pruner')
      end
    end

    context 'with step 5 without db_purge' do
      let(:params) { {
        :step                   => 5,
        :bootstrap_node         => 'node.example.com',
        :glance_enable_db_purge => false,
      } }

      it 'should configure db_purge' do
        is_expected.to_not contain_class('glance::cron::db_purge')
      end
    end

    context 'with step 5 with cache' do
      let(:params) { {
        :step                => 5,
        :bootstrap_node      => 'node.example.com',
        :glance_enable_cache => true,
      } }

      it 'should configure cache' do
        is_expected.to contain_class('glance::cache::cleaner')
        is_expected.to contain_class('glance::cache::pruner')
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::glance::api'
    end
  end
end

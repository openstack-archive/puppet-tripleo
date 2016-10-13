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

describe 'tripleo::profile::base::ceilometer::collector' do
  shared_examples_for 'tripleo::profile::base::ceilometer::collector' do
    let(:pre_condition) do
      "class { '::tripleo::profile::base::ceilometer': step => #{params[:step]}, rabbit_hosts => ['127.0.0.1'] }"
    end

    context 'with step 3 on bootstrap node with mongodb' do
      let(:params) { {
        :step           => 3,
        :bootstrap_node => 'node.example.com',
        :mongodb_node_ips => ['127.0.0.1',],
        :mongodb_replset  => 'replicaset'
      } }

      it 'should trigger complete configuration' do
        is_expected.to contain_class('tripleo::profile::base::ceilometer::collector')
        is_expected.to contain_class('ceilometer::db::sync')
        is_expected.to contain_class('ceilometer::db').with(
          :database_connection => 'mongodb://127.0.0.1:27017/ceilometer?replicaSet=replicaset'
        )
      end
    end

    context 'with step 3 on bootstrap node with mongodb with ipv6' do
      let(:params) { {
        :step             => 3,
        :bootstrap_node   => 'node.example.com',
        :mongodb_ipv6     => true,
        :mongodb_node_ips => ['::1','fe80::ca5b:76ff:fe4b:be3b'],
        :mongodb_replset  => 'replicaset'
      } }

      it 'should trigger complete configuration' do
        is_expected.to contain_class('tripleo::profile::base::ceilometer::collector')
        is_expected.to contain_class('ceilometer::db::sync')
        is_expected.to contain_class('ceilometer::db').with(
          :sync_db             => true,
          :database_connection => 'mongodb://[::1]:27017,[fe80::ca5b:76ff:fe4b:be3b]:27017/ceilometer?replicaSet=replicaset'
        )
      end
    end

    context 'with step 3 on bootstrap node without mongodb' do
      let(:params) { {
        :step               => 3,
        :bootstrap_node     => 'node.example.com',
        :ceilometer_backend => 'somethingelse',
        :mongodb_node_ips   => ['127.0.0.1',],
        :mongodb_replset    => 'replicaset'
      } }

      it 'should trigger complete configuration' do
        is_expected.to contain_class('tripleo::profile::base::ceilometer::collector')
        is_expected.to contain_class('ceilometer::db::sync')
        is_expected.to contain_class('ceilometer::db').without(
          :database_connection => 'mongodb://127.0.0.1:27017/ceilometer?replicaSet=replicaset'
        )
        is_expected.to contain_class('ceilometer::db').with(
          :sync_db => true
        )
      end
    end

    context 'with step 3 not on bootstrap node' do
      let(:params) { {
        :step => 3,
        :bootstrap_node => 'soemthingelse.example.com'
      } }

      it 'should not trigger any configuration' do
        is_expected.to contain_class('tripleo::profile::base::ceilometer::collector')
        is_expected.to_not contain_class('ceilometer::db')
      end
    end

    context 'with step 4 on bootstrap node' do
      let(:params) { {
        :step             => 4,
        :bootstrap_node   => 'node.example.com',
        :mongodb_node_ips => ['127.0.0.1',],
        :mongodb_replset  => 'replicaset'
      } }

      it 'should trigger complete configuration' do
        is_expected.to contain_class('ceilometer::db::sync')
        is_expected.to contain_class('ceilometer::db').with(
          :sync_db             => true,
          :database_connection => 'mongodb://127.0.0.1:27017/ceilometer?replicaSet=replicaset'
        )
        is_expected.to contain_class('ceilometer::collector')
        is_expected.to contain_class('ceilometer::dispatcher::gnocchi')
      end
    end

    context 'with step 4 not on bootstrap node' do
      let(:params) { {
        :step             => 4,
        :bootstrap_node   => 'somethingelse.example.com',
        :mongodb_node_ips => ['127.0.0.1',],
        :mongodb_replset  => 'replicaset'
      } }

      it 'should trigger complete configuration' do
        is_expected.to_not contain_class('ceilometer::db::sync')
        is_expected.to contain_class('ceilometer::db').with(
          :sync_db             => false,
          :database_connection => 'mongodb://127.0.0.1:27017/ceilometer?replicaSet=replicaset'
        )
        is_expected.to contain_class('ceilometer::collector')
        is_expected.to contain_class('ceilometer::dispatcher::gnocchi')
      end
    end
  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::ceilometer::collector'
    end
  end
end

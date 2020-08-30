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

describe 'tripleo::profile::base::zaqar' do
  shared_examples_for 'tripleo::profile::base::zaqar' do
    let(:pre_condition) do
      <<-eos
      class { 'tripleo::profile::base::zaqar::authtoken':
        step => #{params[:step]},
      }
eos
    end

    context 'with step less than 3' do
      let(:params) { {
        :step => 1,
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::zaqar')
        is_expected.to contain_class('tripleo::profile::base::zaqar::authtoken')
        is_expected.to_not contain_class('tripleo::profile::base::apache')
        is_expected.to_not contain_class('zaqar')
        is_expected.to_not contain_class('zaqar::messaging::swift')
        is_expected.to_not contain_class('zaqar::messaging::redis')
        is_expected.to_not contain_class('zaqar::management::sqlalchemy')
        is_expected.to_not contain_class('zaqar::transport::websocket')
        is_expected.to_not contain_class('zaqar::transport::wsgi')
        is_expected.to_not contain_class('zaqar::config')
        is_expected.to_not contain_class('zaqar::logging')
        is_expected.to_not contain_class('zaqar::server')
        is_expected.to_not contain_class('zaqar::wsgi::apache')
        is_expected.to_not contain_zaqar__server_instance('1')
      }
    end

    context 'with step 3 on bootstrap node' do
      let(:params) { {
        :step                 => 3,
        :bootstrap_node       => 'node.example.com',
        :redis_vip            => '192.168.0.1',
        :zaqar_redis_password => 'zaqar',
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::zaqar')
        is_expected.to contain_class('tripleo::profile::base::zaqar::authtoken')
        is_expected.to contain_class('tripleo::profile::base::apache')
        is_expected.to contain_class('zaqar')
        is_expected.to_not contain_class('zaqar::messaging::swift')
        is_expected.to contain_class('zaqar::messaging::redis').with(
          :uri => 'redis://:zaqar@192.168.0.1:6379/',
        )
        is_expected.to contain_class('zaqar::management::sqlalchemy')
        is_expected.to contain_class('zaqar::transport::websocket')
        is_expected.to contain_class('zaqar::transport::wsgi')
        is_expected.to contain_class('zaqar::config')
        is_expected.to contain_class('zaqar::logging')
        is_expected.to contain_class('zaqar::server')
        is_expected.to contain_class('zaqar::wsgi::apache')
        is_expected.to contain_zaqar__server_instance('1').with(
          :transport => 'websocket'
        )
      }
    end

    context 'with step 3 not on bootstrap node' do
      let(:params) { {
        :step           => 3,
        :bootstrap_node => 'other.example.com',
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::zaqar')
        is_expected.to contain_class('tripleo::profile::base::zaqar::authtoken')
        is_expected.to_not contain_class('tripleo::profile::base::apache')
        is_expected.to_not contain_class('zaqar')
        is_expected.to_not contain_class('zaqar::messaging::swift')
        is_expected.to_not contain_class('zaqar::messaging::redis')
        is_expected.to_not contain_class('zaqar::management::sqlalchemy')
        is_expected.to_not contain_class('zaqar::transport::websocket')
        is_expected.to_not contain_class('zaqar::transport::wsgi')
        is_expected.to_not contain_class('zaqar::config')
        is_expected.to_not contain_class('zaqar::logging')
        is_expected.to_not contain_class('zaqar::server')
        is_expected.to_not contain_class('zaqar::wsgi::apache')
        is_expected.to_not contain_zaqar__server_instance('1')
      }
    end

    context 'with step 4 not on bootstrap node' do
      let(:params) { {
        :step                 => 4,
        :bootstrap_node       => 'node.example.com',
        :redis_vip            => '192.168.0.1',
        :zaqar_redis_password => 'zaqar',
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::zaqar')
        is_expected.to contain_class('tripleo::profile::base::zaqar::authtoken')
        is_expected.to contain_class('tripleo::profile::base::apache')
        is_expected.to contain_class('zaqar')
        is_expected.to_not contain_class('zaqar::messaging::swift')
        is_expected.to contain_class('zaqar::messaging::redis').with({
          :uri => 'redis://:zaqar@192.168.0.1:6379/',
        })
        is_expected.to contain_class('zaqar::management::sqlalchemy')
        is_expected.to contain_class('zaqar::transport::websocket')
        is_expected.to contain_class('zaqar::transport::wsgi')
        is_expected.to contain_class('zaqar::config')
        is_expected.to contain_class('zaqar::logging')
        is_expected.to contain_class('zaqar::server')
        is_expected.to contain_class('zaqar::wsgi::apache')
        is_expected.to contain_zaqar__server_instance('1').with(
          :transport => 'websocket'
        )
      }
    end

    context 'with step 4 and swift messaging store' do
      let(:params) { {
        :step            => 4,
        :bootstrap_node  => 'node.example.com',
        :messaging_store => 'swift',
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::zaqar')
        is_expected.to contain_class('tripleo::profile::base::zaqar::authtoken')
        is_expected.to contain_class('tripleo::profile::base::apache')
        is_expected.to contain_class('zaqar')
        is_expected.to contain_class('zaqar::messaging::swift')
        is_expected.to_not contain_class('zaqar::messaging::redis')
        is_expected.to contain_class('zaqar::management::sqlalchemy')
        is_expected.to contain_class('zaqar::transport::websocket')
        is_expected.to contain_class('zaqar::transport::wsgi')
        is_expected.to contain_class('zaqar::config')
        is_expected.to contain_class('zaqar::logging')
        is_expected.to contain_class('zaqar::server')
        is_expected.to contain_class('zaqar::wsgi::apache')
        is_expected.to contain_zaqar__server_instance('1').with(
          :transport => 'websocket'
        )
      }
    end
  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::zaqar'
    end
  end
end

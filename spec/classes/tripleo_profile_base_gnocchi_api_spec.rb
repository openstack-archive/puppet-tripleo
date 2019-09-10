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

describe 'tripleo::profile::base::gnocchi::api' do

  before :each do
    facts.merge!({ :step => params[:step] })
  end

  shared_examples_for 'tripleo::profile::base::gnocchi::api' do
    let(:pre_condition) do
      "
        class { '::tripleo::profile::base::gnocchi': step => #{params[:step]}, }
      "
    end

    context 'with step less than 3' do
      let(:params) { {
        :step => 2,
        :gnocchi_redis_password => 'gnocchi',
        :redis_vip => '127.0.0.1'
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::gnocchi::api')
        is_expected.to_not contain_class('gnocchi::api')
        is_expected.to_not contain_class('gnocchi::wsgi::apache')
      }
    end

    context 'with step 4 on bootstrap' do
      let(:params) { {
        :step => 4,
        :bootstrap_node => 'node.example.com',
        :gnocchi_redis_password => 'gnocchi',
        :redis_vip => '127.0.0.1'
      } }

      it {
        is_expected.to contain_class('gnocchi::db::sync')
        is_expected.to contain_class('gnocchi::api')
        is_expected.to contain_class('gnocchi::wsgi::apache')
      }
    end

    context 'with step 4' do
      let(:params) { {
        :step => 4,
        :gnocchi_redis_password => 'gnocchi',
        :redis_vip => '127.0.0.1'
      } }

      it {
        is_expected.to contain_class('gnocchi::api')
        is_expected.to contain_class('gnocchi::wsgi::apache')
        is_expected.to contain_class('gnocchi::storage').with(
          :coordination_url => 'redis://:gnocchi@127.0.0.1:6379/'
        )
        is_expected.to contain_class('gnocchi::storage::swift')
      }
    end

    context 'with step 4 with file backend' do
      let(:params) { {
        :step => 4,
        :gnocchi_backend => 'file',
        :gnocchi_redis_password => 'gnocchi',
        :redis_vip => '127.0.0.1',
        :incoming_storage_driver => 'redis',
      } }

      it {
        is_expected.to contain_class('gnocchi::api')
        is_expected.to contain_class('gnocchi::wsgi::apache')
        is_expected.to contain_class('gnocchi::storage').with(
          :coordination_url => 'redis://:gnocchi@127.0.0.1:6379/'
        )
        is_expected.to contain_class('gnocchi::storage::incoming::redis').with(
          :redis_url => 'redis://:gnocchi@127.0.0.1:6379/'
        )
        is_expected.to contain_class('gnocchi::storage::file')
      }
    end

    context 'with step 4 with ceph backend' do
      let(:params) { {
        :step => 4,
        :gnocchi_backend => 'rbd',
        :gnocchi_redis_password => 'gnocchi',
        :redis_vip => '127.0.0.1',
        :gnocchi_rbd_client_name => 'openstack',
        :incoming_storage_driver => 'redis',
      } }

      it {
        is_expected.to contain_class('gnocchi::api')
        is_expected.to contain_class('gnocchi::wsgi::apache')
        is_expected.to contain_class('gnocchi::storage').with(
          :coordination_url => 'redis://:gnocchi@127.0.0.1:6379/'
        )
        is_expected.to contain_class('gnocchi::storage::incoming::redis').with(
          :redis_url => 'redis://:gnocchi@127.0.0.1:6379/'
        )
        is_expected.to contain_class('gnocchi::storage::ceph')
        is_expected.to contain_exec('exec-setfacl-openstack-gnocchi')
        is_expected.to contain_exec('exec-setfacl-openstack-gnocchi-mask')
      }
    end

    context 'skip incoming storage in step 4' do
      let(:params) { {
        :step => 4,
        :gnocchi_backend => 'rbd',
        :gnocchi_redis_password => 'gnocchi',
        :redis_vip => '127.0.0.1',
        :incoming_storage_driver => '',
      } }

      it {
        is_expected.not_to contain_class('gnocchi::storage::incoming::redis')
      }
    end

    context 'with step 5 on bootstrap' do
      let(:params) { {
        :step => 5,
        :bootstrap_node => 'node.example.com',
        :gnocchi_redis_password => 'gnocchi',
        :redis_vip => '127.0.0.1'
      } }

      it {
        is_expected.to contain_class('gnocchi::api')
        is_expected.to contain_class('gnocchi::wsgi::apache')
      }
    end
  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::gnocchi::api'
    end
  end
end

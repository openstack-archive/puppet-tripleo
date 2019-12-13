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

describe 'tripleo::profile::base::neutron::server' do
  shared_examples_for 'tripleo::profile::base::neutron::server' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    let(:pre_condition) do
      <<-eos
      class { '::tripleo::profile::base::neutron':
        oslomsg_rpc_hosts    => [ 'localhost' ],
        oslomsg_rpc_username => 'neutron',
        oslomsg_rpc_password => 'foo'
      }
eos
    end

    context 'with step less than 3' do
      let(:params) { {
        :step           => 1,
        :bootstrap_node => 'node.example.com',
      } }
      it 'should od nothing' do
        is_expected.to contain_class('tripleo::profile::base::neutron::server')
        is_expected.to contain_class('tripleo::profile::base::neutron')
        is_expected.to contain_class('tripleo::profile::base::neutron::authtoken')
        is_expected.to_not contain_class('tripleo::profile::base::apache')
        is_expected.to_not contain_class('neutron::server::notifications')
        is_expected.to_not contain_class('neutron::server::placement')
        is_expected.to_not contain_class('neutron::server')
        is_expected.to_not contain_class('neutron::quota')
      end
    end

    context 'with step 3 on bootstrap node' do
      let(:params) { {
        :step           => 3,
        :bootstrap_node => 'node.example.com',
      } }
      it 'should trigger apache configuration' do
        is_expected.to contain_class('tripleo::profile::base::neutron::server')
        is_expected.to contain_class('tripleo::profile::base::neutron')
        is_expected.to contain_class('tripleo::profile::base::neutron::authtoken')
        is_expected.to contain_class('tripleo::profile::base::apache')
        is_expected.to_not contain_class('neutron::server::notifications')
        is_expected.to_not contain_class('neutron::server::placement')
        is_expected.to_not contain_class('neutron::server')
        is_expected.to_not contain_class('neutron::quota')
      end
    end

    context 'with step 3 not on bootstrap node' do
      let(:params) { {
        :step           => 3,
        :bootstrap_node => 'other.example.com',
      } }
      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::neutron::server')
        is_expected.to contain_class('tripleo::profile::base::neutron')
        is_expected.to contain_class('tripleo::profile::base::neutron::authtoken')
        is_expected.to_not contain_class('tripleo::profile::base::apache')
        is_expected.to_not contain_class('neutron::server::notifications')
        is_expected.to_not contain_class('neutron::server::placement')
        is_expected.to_not contain_class('neutron::server')
        is_expected.to_not contain_class('neutron::quota')
      end
    end

    context 'with step 4 on bootstrap node' do
      let(:params) { {
        :step           => 4,
        :bootstrap_node => 'node.example.com',
      } }
      it 'should trigger complete configuration' do
        is_expected.to contain_class('tripleo::profile::base::neutron::server')
        is_expected.to contain_class('tripleo::profile::base::neutron')
        is_expected.to contain_class('tripleo::profile::base::neutron::authtoken')
        is_expected.to contain_class('tripleo::profile::base::apache')
        is_expected.to contain_class('neutron::server::notifications')
        is_expected.to contain_class('neutron::server::placement')
        is_expected.to contain_class('neutron::server').with(
          :sync_db => true,
          :l3_ha   => false,
        )
        is_expected.to contain_class('neutron::quota')
      end
    end

    context 'with step 4 not on bootstrap node' do
      let(:params) { {
        :step           => 4,
        :bootstrap_node => 'other.example.com',
      } }
      it 'should trigger apache configuration' do
        is_expected.to contain_class('tripleo::profile::base::neutron::server')
        is_expected.to contain_class('tripleo::profile::base::neutron')
        is_expected.to contain_class('tripleo::profile::base::neutron::authtoken')
        is_expected.to contain_class('tripleo::profile::base::apache')
        is_expected.to_not contain_class('neutron::server::notifications')
        is_expected.to_not contain_class('neutron::server::placement')
        is_expected.to_not contain_class('neutron::server')
        is_expected.to_not contain_class('neutron::quota')
      end
    end

    context 'with step 5 not on bootstrap nodes' do
      let(:params) { {
        :step           => 5,
        :bootstrap_node => 'other.example.com',
      } }
      it 'should trigger complete configuration' do
        is_expected.to contain_class('tripleo::profile::base::neutron::server')
        is_expected.to contain_class('tripleo::profile::base::neutron')
        is_expected.to contain_class('tripleo::profile::base::neutron::authtoken')
        is_expected.to contain_class('tripleo::profile::base::apache')
        is_expected.to contain_class('neutron::server::notifications')
        is_expected.to contain_class('neutron::server::placement')
        is_expected.to contain_class('neutron::server').with(
          :sync_db => false,
          :l3_ha   => false,
        )
        is_expected.to contain_class('neutron::quota')
      end
    end

    context 'with multiple l3 nods' do
      let(:params) { {
        :step           => 5,
        :bootstrap_node => 'node.example.com',
        :l3_nodes       => ['netcont1.localdomain', 'netcont2.localdomain', 'netcont3.localdomain'],
      } }
      it 'should enable l3_ha' do
        is_expected.to contain_class('neutron::server').with(
          :l3_ha => true,
        )
      end
    end

    context 'with multiple l3 nods and dvr enabled' do
      let(:params) { {
        :step           => 5,
        :bootstrap_node => 'node.example.com',
        :l3_nodes       => ['netcont1.localdomain', 'netcont2.localdomain', 'netcont3.localdomain'],
        :dvr_enabled    => true
      } }
      it 'should disable l3_ha' do
        is_expected.to contain_class('neutron::server').with(
          :l3_ha   => false,
        )
      end
    end

    context 'with l3_ha_override passed' do
      let(:params) { {
        :step           => 5,
        :bootstrap_node => 'node.example.com',
        :l3_ha_override => 'true'
      } }
      it 'should enable l3_ha' do
        is_expected.to contain_class('neutron::server').with(
          :l3_ha => true,
        )
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::neutron::server'
    end
  end
end

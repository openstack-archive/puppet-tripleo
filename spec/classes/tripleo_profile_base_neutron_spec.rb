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

describe 'tripleo::profile::base::neutron' do
  shared_examples_for 'tripleo::profile::base::neutron' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'with step less than 3' do
      let(:params) { { :step => 1 } }
      it 'should od nothing' do
        is_expected.to contain_class('tripleo::profile::base::neutron')
        is_expected.to_not contain_class('neutron')
        is_expected.to_not contain_class('neutron::config')
        is_expected.to_not contain_class('neutron::logging')
      end
    end

    context 'with step 3' do
      let(:params) { {
        :step       => 3,
        :oslomsg_rpc_hosts       => [ '192.168.0.1' ],
        :oslomsg_rpc_username    => 'neutron1',
        :oslomsg_rpc_password    => 'foo',
        :oslomsg_rpc_port        => '1234',
        :oslomsg_notify_hosts    => [ '192.168.0.2' ],
        :oslomsg_notify_username => 'neutron2',
        :oslomsg_notify_password => 'baa',
        :oslomsg_notify_port     => '5678',
        :dhcp_agents_per_network => 2
      } }
      it 'should trigger complete configuration' do
        is_expected.to contain_class('tripleo::profile::base::neutron')
        is_expected.to contain_class('neutron').with(
          :default_transport_url      => 'rabbit://neutron1:foo@192.168.0.1:1234/?ssl=0',
          :notification_transport_url => 'rabbit://neutron2:baa@192.168.0.2:5678/?ssl=0',
          :dhcp_agents_per_network    => 2
        )
        is_expected.to contain_class('neutron::config')
        is_expected.to contain_class('neutron::logging')
      end
    end

    context 'when not dhcp agents per network is set' do
      let(:params) { {
        :step                    => 3,
        :oslomsg_rpc_password    => 'foo',
        :oslomsg_notify_password => 'baa',
        :dhcp_nodes              => ['netcont1.localdomain', 'netcont2.localdomain', 'netcont3.localdomain']
      } }
      it 'should equal the number of dhcp agents' do
        is_expected.to contain_class('neutron').with(
          :dhcp_agents_per_network    => 3
        )
      end
    end

    context 'when dhcp agents per network is greater than number of agents' do
      let(:params) { {
        :step                    => 3,
        :oslomsg_rpc_password    => 'foo',
        :oslomsg_notify_password => 'baa',
        :dhcp_nodes              => ['netcont1.localdomain', 'netcont2.localdomain'],
        :dhcp_agents_per_network => 5
      } }
      it 'should set value and complain about not enough agents' do
        is_expected.to contain_class('neutron').with(
          :dhcp_agents_per_network => 5
        )
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::neutron'
    end
  end
end

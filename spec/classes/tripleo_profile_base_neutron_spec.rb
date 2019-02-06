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
  let :params do
    { :step                    => 5,
      :oslomsg_notify_password => 'foobar',
      :oslomsg_rpc_password    => 'foobar'
    }
  end

  shared_examples_for 'tripleo::profile::base::neutron' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'when no dhcp agents per network set' do
      before do
        params.merge!({
          :dhcp_nodes => ['netcont1.localdomain', 'netcont2.localdomain', 'netcont3.localdomain']
        })
      end
      it 'should equal the number of dhcp agents' do
        is_expected.to contain_class('neutron').with(:dhcp_agents_per_network => 3)
      end
    end

    context 'when dhcp agents per network is set' do
      before do
        params.merge!({
          :dhcp_agents_per_network => 2
        })
      end
      it 'should set the value' do
        is_expected.to contain_class('neutron').with(:dhcp_agents_per_network => 2)
      end
    end

    context 'when dhcp agents per network is greater than number of agents' do
      before do
        params.merge!({
          :dhcp_nodes => ['netcont1.localdomain', 'netcont2.localdomain'],
          :dhcp_agents_per_network => 5
        })
      end
      it 'should set value and complain about not enough agents' do
        is_expected.to contain_class('neutron').with(:dhcp_agents_per_network => 5)
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

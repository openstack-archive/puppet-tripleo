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

describe 'tripleo::profile::base::neutron::opendaylight' do
  let :params do
    { :step                    => 1
    }
  end
  shared_examples_for 'tripleo::profile::base::neutron::opendaylight' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'with noha' do
      before do
        params.merge!({
          :odl_api_ips => ['192.0.2.5']
        })
      end
      it 'should install and configure opendaylight' do
        is_expected.to contain_class('opendaylight')
      end
    end

    context 'with empty OpenDaylight API IPs' do
      before do
        params.merge!({
          :odl_api_ips => []
        })
      end
      it 'should fail to install OpenDaylight' do
        is_expected.to compile.and_raise_error(/No IPs assigned to OpenDaylight Api Service/)
      end
    end

    context 'with 2 OpenDaylight API IPs' do
      before do
        params.merge!({
          :odl_api_ips => ['192.0.2.5', '192.0.2.6']
        })
      end
      it 'should fail to install OpenDaylight' do
        is_expected.to compile.and_raise_error(/2 node OpenDaylight deployments are unsupported.  Use 1 or greater than 2/)
      end
    end

    context 'with HA and 3 OpenDaylight API IPs' do
      before do
        params.merge!({
          :odl_api_ips => ['192.0.2.5', '192.0.2.6', '192.0.2.7']
        })
      end
      it 'should install and configure OpenDaylight in HA' do
        is_expected.to contain_class('opendaylight').with(
          :enable_ha     => true,
          :ha_node_ips   => params[:odl_api_ips]
        )
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::neutron::opendaylight'
    end
  end
end

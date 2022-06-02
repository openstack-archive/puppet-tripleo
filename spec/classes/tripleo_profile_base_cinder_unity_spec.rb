# Copyright (c) 2016-2017 Dell Inc, or its subsidiaries
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

describe 'tripleo::profile::base::cinder::volume::dellemc_unity' do
  shared_examples_for 'tripleo::profile::base::cinder::volume::dellemc_unity' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'with step less than 4' do
      let(:params) { { :step => 3 } }

      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::cinder::volume::dellemc_unity')
        is_expected.to contain_class('tripleo::profile::base::cinder::volume')
        is_expected.to contain_class('tripleo::profile::base::cinder')
        is_expected.to_not contain_cinder__backend__dellemc_unity('tripleo_dellemc_unity')
      end
    end

    context 'with step 4' do
      let(:params) { {
        :step => 4,
      } }

      it 'should trigger complete configuration' do
        # TODO(aschultz): check hiera parameters
        is_expected.to contain_cinder__backend__dellemc_unity('tripleo_dellemc_unity')
      end
      context 'with multiple backends' do
        let(:params) { {
          :backend_name => ['tripleo_dellemc_unity_1', 'tripleo_dellemc_unity_2'],
          :multi_config => { 'tripleo_dellemc_unity_2' => { 'CinderDellEMCUnityStorageProtocol' => 'FC' }},
          :step         => 4,
        } }
        it 'should configure each backend' do
          is_expected.to contain_cinder__backend__dellemc_unity('tripleo_dellemc_unity_1')
          is_expected.to contain_cinder_config('tripleo_dellemc_unity_1/volume_driver')
             .with_value('cinder.volume.drivers.dell_emc.unity.Driver')
          is_expected.to contain_cinder_config('tripleo_dellemc_unity_1/storage_protocol')
             .with_value('iSCSI')
          is_expected.to contain_cinder__backend__dellemc_unity('tripleo_dellemc_unity_2')
          is_expected.to contain_cinder_config('tripleo_dellemc_unity_2/storage_protocol')
             .with_value('FC')
        end
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(OSDefaults.get_facts({ :hostname => 'node.example.com' }))
      end

      it_behaves_like 'tripleo::profile::base::cinder::volume::dellemc_unity'
    end
  end
end

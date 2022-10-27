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

describe 'tripleo::profile::base::cinder::volume::ibm_svf' do
  shared_examples_for 'tripleo::profile::base::cinder::volume::ibm_svf' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'with step less than 4' do
      let(:params) { { :step => 3  } }

      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::cinder::volume::ibm_svf')
        is_expected.to contain_class('tripleo::profile::base::cinder::volume')
        is_expected.to contain_class('tripleo::profile::base::cinder')
        is_expected.to_not contain_cinder__backend__ibm_svf('tripleo_ibm_svf')
      end
    end

    context 'with step 4' do
      let(:params) { {
        :step => 4,
      } }

      it 'should trigger complete configuration' do
        is_expected.to contain_cinder__backend__ibm_svf('tripleo_ibm_svf')
      end

      context 'with multiple backends' do
        let(:params) { {
          :backend_name => ['tripleo_ibm_svf_1', 'tripleo_ibm_svf_2'],
          :multi_config => { 'tripleo_ibm_svf_1' => {
                              'CinderSvfAllowTenantQos' => 'true',
                             },
                             'tripleo_ibm_svf_2' => {
                              'CinderSvfConnectionProtocol' => 'FC',
                             },
                           },
          :step         => 4,
        } }
        it 'should configure each backend' do
          is_expected.to contain_cinder__backend__ibm_svf('tripleo_ibm_svf_1')
          is_expected.to contain_cinder_config('tripleo_ibm_svf_1/storwize_svc_allow_tenant_qos').with_value('true')
          is_expected.to contain_cinder_config('tripleo_ibm_svf_1/volume_driver').with_value('cinder.volume.drivers.ibm.storwize_svc.storwize_svc_iscsi.StorwizeSVCISCSIDriver')
          is_expected.to contain_cinder__backend__ibm_svf('tripleo_ibm_svf_2')
          is_expected.to contain_cinder_config('tripleo_ibm_svf_2/storwize_svc_allow_tenant_qos').with_value('<SERVICE DEFAULT>')
          is_expected.to contain_cinder_config('tripleo_ibm_svf_2/volume_driver').with_value('cinder.volume.drivers.ibm.storwize_svc.storwize_svc_fc.StorwizeSVCFCDriver')
        end
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(OSDefaults.get_facts({ :hostname => 'node.example.com' }))
      end

      it_behaves_like 'tripleo::profile::base::cinder::volume::ibm_svf'
    end
  end
end

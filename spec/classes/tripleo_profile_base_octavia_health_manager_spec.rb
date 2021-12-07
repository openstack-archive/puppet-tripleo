#
# Copyright (C) 2021 Red Hat, Inc.
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

describe 'tripleo::profile::base::octavia::health_manager' do

  let :params do
    { :step => 5  }
  end

  shared_examples_for 'tripleo::profile::base::octavia::health_manager' do

    before :each do
      facts.merge!({ :step => params[:step] })
    end

    let(:pre_condition) do
      <<-eos
      class { 'tripleo::profile::base::octavia' :
        step => #{params[:step]},
        oslomsg_rpc_username => 'bugs',
        oslomsg_rpc_password => 'rabbits_R_c00l',
        oslomsg_rpc_hosts    => ['hole.field.com']
      }
eos
    end

    context 'with step less than 5' do
      before do
        params.merge!({ :step => 4 })
      end

      it 'should not do anything' do
        is_expected.to_not contain_class('octavia::controller')
        is_expected.to_not contain_class('octavia::nova')
        is_expected.to_not contain_class('octavia::health_manager')
        is_expected.to_not contain_class('octavia::certificates')
        is_expected.to_not contain_class('octavia::neutron')
        is_expected.to_not contain_class('octavia::glance')
        is_expected.to_not contain_class('octavia::cinder')
        is_expected.to_not contain_class('octavia::task_flow')
      end
    end

    context 'with step 5' do
      before do
        params.merge!({ :step => 5 })
      end

      it 'should do the full configuration' do
        is_expected.to contain_class('octavia::controller')
        is_expected.to contain_class('octavia::nova')
        is_expected.to contain_class('octavia::health_manager')
        is_expected.to contain_class('octavia::certificates')
        is_expected.to contain_class('octavia::neutron')
        is_expected.to contain_class('octavia::glance')
        is_expected.to contain_class('octavia::cinder')
        is_expected.to contain_class('octavia::task_flow')
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end
      it_behaves_like 'tripleo::profile::base::octavia::health_manager'
    end
  end
end

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

describe 'tripleo::profile::base::neutron::dhcp' do

  shared_examples_for 'tripleo::profile::base::neutron::dhcp' do

    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'with defaults for all parameters' do
      let(:params) { { :step => 4 } }

      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::neutron::dhcp')
        is_expected.to contain_class('neutron::agents::dhcp')
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::neutron::dhcp'
    end
  end
end

#
# Copyright (C) 2015 Red Hat Inc.
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

require 'spec_helper'

describe 'tripleo::packages' do

  shared_examples_for 'tripleo::packages' do

    let :pre_condition do
      "service{'nova-compute': ensure => 'running'}"
    end

    let :params do
      {
        :enable_upgrade => true
      }
    end

    it 'should contain upgrade exec' do
        is_expected.to contain_exec('package-upgrade').with(:command => 'yum -y update')
    end

  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      it_behaves_like 'tripleo::packages'
    end
  end

end

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

  shared_examples_for 'Red Hat distributions' do

    let :pre_condition do
      "service{'nova-compute': ensure => 'running'}"
    end

    let :facts do
      {
        :osfamily                  => 'RedHat',
        :operatingsystemmajrelease => 7,
      }
    end

    let :params do
      {
        :enable_upgrade => true
      }
    end

    it 'should contain correct upgrade ordering' do
        is_expected.to contain_exec('package-upgrade').that_comes_before('Service[nova-compute]')
        is_expected.to contain_exec('package-upgrade').with(:command     => 'yum -y update')
    end

  end

  it_configures 'Red Hat distributions'

end

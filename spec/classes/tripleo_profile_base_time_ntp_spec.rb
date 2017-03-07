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

describe 'tripleo::profile::base::time::ntp' do
  shared_examples_for 'tripleo::profile::base::time::ntp' do

    context 'with defaults' do
      it { is_expected.to contain_class('tripleo::profile::base::time::ntp') }
      it { is_expected.to contain_service('chronyd').with(
          :ensure => 'stopped',
          :enable => false) }
      it { is_expected.to contain_class('ntp') }
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let (:facts) {
        facts
      }
      it_behaves_like 'tripleo::profile::base::time::ntp'
    end
  end
end

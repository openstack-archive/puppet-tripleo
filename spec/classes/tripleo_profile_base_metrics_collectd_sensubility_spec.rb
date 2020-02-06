#
# Copyright (C) 2020 Red Hat, Inc.
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

describe 'tripleo::profile::base::metrics::collectd::sensubility' do
  shared_examples_for 'tripleo::profile::base::metrics::collectd::sensubility' do
    context 'with defaults and sudo rule defined' do
      let(:params) do
        {:exec_sudo_rule => 'ALL=(ALL)  NOPASSWD:ALL'}
      end
      it 'has sudoers file for appropriate user with relevant rule' do
        is_expected.to compile.with_all_deps
        is_expected.to contain_file('/etc/sudoers.d/sensubility_collectd').with_content('collectd  ALL=(ALL)  NOPASSWD:ALL')
        is_expected.to contain_exec('collectd-sudo-syntax-check').with(
          :command => "visudo -c -f '/etc/sudoers.d/sensubility_collectd' || (rm -f '/etc/sudoers.d/sensubility_collectd' && exit 1)",
        )
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let (:facts) {
        facts
      }
      it_behaves_like 'tripleo::profile::base::metrics::collectd::sensubility'
    end
  end
end

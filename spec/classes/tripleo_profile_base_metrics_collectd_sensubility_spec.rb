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

    context 'with defaults and scripts for download defined' do
      let(:params) do
        { :workdir => '/some/path',
          :scripts    => {
            'scriptA' => {
              'source'   => 'http://some.uri/scriptA',
              'checksum' => '227e8f542d95e416462a7f17652da655',
            },
            'scriptB' => {
              'source'          => 'http://some.other.uri/scriptB',
              'checksum'        => '48a404e59d4a43239ce64dee3af038b9',
              'create_bin_link' => false
            }
          }
        }
      end

      it 'requests the scripts download' do
        is_expected.to compile.with_all_deps
        is_expected.to contain_file('/some/path/scripts/scriptA').with(
          :source         => 'http://some.uri/scriptA',
          :checksum_value => '227e8f542d95e416462a7f17652da655',
        )
        is_expected.to contain_file('/usr/bin/sensubility_scriptA')

        is_expected.to contain_file('/some/path/scripts/scriptB').with(
          :source         => 'http://some.other.uri/scriptB',
          :checksum_value => '48a404e59d4a43239ce64dee3af038b9',
        )
        is_expected.not_to contain_file('/usr/bin/sensubility_scriptB')
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

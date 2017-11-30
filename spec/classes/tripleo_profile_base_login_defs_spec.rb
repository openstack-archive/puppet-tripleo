# Copyright 2017 Red Hat, Inc.  # All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Unit tests for tripleo::profile::base::login_defs
#

require 'spec_helper'

describe 'tripleo::profile::base::login_defs' do

    shared_examples_for 'tripleo::profile::base::login_defs' do

      context 'setting values it should contain' do
        let(:params) { { :step => 1 } }
        it do
          is_expected.to contain_augeas('login_defs')
                  .with_changes(['set PASS_MAX_DAYS 99999',
                                 'set PASS_MIN_DAYS 7',
                                 'set PASS_MIN_LEN 6',
                                 'set PASS_WARN_AGE 7',
                                 'set FAIL_DELAY 4'])
        end
      end

      context 'with file attributes' do
        let(:params) { { :step => 1 } }
        it do
          is_expected.to contain_file('/etc/login.defs').with({
            'owner'  => 'root',
            'group'  => 'root',
            'mode'   => '0644',
            })
        end
      end
    end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let (:facts) {
        facts
      }
      it_behaves_like 'tripleo::profile::base::login_defs'
    end
  end
end

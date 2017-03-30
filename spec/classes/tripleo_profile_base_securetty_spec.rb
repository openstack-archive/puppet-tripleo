# Copyright 2017 Red Hat, Inc.
# All Rights Reserved.
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
# Unit tests for tripleo::profile::base::securetty
#

require 'spec_helper'

describe 'tripleo::profile::base::securetty' do

  shared_examples_for 'tripleo::profile::base::securetty' do

    context 'with defaults step 1' do
       let(:params) {{ :step => 1 }}
       it { is_expected.to contain_class('tripleo::profile::base::securetty') }
       it {
         is_expected.to contain_file('/etc/securetty').with(
           :content => ["# Managed by Puppet / TripleO Heat Templates",
                        "# A list of TTYs, from which root can log in",
                        "# see `man securetty` for reference",
                        "",
                        ""].join("\n"),
           :owner => 'root',
           :group => 'root',
           :mode  => '0600')
       }
     end

    context 'it should configure securtty' do
      let(:params) {{
        :step     => 1,
        :tty_list => ['console', 'tty1', 'tty2', 'tty3', 'tty4', 'tty5', 'tty6']
      }}

      it 'should configure securetty values' do
        is_expected.to contain_file('/etc/securetty').with(
          :owner => 'root',
          :group => 'root',
          :mode  => '0600',
          )
          .with_content(/console/)
          .with_content(/tty1/)
          .with_content(/tty2/)
          .with_content(/tty3/)
          .with_content(/tty4/)
          .with_content(/tty5/)
          .with_content(/tty6/)
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let (:facts) {
        facts
      }
      it_behaves_like 'tripleo::profile::base::securetty'
    end
  end
end

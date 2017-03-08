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
# Unit tests for tripleo::profile::base::sshd
#

require 'spec_helper'

describe 'tripleo::profile::base::sshd' do

  shared_examples_for 'tripleo::profile::base::sshd' do

    context 'it should do nothing' do
      it do
        is_expected.to contain_class('ssh')
        is_expected.to_not contain_file('/etc/issue')
        is_expected.to_not contain_file('/etc/issue.net')
        is_expected.to_not contain_file('/etc/motd')
      end
    end

    context 'with issue and issue.net configured' do
      let(:params) {{ :bannertext => 'foo' }}
      it do
        is_expected.to contain_file('/etc/issue').with({
          'content' => 'foo',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0644',
          })
        is_expected.to contain_file('/etc/issue.net').with({
          'content' => 'foo',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0644',
          })
        is_expected.to_not contain_file('/etc/motd')
      end
    end

    context 'with motd configured' do
      let(:params) {{ :motd => 'foo' }}
      it do
        is_expected.to contain_file('/etc/motd').with({
          'content' => 'foo',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0644',
          })
        is_expected.to_not contain_file('/etc/issue')
        is_expected.to_not contain_file('/etc/issue.net')
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let (:facts) {
        facts
      }
      it_behaves_like 'tripleo::profile::base::sshd'
    end
  end
end

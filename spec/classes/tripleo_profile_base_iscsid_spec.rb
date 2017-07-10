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

describe 'tripleo::profile::base::iscsid' do
  shared_examples_for 'tripleo::profile::base::iscsid' do
    context 'default params' do
      let(:params) { { :step => 2, } }

      it {
        is_expected.to contain_package('iscsi-initiator-utils')
        is_expected.to contain_exec('reset-iscsi-initiator-name')
        is_expected.to contain_file('/etc/iscsi/.initiator_reset')
      }
    end
  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::iscsid'
    end
  end
end

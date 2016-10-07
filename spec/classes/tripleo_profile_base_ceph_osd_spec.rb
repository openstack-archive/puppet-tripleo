#
# Copyright (C) 2016 Red Hat, Inc.
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

describe 'tripleo::profile::base::ceph::osd' do
  shared_examples_for 'tripleo::profile::base::ceph::osd' do
    let (:pre_condition) do
      <<-eof
      class { '::tripleo::profile::base::ceph':
        step => #{params[:step]}
      }
      eof
    end

    context 'with step less than 3' do
      let(:params) { { :step => 1 } }
      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::ceph::osd')
        is_expected.to contain_class('tripleo::profile::base::ceph')
        is_expected.to_not contain_class('ceph::profile::osd')
      end
    end

    context 'with step 3 defaults' do
      let(:params) { {
        :step => 3,
      } }

      it 'should include osd configuration' do
        is_expected.to contain_class('tripleo::profile::base::ceph')
        is_expected.to contain_class('ceph::profile::osd')
        is_expected.to_not contain_exec('set selinux to permissive on boot')
        is_expected.to_not contain_exec('set selinux to permissive')
      end
    end

    context 'with step 3 enable selinux permissive' do
      let(:params) { {
        :step => 3,
        :ceph_osd_selinux_permissive => true
      } }

      it 'should include osd configuration' do
        is_expected.to contain_class('tripleo::profile::base::ceph')
        is_expected.to contain_class('ceph::profile::osd')
        is_expected.to contain_exec('set selinux to permissive on boot')
        is_expected.to contain_exec('set selinux to permissive')
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::ceph::osd'
    end
  end
end

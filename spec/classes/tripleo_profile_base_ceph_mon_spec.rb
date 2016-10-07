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

describe 'tripleo::profile::base::ceph::mon' do
  shared_examples_for 'tripleo::profile::base::ceph::mon' do
    let (:pre_condition) do
      <<-eof
      class { '::tripleo::profile::base::ceph':
        step => #{params[:step]}
      }
      eof
    end

    context 'with step less than 2' do
      let(:params) { { :step => 1 } }
      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::ceph::mon')
        is_expected.to contain_class('tripleo::profile::base::ceph')
        is_expected.to_not contain_class('ceph::profile::mon')
      end
    end

    context 'with step 2' do
      let(:params) { {
        :step => 2,
      } }

      it 'should include mon configuration' do
        is_expected.to contain_class('tripleo::profile::base::ceph')
        is_expected.to contain_class('ceph::profile::mon')
      end
    end

    context 'with step 4 create pools' do
      let(:params) { {
        :step       => 4,
        :ceph_pools => { 'mypool' => { 'size' => 5, 'pg_num' => 128, 'pgp_num' => 128 } }
      } }

      it 'should include mon configuration' do
        is_expected.to contain_class('tripleo::profile::base::ceph')
        is_expected.to contain_class('ceph::profile::mon')
        is_expected.to contain_ceph__pool('mypool').with({
          :size => 5,
          :pg_num => 128,
          :pgp_num => 128
        })
      end
    end

  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::ceph::mon'
    end
  end
end

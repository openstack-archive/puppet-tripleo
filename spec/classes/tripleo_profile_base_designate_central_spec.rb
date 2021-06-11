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

describe 'tripleo::profile::base::designate::central' do
  shared_examples_for 'tripleo::profile::base::designate::central' do
    let(:pre_condition) do
      <<-eos
      class { 'tripleo::profile::base::designate':
        step => #{params[:step]},
        oslomsg_rpc_hosts    => [ 'localhost' ],
        oslomsg_rpc_username => 'designate',
        oslomsg_rpc_password => 'foo'
      }
      class { 'tripleo::profile::base::designate::authtoken':
        step => #{params[:step]},
      }
eos
    end

    context 'with step less than 3' do
      let(:params) { {
        :step => 1,
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::designate::central')
        is_expected.to contain_class('tripleo::profile::base::designate')
        is_expected.to_not contain_class('designate::db')
        is_expected.to_not contain_class('designate::central')
        is_expected.to_not contain_class('designate::quota')
      }
    end

    context 'with step 3 on bootstrap node' do
      let(:params) { {
        :step           => 3,
        :bootstrap_node => 'node.example.com',
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::designate::central')
        is_expected.to contain_class('tripleo::profile::base::designate')
        is_expected.to contain_class('designate::db').with(:sync_db => true)
        is_expected.to contain_class('designate::central')
        is_expected.to contain_class('designate::quota')
      }
    end

    context 'with step 3 not on bootstrap node' do
      let(:params) { {
        :step           => 3,
        :bootstrap_node => 'other.example.com',
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::designate::central')
        is_expected.to contain_class('tripleo::profile::base::designate')
        is_expected.to_not contain_class('designate::db')
        is_expected.to_not contain_class('designate::central')
        is_expected.to_not contain_class('designate::quota')
      }
    end

    context 'with step 4 not on bootstrap node' do
      let(:params) { {
        :step           => 4,
        :bootstrap_node => 'other.example.com',
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::designate::central')
        is_expected.to contain_class('tripleo::profile::base::designate')
        is_expected.to contain_class('designate::db').with(
          :sync_db => false
        )
        is_expected.to contain_class('designate::central')
        is_expected.to contain_class('designate::quota')
      }
    end

  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::designate::central'
    end
  end
end

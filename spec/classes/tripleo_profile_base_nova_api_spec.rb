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

describe 'tripleo::profile::base::nova::api' do
  shared_examples_for 'tripleo::profile::base::nova::api' do
    let(:pre_condition) do
      <<-eos
      class { 'tripleo::profile::base::nova':
        step => #{params[:step]},
        oslomsg_rpc_hosts    => [ 'localhost' ],
        oslomsg_rpc_username => 'nova',
        oslomsg_rpc_password => 'foo'
      }
      class { 'tripleo::profile::base::nova::authtoken':
        step => #{params[:step]},
      }
eos
    end

    context 'with step less than 3' do
      let(:params) { {
        :step => 1,
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova::api')
        is_expected.to contain_class('tripleo::profile::base::nova')
        is_expected.to contain_class('tripleo::profile::base::nova::authtoken')
        is_expected.to_not contain_class('nova::api')
        is_expected.to_not contain_class('nova::quota')
        is_expected.to_not contain_class('nova::keystone')
        is_expected.to_not contain_class('nova::cors')
        is_expected.to_not contain_class('nova::pci')
        is_expected.to_not contain_class('nova::vendordata')
        is_expected.to_not contain_class('nova::network::neutron')
        is_expected.to_not contain_class('nova::wsgi::apache_api')
        is_expected.to_not contain_class('nova::cron::archive_deleted_rows')
        is_expected.to_not contain_class('nova::cron::purge_shadow_tables')
      }
    end

    context 'with step 3 on bootstrap node' do
      let(:params) { {
        :step           => 3,
        :bootstrap_node => 'node.example.com',
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova::api')
        is_expected.to contain_class('tripleo::profile::base::nova')
        is_expected.to contain_class('tripleo::profile::base::nova::authtoken')
        is_expected.to contain_class('nova::cell_v2::simple_setup')
        is_expected.to contain_class('nova::api').with(
          :nova_metadata_wsgi_enabled => true
        )
        is_expected.to contain_class('nova::cors')
        is_expected.to contain_class('nova::quota')
        is_expected.to contain_class('nova::keystone')
        is_expected.to contain_class('nova::pci')
        is_expected.to contain_class('nova::vendordata')
        is_expected.to contain_class('nova::network::neutron')
        is_expected.to contain_class('nova::wsgi::apache_api')
        is_expected.to_not contain_class('nova::cron::archive_deleted_rows')
        is_expected.to_not contain_class('nova::cron::purge_shadow_tables')
      }
    end

    context 'with step 3 not on bootstrap node' do
      let(:params) { {
        :step           => 3,
        :bootstrap_node => 'other.example.com',
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova::api')
        is_expected.to contain_class('tripleo::profile::base::nova')
        is_expected.to contain_class('tripleo::profile::base::nova::authtoken')
        is_expected.to_not contain_class('nova::cell_v2::simple_setup')
        is_expected.to_not contain_class('nova::api')
        is_expected.to_not contain_class('nova::cors')
        is_expected.to_not contain_class('nova::quota')
        is_expected.to_not contain_class('nova::keystone')
        is_expected.to_not contain_class('nova::pci')
        is_expected.to_not contain_class('nova::vendordata')
        is_expected.to_not contain_class('nova::network::neutron')
        is_expected.to_not contain_class('nova::wsgi::apache_api')
        is_expected.to_not contain_class('nova::cron::archive_deleted_rows')
        is_expected.to_not contain_class('nova::cron::purge_shadow_tables')
      }
    end

    context 'with step 4 not on bootstrap node' do
      let(:params) { {
        :step           => 4,
        :bootstrap_node => 'other.example.com',
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova::api')
        is_expected.to contain_class('tripleo::profile::base::nova')
        is_expected.to contain_class('tripleo::profile::base::nova::authtoken')
        is_expected.to_not contain_class('nova::cell_v2::simple_setup')
        is_expected.to contain_class('nova::api').with(
          :nova_metadata_wsgi_enabled => true
        )
        is_expected.to contain_class('nova::cors')
        is_expected.to contain_class('nova::quota')
        is_expected.to contain_class('nova::keystone')
        is_expected.to contain_class('nova::pci')
        is_expected.to contain_class('nova::vendordata')
        is_expected.to contain_class('nova::network::neutron')
        is_expected.to contain_class('nova::wsgi::apache_api')
        is_expected.to_not contain_class('nova::cron::archive_deleted_rows')
        is_expected.to_not contain_class('nova::cron::purge_shadow_tables')
      }
    end

    context 'with step 5' do
      let(:params) { {
        :step           => 5,
        :bootstrap_node => 'other.example.com',
      } }

      it {
        is_expected.to contain_class('nova::cron::archive_deleted_rows')
        is_expected.to contain_class('nova::cron::purge_shadow_tables')
      }
    end

    context 'with step 5 and db_purge disabled' do
      let(:params) { {
        :step                 => 5,
        :bootstrap_node       => 'other.example.com',
        :nova_enable_db_purge => false,
      } }

      it {
        is_expected.to contain_class('nova::cron::archive_deleted_rows')
        is_expected.to_not contain_class('nova::cron::purge_shadow_tables')
      }
    end

    context 'with step 5 and db archive disabled' do
      let(:params) { {
        :step                   => 5,
        :bootstrap_node         => 'other.example.com',
        :nova_enable_db_archive => false,
      } }

      it {
        is_expected.to_not contain_class('nova::cron::archive_deleted_rows')
        is_expected.to_not contain_class('nova::cron::purge_shadow_tables')
      }
    end

  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(OSDefaults.get_facts({ :hostname => 'node.example.com' }))
      end

      it_behaves_like 'tripleo::profile::base::nova::api'
    end
  end
end

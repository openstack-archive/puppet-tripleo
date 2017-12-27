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

describe 'tripleo::profile::base::ceph::rgw' do
  shared_examples_for 'tripleo::profile::base::ceph::rgw' do
    let (:pre_condition) do
      <<-eof
      class { '::tripleo::profile::base::ceph':
        step => #{params[:step]}
      }
      eof
    end

    let (:default_params) do
      {
        :keystone_admin_token => 'token',
        :keystone_url         => 'url',
        :rgw_key              => 'key',
        :civetweb_bind_ip     => '2001:db8:0:1234:0:567:8:1',
        :civetweb_bind_port   => '8888',
      }
    end

    context 'with step less than 3' do
      let(:params) { default_params.merge({ :step => 1 }) }
      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::ceph::rgw')
        is_expected.to contain_class('tripleo::profile::base::ceph')
        is_expected.to_not contain_class('ceph::rgw')
      end
    end

    context 'with step 3' do
      let(:params) { default_params.merge({ :step => 3 }) }
      it 'should include rgw configuration' do
        is_expected.to contain_class('tripleo::profile::base::ceph')
        is_expected.to contain_ceph__rgw('radosgw.gateway').with(
          :frontend_type => 'civetweb',
          :rgw_frontends => 'civetweb port=[2001:db8:0:1234:0:567:8:1]:8888'
        )
        is_expected.to contain_ceph__key('client.radosgw.gateway').with(
          :secret  => 'key',
          :cap_mon => 'allow *',
          :cap_osd => 'allow *',
          :inject  => true
        )
        is_expected.to_not contain_ceph__rgw__keystone('radosgw.gateway')
      end
    end

    context 'with step 4' do
      let(:params) { default_params.merge({ :step => 4 }) }
      it 'should include rgw configuration' do
        is_expected.to contain_class('tripleo::profile::base::ceph')
        is_expected.to contain_ceph__rgw('radosgw.gateway').with(
          :frontend_type => 'civetweb',
          :rgw_frontends => 'civetweb port=[2001:db8:0:1234:0:567:8:1]:8888'
        )
        is_expected.to contain_ceph__key('client.radosgw.gateway').with(
          :secret  => 'key',
          :cap_mon => 'allow *',
          :cap_osd => 'allow *',
          :inject  => true
        )
        is_expected.to contain_ceph__rgw__keystone('radosgw.gateway').with(
          :rgw_keystone_accepted_roles => ['admin', 'Member'],
          :use_pki                     => false,
          :rgw_keystone_admin_token    => 'token',
          :rgw_keystone_url            => 'url'
        )
      end
    end

    context 'with step 4 and keystone v3' do
      let(:params) { default_params.merge({ :step => 4, :rgw_keystone_version => 'v3' }) }
      it 'should include rgw configuration' do
        is_expected.to contain_ceph__rgw__keystone('radosgw.gateway').with(
          :rgw_keystone_accepted_roles => ["admin", "Member"],
          :use_pki                     => false,
          :rgw_keystone_url            => 'url'
        )
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::ceph::rgw'
    end
  end
end

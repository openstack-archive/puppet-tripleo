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

describe 'tripleo::profile::base::glance::backend::swift' do
  shared_examples_for 'tripleo::profile::base::glance::backend::swift' do

    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'with step less than 4' do
      let(:params) { {
        :backend_names => ['my_swift'],
        :step          => 3,
      } }

      it 'should not configure a backend' do
        is_expected.to contain_class('tripleo::profile::base::glance::backend::swift')
        is_expected.to_not contain_glance__backend__multistore__swift('my_swift')
      end
    end

    context 'with step 4' do
      let(:params) { {
        :backend_names                       => ['my_swift'],
        :swift_store_user                    => 'service:glance',
        :swift_store_key                     => 'glance_password',
        :swift_store_auth_address            => '127.0.0.2:8080/v3/',
        :swift_store_auth_version            => 3,
        :swift_store_create_container_on_put => true,
        :step                                => 4,
      } }

      it 'should configure the backend' do
        is_expected.to contain_glance__backend__multistore__swift('my_swift').with(
          :swift_store_user                    => 'service:glance',
          :swift_store_key                     => 'glance_password',
          :swift_store_auth_address            => '127.0.0.2:8080/v3/',
          :swift_store_auth_version            => 3,
          :swift_store_create_container_on_put => true,
          :default_swift_reference             => 'ref1',
          :store_description                   => 'Swift store',
        )
      end

      context 'with store description in multistore_config' do
        before :each do
          params.merge!({
            :multistore_config => {
              'my_swift' => {
                'GlanceStoreDescription' => 'My multistore swift backend',
              },
            },
          })
        end
        it 'should use the multistore_config description' do
          is_expected.to contain_glance__backend__multistore__swift('my_swift').with(
            :store_description => 'My multistore swift backend',
          )
        end
      end

      context 'with multiple backend_names' do
        before :each do
          params.merge!({
            :backend_names => ['swift1', 'swift2'],
          })
        end
        it_raises 'a Puppet::Error', /Multiple swift backends are not supported./
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      it_behaves_like 'tripleo::profile::base::glance::backend::swift'
    end
  end
end

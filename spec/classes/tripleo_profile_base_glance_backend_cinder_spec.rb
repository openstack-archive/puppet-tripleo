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

describe 'tripleo::profile::base::glance::backend::cinder' do
  shared_examples_for 'tripleo::profile::base::glance::backend::cinder' do

    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'with step less than 4' do
      let(:params) { {
        :backend_names => ['my_cinder'],
        :step          => 3,
      } }

      it 'should not configure a backend' do
        is_expected.to contain_class('tripleo::profile::base::glance::backend::cinder')
        is_expected.to_not contain_glance__backend__multistore__cinder('my_cinder')
      end
    end

    context 'with step 4' do
      let(:params) { {
        :cinder_ca_certificates_file => '/path/to/certificates_file',
        :cinder_api_insecure         => true,
        :cinder_catalog_info         => 'volume:cinder:internalURL',
        :cinder_http_retries         => '10',
        :cinder_endpoint_template    => 'http://srv-foo:8776/v1/%(project_id)s',
        :cinder_store_auth_address   => '127.0.0.2:8080/v3/',
        :cinder_store_project_name   => 'services',
        :cinder_store_user_name      => 'glance',
        :cinder_store_password       => 'glance_password',
        :cinder_enforce_multipath    => true,
        :cinder_use_multipath        => true,
        :cinder_mount_point_base     => '/var/lib/glance/mnt/nfs',
        :cinder_volume_type          => 'glance-my_cinder',
        :store_description           => 'Cinder store',
        :backend_names               => ['my_cinder'],
        :step                        => 4,
      } }

      it 'should configure the backend' do
        is_expected.to contain_glance__backend__multistore__cinder('my_cinder').with(
          :cinder_ca_certificates_file => '/path/to/certificates_file',
          :cinder_api_insecure         => true,
          :cinder_catalog_info         => 'volume:cinder:internalURL',
          :cinder_http_retries         => '10',
          :cinder_endpoint_template    => 'http://srv-foo:8776/v1/%(project_id)s',
          :cinder_store_auth_address   => '127.0.0.2:8080/v3/',
          :cinder_store_project_name   => 'services',
          :cinder_store_user_name      => 'glance',
          :cinder_store_password       => 'glance_password',
          :cinder_enforce_multipath    => true,
          :cinder_use_multipath        => true,
          :cinder_mount_point_base     => '/var/lib/glance/mnt/nfs',
          :cinder_volume_type          => 'glance-my_cinder',
          :store_description           => 'Cinder store',
        )
      end


     context 'with store description and volume type in multistore_config' do
       before :each do
         params.merge!({
          :multistore_config => {
            'my_cinder' => {
              'GlanceCinderVolumeType' => 'glance-cinder',
              'GlanceStoreDescription' => 'My multistore cinder backend',
             },
           },
         })
       end
       it 'should use the multistore_config description and volume type' do
         is_expected.to contain_glance__backend__multistore__cinder('my_cinder').with(
           :cinder_volume_type => 'glance-cinder',
           :store_description => 'My multistore cinder backend',
         )
       end
     end

     context 'with multiple backend_names' do
        before :each do
          params.merge!({
            :backend_names => ['cinder1', 'cinder2'],
            :multistore_config => {
              'cinder2' => {
                'GlanceCinderVolumeType' => 'glance-cinder2',
                'GlanceStoreDescription' => 'cinder2 backend',
              },
            },
            :cinder_volume_type => 'glance-cinder1',
            :store_description => 'cinder1 backend',
          })
        end

        it 'should configure multiple backends' do
          is_expected.to contain_glance__backend__multistore__cinder('cinder1').with(
            :cinder_volume_type  => 'glance-cinder1',
            :store_description   => 'cinder1 backend',
          )
          is_expected.to contain_glance__backend__multistore__cinder('cinder2').with(
            :cinder_volume_type  => 'glance-cinder2',
            :store_description   => 'cinder2 backend',
          )
        end
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      it_behaves_like 'tripleo::profile::base::glance::backend::cinder'
    end
  end
end

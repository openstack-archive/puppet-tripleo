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

describe 'tripleo::profile::base::glance::backend::file' do
  shared_examples_for 'tripleo::profile::base::glance::backend::file' do

    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'with step less than 4' do
      let(:params) { {
        :backend_names => ['my_file'],
        :step          => 3,
      } }

      it 'should not configure a backend' do
        is_expected.to contain_class('tripleo::profile::base::glance::backend::file')
        is_expected.to_not contain_glance__backend__multistore__file('my_file')
      end
    end

    context 'with step 4' do
      let(:params) { {
        :backend_names            => ['my_file'],
        :filesystem_store_datadir => '/path/to/datadir',
        :step                     => 4,
      } }

      it 'should configure the backend' do
        is_expected.to contain_glance__backend__multistore__file('my_file').with(
          :filesystem_store_datadir => '/path/to/datadir',
          :store_description        => 'File store',
        )
      end

      context 'with parameters overridden' do
        before :each do
          params.merge!({
            :filesystem_thin_provisioning => true
          })

          it 'should configure the backend with the specified parameters' do
            is_expected.to contain_glance__backend__multistore__file('my_file').with(
              :filesystem_store_datadir     => '/path/to/datadir',
              :filesystem_thin_provisioning => true,
              :store_description            => 'File store',
            )
          end
        end
      end

      context 'with store description in multistore_config' do
        before :each do
          params.merge!({
            :multistore_config => {
              'my_file' => {
                'GlanceStoreDescription' => 'My multistore file backend',
              },
            },
          })
        end
        it 'should use the multistore_config description' do
          is_expected.to contain_glance__backend__multistore__file('my_file').with(
            :store_description => 'My multistore file backend',
          )
        end
      end

      context 'with multiple backend_names' do
        before :each do
          params.merge!({
            :backend_names => ['file1', 'file2'],
          })
        end
        it_raises 'a Puppet::Error', /Multiple file backends are not supported./
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      it_behaves_like 'tripleo::profile::base::glance::backend::file'
    end
  end
end

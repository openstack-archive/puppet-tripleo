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

describe 'tripleo::profile::base::cinder::volume::pure' do
  shared_examples_for 'tripleo::profile::base::cinder::volume::pure' do
    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'with step less than 4' do
      let(:params) { { :step => 3 } }

      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::cinder::volume::pure')
        is_expected.to contain_class('tripleo::profile::base::cinder::volume')
        is_expected.to contain_class('tripleo::profile::base::cinder')
        is_expected.to_not contain_cinder__backend__pure('tripleo_pure')
      end
    end

    context 'with step 4' do
      let(:params) { {
        :step => 4,
      } }

      it 'should trigger complete configuration' do
        # TODO(aschultz): check hiera parameters
        is_expected.to contain_cinder__backend__pure('tripleo_pure')
        is_expected.to contain_cinder_config('tripleo_pure/use_chap_auth').with_value(false)
      end

      context 'with multiple backends' do
        let(:params) { {
          :backend_name => ['tripleo_pure_1', 'tripleo_pure_2'],
          :multi_config => { 'tripleo_pure_2' => { 'CinderPureUseChap' => true }},
          :step         => 4,
        } }

        it 'should configure each backend' do
          is_expected.to contain_cinder__backend__pure('tripleo_pure_1')
          is_expected.to contain_cinder_config('tripleo_pure_1/use_chap_auth').with_value(false)
          is_expected.to contain_cinder__backend__pure('tripleo_pure_2')
          is_expected.to contain_cinder_config('tripleo_pure_2/use_chap_auth').with_value(true)
        end
      end
    end
  end


  on_supported_os.each do |os, facts|
    context 'on #{os}' do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::cinder::volume::pure'
    end
  end
end

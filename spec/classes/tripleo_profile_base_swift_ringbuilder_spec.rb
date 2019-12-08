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

describe 'tripleo::profile::base::swift::ringbuilder' do
  shared_examples_for 'tripleo::profile::base::swift::ringbuilder' do

    let :pre_condition do
      "class { 'swift':
         swift_hash_path_prefix => 'foo',
       }"
    end

    context 'with step 2 and swift_ring_get_tempurl set' do
      let(:params) { {
        :step => 2,
        :replicas => 1,
        :swift_ring_get_tempurl=> 'http://something'
      } }

      it 'should fetch and extract swift rings' do
        is_expected.to contain_exec('fetch_swift_ring_tarball')
        is_expected.to contain_exec('extract_swift_ring_tarball')
      end
    end

    context 'with step 5 and swift_ring_put_tempurl set' do
      let(:params) { {
        :step => 5,
        :replicas => 1,
        :swift_ring_put_tempurl=> 'http://something'
      } }

      it 'should pack and upload swift rings' do
        is_expected.to contain_exec('create_swift_ring_tarball')
        is_expected.to contain_exec('upload_swift_ring_tarball')
      end
    end

  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      it_behaves_like 'tripleo::profile::base::swift::ringbuilder'
    end
  end
end

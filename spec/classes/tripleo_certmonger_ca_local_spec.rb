#
# Copyright (C) 2017 Red Hat Inc.
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
# Unit tests for tripleo
#

require 'spec_helper'

describe 'tripleo::certmonger::ca::local' do

  shared_examples_for 'tripleo::certmonger::ca::local' do

    let :pre_condition do
      "include certmonger"
    end

    let :params do
      {
        :ca_pem => '/etc/pki/ca-trust/source/anchors/cm-local-ca.pem',
      }
    end

    it 'should extract CA cert' do
      is_expected.to contain_exec('extract-and-trust-ca')
    end

    it 'set the correct permissions for the CA certificate file' do
      is_expected.to contain_file(params[:ca_pem]).with(
        :ensure => 'present',
        :mode   => '0644',
        :owner  => 'root'
      )
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      it_behaves_like 'tripleo::certmonger::ca::local'
    end
  end
end

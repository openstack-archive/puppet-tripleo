# Copyright 2016 Red Hat, Inc.
# All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#

require 'spec_helper'

describe 'tripleo::profile::base::docker' do
  shared_examples_for 'tripleo::profile::base::docker' do
    context 'with step 1 and defaults' do
      let(:params) { {
          :step              => 1,
      } }

      it { is_expected.to contain_class('tripleo::profile::base::docker') }
      it { is_expected.to contain_package('docker') }
      it { is_expected.to contain_service('docker') }
      it {
          is_expected.to contain_augeas('docker-sysconfig').with_changes(['rm INSECURE_REGISTRY'])
      }
    end

    context 'with step 1 and insecure_registry configured' do
      let(:params) { {
          :docker_namespace  => 'foo:8787',
          :insecure_registry => true,
          :step              => 1,
      } }

      it { is_expected.to contain_class('tripleo::profile::base::docker') }
      it { is_expected.to contain_package('docker') }
      it { is_expected.to contain_service('docker') }
      it {
        is_expected.to contain_augeas('docker-sysconfig').with_changes(["set INSECURE_REGISTRY '\"--insecure-registry foo:8787\"'"])
      }
    end

    context 'with step 1 and insecure_registry configured but no docker_namespace' do
      let(:params) { {
          :insecure_registry => true,
          :step              => 1,
      } }

      it_raises 'a Puppet::Error', /You must provide a \$docker_namespace in order to configure insecure registry/
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::docker'
    end
  end
end

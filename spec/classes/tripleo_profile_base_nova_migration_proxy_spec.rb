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

describe 'tripleo::profile::base::nova::migration::proxy' do
  shared_examples_for 'tripleo::profile::base::nova::migration::proxy' do

    context 'with step 4 with defaults (disabled)' do
      let(:pre_condition) {
        <<-eos
        class { '::tripleo::profile::base::nova::migration':
          step => #{params[:step]}
        }
eos
      }
      let(:params) { {
        :step           => 4,
      } }

      it {
        is_expected.to_not contain_class('tripleo::profile::base::nova::migration::target')
        is_expected.to contain_file('/etc/nova/migration/proxy_identity').with(:ensure => 'absent')
      }
    end

    context 'with step 4 with ssh_private_key' do
      let(:pre_condition) {
        <<-eos
        class { '::tripleo::profile::base::nova::migration':
          step => #{params[:step]}
        }
eos
      }
      let(:params) { {
        :step                => 4,
        :ssh_private_key => 'foo',
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova::migration::target').with(
          :wrapper_command => '/bin/ssh -p 22 -i /etc/nova/migration/proxy_identity -o BatchMode=yes -o UserKnownHostsFile=/dev/null nova_migration@127.0.0.1 $SSH_ORIGINAL_COMMAND'
        )
        is_expected.to contain_file('/etc/nova/migration/proxy_identity').with(
          :content => 'foo',
          :mode => '0600',
          :owner => 'nova_migration',
          :group => 'nova_migration',
        )
      }
    end

    context 'with step 4 with host and port' do
      let(:pre_condition) {
        <<-eos
        class { '::tripleo::profile::base::nova::migration':
          step => #{params[:step]}
        }
eos
      }
      let(:params) { {
        :step                => 4,
        :ssh_private_key => 'foo',
        :target_host => 'node.example.com',
        :target_port => 1000
      } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova::migration::target').with(
          :wrapper_command => '/bin/ssh -p 1000 -i /etc/nova/migration/proxy_identity -o BatchMode=yes -o UserKnownHostsFile=/dev/null nova_migration@node.example.com $SSH_ORIGINAL_COMMAND'
        )
        is_expected.to contain_file('/etc/nova/migration/proxy_identity').with(
          :content => 'foo',
          :mode => '0600',
          :owner => 'nova_migration',
          :group => 'nova_migration',
        )
      }
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end
      it_behaves_like 'tripleo::profile::base::nova::migration::proxy'
    end
  end
end
# Copyright 2017 Red Hat, Inc.
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
# Unit tests for tripleo::profile::base::sshd
#

require 'spec_helper'

describe 'tripleo::profile::base::sshd' do

  shared_examples_for 'tripleo::profile::base::sshd' do

    context 'it should do nothing' do
      it do
        is_expected.to contain_class('ssh::server').with({
          'storeconfigs_enabled' => false,
          'options'   => {
            'Port'    => [22],
            'HostKey' => [
              '/etc/ssh/ssh_host_rsa_key',
              '/etc/ssh/ssh_host_ecdsa_key',
              '/etc/ssh/ssh_host_ed25519_key',
            ],
          }
        })
        is_expected.to_not contain_file('/etc/issue')
        is_expected.to_not contain_file('/etc/issue.net')
        is_expected.to_not contain_file('/etc/motd')
      end
    end

    context 'it should do nothing with empty strings' do
      let(:params) {{ :bannertext => '', :motd => '' }}
      it do
        is_expected.to contain_class('ssh::server').with({
          'storeconfigs_enabled' => false,
          'options' => {
            'Port' => [22],
            'HostKey' => [
              '/etc/ssh/ssh_host_rsa_key',
              '/etc/ssh/ssh_host_ecdsa_key',
              '/etc/ssh/ssh_host_ed25519_key',
            ],
          }
        })
        is_expected.to_not contain_file('/etc/issue')
        is_expected.to_not contain_file('/etc/issue.net')
        is_expected.to_not contain_file('/etc/motd')
      end
    end

    context 'with port configured' do
      let(:params) {{ :port => 123 }}
      it do
        is_expected.to contain_class('ssh::server').with({
          'storeconfigs_enabled' => false,
          'options' => {
            'Port' => [123],
            'HostKey' => [
              '/etc/ssh/ssh_host_rsa_key',
              '/etc/ssh/ssh_host_ecdsa_key',
              '/etc/ssh/ssh_host_ed25519_key',
            ],
          }
        })
      end
    end

    context 'with port configured and port option' do
      let(:params) {{ :port => 123, :options => {'Port' => 456}  }}
      it do
        is_expected.to contain_class('ssh::server').with({
          'storeconfigs_enabled' => false,
          'options' => {
            'Port' => [456, 123],
            'HostKey' => [
              '/etc/ssh/ssh_host_rsa_key',
              '/etc/ssh/ssh_host_ecdsa_key',
              '/etc/ssh/ssh_host_ed25519_key',
            ],
          }
        })
      end
    end

    context 'with port configured and same port option' do
      let(:params) {{ :port => 123, :options => {'Port' => 123}  }}
      it do
        is_expected.to contain_class('ssh::server').with({
          'storeconfigs_enabled' => false,
          'options' => {
            'Port' => [123],
            'HostKey' => [
              '/etc/ssh/ssh_host_rsa_key',
              '/etc/ssh/ssh_host_ecdsa_key',
              '/etc/ssh/ssh_host_ed25519_key',
            ],
          }
        })
      end
    end

    context 'with issue and issue.net configured' do
      let(:params) {{ :bannertext => 'foo' }}
      it do
        is_expected.to contain_class('ssh::server').with({
          'storeconfigs_enabled' => false,
          'options' => {
            'Banner' => '/etc/issue.net',
            'Port' => [22],
            'HostKey' => [
              '/etc/ssh/ssh_host_rsa_key',
              '/etc/ssh/ssh_host_ecdsa_key',
              '/etc/ssh/ssh_host_ed25519_key',
            ],
          }
        })
        is_expected.to contain_file('/etc/issue').with({
          'content' => 'foo',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0644',
          })
        is_expected.to contain_file('/etc/issue.net').with({
          'content' => 'foo',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0644',
          })
        is_expected.to_not contain_file('/etc/motd')
      end
    end

    context 'with motd configured' do
      let(:params) {{ :motd => 'foo' }}
      it do
        is_expected.to contain_class('ssh::server').with({
          'storeconfigs_enabled' => false,
          'options' => {
            'Port' => [22],
            'PrintMotd' => 'yes',
            'HostKey' => [
              '/etc/ssh/ssh_host_rsa_key',
              '/etc/ssh/ssh_host_ecdsa_key',
              '/etc/ssh/ssh_host_ed25519_key',
            ],
          }
        })
        is_expected.to contain_file('/etc/motd').with({
          'content' => 'foo',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0644',
          })
        is_expected.to_not contain_file('/etc/issue')
        is_expected.to_not contain_file('/etc/issue.net')
      end
    end

    context 'with options configured' do
      let(:params) {{ :options => {'X11Forwarding' => 'no'} }}
      it do
        is_expected.to contain_class('ssh::server').with({
          'storeconfigs_enabled' => false,
          'options' => {
            'Port' => [22],
            'X11Forwarding' => 'no',
            'HostKey' => [
              '/etc/ssh/ssh_host_rsa_key',
              '/etc/ssh/ssh_host_ecdsa_key',
              '/etc/ssh/ssh_host_ed25519_key',
            ],
          }
        })
        is_expected.to_not contain_file('/etc/motd')
        is_expected.to_not contain_file('/etc/issue')
        is_expected.to_not contain_file('/etc/issue.net')
      end
    end

    context 'with motd and issue configured' do
      let(:params) {{
        :bannertext => 'foo',
        :motd => 'foo'
      }}
      it do
        is_expected.to contain_class('ssh::server').with({
          'storeconfigs_enabled' => false,
          'options' => {
            'Banner' => '/etc/issue.net',
            'Port' => [22],
            'PrintMotd' => 'yes',
            'HostKey' => [
              '/etc/ssh/ssh_host_rsa_key',
              '/etc/ssh/ssh_host_ecdsa_key',
              '/etc/ssh/ssh_host_ed25519_key',
            ],
          }
        })
        is_expected.to contain_file('/etc/motd').with({
          'content' => 'foo',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0644',
          })
        is_expected.to contain_file('/etc/issue').with({
          'content' => 'foo',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0644',
          })
        is_expected.to contain_file('/etc/issue.net').with({
          'content' => 'foo',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0644',
          })
      end
    end

    context 'with motd and issue and options configured' do
      let(:params) {{
        :bannertext => 'foo',
        :motd => 'foo',
        :options => {
          'Port' => [22],
          'PrintMotd' => 'no', # this should be overridden
          'X11Forwarding' => 'no',
        }
      }}
      it do
        is_expected.to contain_class('ssh::server').with({
          'storeconfigs_enabled' => false,
          'options' => {
            'Banner' => '/etc/issue.net',
            'Port' => [22],
            'PrintMotd' => 'yes',
            'X11Forwarding' => 'no',
            'HostKey' => [
              '/etc/ssh/ssh_host_rsa_key',
              '/etc/ssh/ssh_host_ecdsa_key',
              '/etc/ssh/ssh_host_ed25519_key',
            ],
          }
        })
        is_expected.to contain_file('/etc/motd').with({
          'content' => 'foo',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0644',
          })
        is_expected.to contain_file('/etc/issue').with({
          'content' => 'foo',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0644',
          })
        is_expected.to contain_file('/etc/issue.net').with({
          'content' => 'foo',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0644',
          })
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let (:facts) {
        facts
      }
      it_behaves_like 'tripleo::profile::base::sshd'
    end
  end
end

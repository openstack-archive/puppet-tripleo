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

describe 'tripleo::profile::base::nova::libvirt' do
  shared_examples_for 'tripleo::profile::base::nova::libvirt' do

    context 'with step less than 4' do
      let(:params) { { :step => 1, } }
      let(:pre_condition) do
        <<-eos
        class { '::tripleo::profile::base::nova::compute_libvirt_shared':
          step => #{params[:step]}
        }
eos
      end
      it {
        is_expected.to contain_class('tripleo::profile::base::nova::libvirt')
        is_expected.to contain_class('tripleo::profile::base::nova::compute_libvirt_shared')
        is_expected.to_not contain_class('tripleo::profile::base::nova')
        is_expected.to_not contain_class('nova::compute::libvirt::services')
        is_expected.to_not contain_file('/etclibvirt/qemu/networks/autostart/default.xml')
        is_expected.to_not contain_file('/etclibvirt/qemu/networks/default.xml')
        is_expected.to_not contain_exec('libvirt-default-net-destroy')
        is_expected.to_not contain_exec('set libvirt sasl credentials')
      }
    end

    context 'with step 4' do
      let(:pre_condition) do
        <<-eos
        class { '::tripleo::profile::base::nova':
          step => #{params[:step]},
          oslomsg_rpc_hosts => [ '127.0.0.1' ],
        }
        class { '::tripleo::profile::base::nova::migration':
          step => #{params[:step]}
        }
        class { '::tripleo::profile::base::nova::migration::client':
          step => #{params[:step]}
        }
        class { '::tripleo::profile::base::nova::compute_libvirt_shared':
          step => #{params[:step]}
        }
eos
      end

      let(:params) { { :step => 4, } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova::libvirt')
        is_expected.to contain_class('tripleo::profile::base::nova::compute_libvirt_shared')
        is_expected.to contain_class('tripleo::profile::base::nova')
        is_expected.to contain_class('nova::compute::libvirt::services')
        is_expected.to contain_class('nova::compute::libvirt::qemu')
        is_expected.to contain_class('nova::migration::qemu')
        is_expected.to contain_file('/etc/libvirt/qemu/networks/autostart/default.xml').with_ensure('absent')
        is_expected.to contain_file('/etc/libvirt/qemu/networks/default.xml').with_ensure('absent')
        is_expected.to contain_exec('libvirt-default-net-destroy')
        is_expected.to contain_class('nova::compute::libvirt::config').with_libvirtd_config({
          "unix_sock_group"    => {"value" => '"libvirt"'},
          "auth_unix_ro"       => {"value" => '"none"'},
          "auth_unix_rw"       => {"value" => '"none"'},
          "unix_sock_ro_perms" => {"value" => '"0777"'},
          "unix_sock_rw_perms" => {"value" => '"0770"'}
        })
        is_expected.to contain_package('cyrus-sasl-scram')
        is_expected.to contain_file('/etc/sasl2/libvirt.conf')
        is_expected.to contain_file('/etc/libvirt/auth.conf').with_ensure('absent')
        is_expected.to contain_exec('set libvirt sasl credentials').with_command(
          'saslpasswd2 -d -a libvirt -u overcloud migration'
        )
      }
    end

    context 'with step 4 and libvirtd_config' do
      let(:pre_condition) do
        <<-eos
        class { '::tripleo::profile::base::nova':
          step => #{params[:step]},
          oslomsg_rpc_hosts => [ '127.0.0.1' ],
        }
        class { '::tripleo::profile::base::nova::migration':
          step => #{params[:step]}
        }
        class { '::tripleo::profile::base::nova::migration::client':
          step => #{params[:step]}
        }
        class { '::tripleo::profile::base::nova::compute_libvirt_shared':
          step => #{params[:step]}
        }
eos
      end

      let(:params) { { :step => 4, :libvirtd_config => { "unix_sock_group" => {"value" => '"foobar"'}} } }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova::libvirt')
        is_expected.to contain_class('tripleo::profile::base::nova')
        is_expected.to contain_class('nova::compute::libvirt::services')
        is_expected.to contain_file('/etc/libvirt/qemu/networks/autostart/default.xml').with_ensure('absent')
        is_expected.to contain_file('/etc/libvirt/qemu/networks/default.xml').with_ensure('absent')
        is_expected.to contain_exec('libvirt-default-net-destroy')
        is_expected.to contain_class('nova::compute::libvirt::config').with_libvirtd_config({
          "unix_sock_group"    => {"value" => '"foobar"'},
          "auth_unix_ro"       => {"value" => '"none"'},
          "auth_unix_rw"       => {"value" => '"none"'},
          "unix_sock_ro_perms" => {"value" => '"0777"'},
          "unix_sock_rw_perms" => {"value" => '"0770"'}
        })
        is_expected.to contain_package('cyrus-sasl-scram')
        is_expected.to contain_file('/etc/sasl2/libvirt.conf')
        is_expected.to contain_file('/etc/libvirt/auth.conf').with_ensure('absent')
        is_expected.to contain_exec('set libvirt sasl credentials').with_command(
          'saslpasswd2 -d -a libvirt -u overcloud migration'
        )
      }
    end

    context 'with step 4 and tls_password' do
      let(:pre_condition) do
        <<-eos
        class { '::tripleo::profile::base::nova':
          step => #{params[:step]},
          oslomsg_rpc_hosts => [ '127.0.0.1' ],
        }
        class { '::tripleo::profile::base::nova::migration':
          step => #{params[:step]}
        }
        class { '::tripleo::profile::base::nova::migration::client':
          step => #{params[:step]}
        }
        class { '::tripleo::profile::base::nova::compute_libvirt_shared':
          step => #{params[:step]}
        }
eos
      end

      let(:params) { { :step => 4, :tls_password => 'foo'} }

      it {
        is_expected.to contain_class('tripleo::profile::base::nova::libvirt')
        is_expected.to contain_class('tripleo::profile::base::nova::compute_libvirt_shared')
        is_expected.to contain_class('tripleo::profile::base::nova')
        is_expected.to contain_class('nova::compute::libvirt::services')
        is_expected.to contain_class('nova::compute::libvirt::qemu')
        is_expected.to contain_class('nova::migration::qemu')
        is_expected.to contain_file('/etc/libvirt/qemu/networks/autostart/default.xml').with_ensure('absent')
        is_expected.to contain_file('/etc/libvirt/qemu/networks/default.xml').with_ensure('absent')
        is_expected.to contain_exec('libvirt-default-net-destroy')
        is_expected.to contain_class('nova::compute::libvirt::config').with_libvirtd_config({
          "unix_sock_group"    => {"value" => '"libvirt"'},
          "auth_unix_ro"       => {"value" => '"none"'},
          "auth_unix_rw"       => {"value" => '"none"'},
          "unix_sock_ro_perms" => {"value" => '"0777"'},
          "unix_sock_rw_perms" => {"value" => '"0770"'}
        })
        is_expected.to contain_package('cyrus-sasl-scram')
        is_expected.to contain_file('/etc/sasl2/libvirt.conf')
        is_expected.to contain_file('/etc/libvirt/auth.conf').with_ensure('present')
        is_expected.to contain_exec('set libvirt sasl credentials').with_command(
          "echo \"\${TLS_PASSWORD}\" | saslpasswd2 -p -a libvirt -u overcloud migration"
        )
      }
    end
  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::nova::libvirt'
    end
  end
end

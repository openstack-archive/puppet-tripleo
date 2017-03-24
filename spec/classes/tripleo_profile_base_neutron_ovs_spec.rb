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

describe 'tripleo::profile::base::neutron::ovs' do

  shared_examples_for 'tripleo::profile::base::neutron::ovs with default params' do

    let(:pre_condition) do
      "class { '::tripleo::profile::base::neutron': step => #{params[:step]} }"
    end

    context 'with defaults for all parameters' do

      let(:params) { { :step => 5 } }

      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::neutron')
        is_expected.to contain_class('neutron::agents::ml2::ovs')
        is_expected.not_to contain_file('/var/lib/vhostuser_sockets')
      end
    end
  end

  shared_examples_for 'tripleo::profile::base::neutron::ovs with vhostuser_socketdir' do

    let(:pre_condition) do
      "class { '::tripleo::profile::base::neutron': step => #{params[:step]} }"
    end

    context 'with vhostuser_socketdir configured' do
      let :params do
        {
          :step => 5,
          :vhostuser_socket_dir => '/var/lib/vhostuser_sockets'
        }
      end

      it { is_expected.to contain_class('tripleo::profile::base::neutron') }
      it { is_expected.to contain_class('neutron::agents::ml2::ovs') }
      it { is_expected.to contain_file('/var/lib/vhostuser_sockets').with(
        :ensure => 'directory',
        :owner  => 'qemu',
        :group  => 'qemu',
        :mode   => '0775',
      ) }
    end
  end


  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::neutron::ovs with default params'
      it_behaves_like 'tripleo::profile::base::neutron::ovs with vhostuser_socketdir'
    end
  end
end


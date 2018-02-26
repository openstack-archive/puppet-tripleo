#
# Copyright (C) 2018 Red Hat, Inc.
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

describe 'tripleo::profile::base::neutron::plugins::ovs::opendaylight' do

  shared_examples_for 'tripleo::profile::base::neutron::plugins::ovs::opendaylight' do

  let :params do
    { :step          => 4,
      :odl_port      => 8081,
      :odl_check_url => 'restconf/operational/network-topology:network-topology/topology/netvirt:1',
      :odl_api_ips   => ['192.0.2.5'],
      :odl_url_ip    => '192.0.2.6',
      :tunnel_ip     => '11.0.0.5',
    }
    end

    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'with defaults for all parameters at step 3' do
      before do
        params.merge!({ :step => 3 })
        facts.merge!({ :step => params[:step] })
      end
      it 'should do nothing' do
        is_expected.not_to contain_file('/var/lib/vhostuser_sockets')
      end
    end

    context 'with vhostuser_socketdir configured at step 3' do
      before do
        params.merge!({ :step => 3,
                        :vhostuser_socket_dir => '/var/lib/vhostuser_sockets' })
        facts.merge!({ :step => params[:step] })
      end
      it { is_expected.to contain_file('/var/lib/vhostuser_sockets').with(
        :ensure => 'directory',
        :owner  => 'qemu',
        :group  => 'qemu',
        :mode   => '0775',
      ) }
    end

    context 'with vhostuser_socketdir and its user/group configured' do
      before do
        params.merge!({ :step => 3,
                        :vhostuser_socket_dir => '/var/lib/vhostuser_sockets',
                        :vhostuser_socket_group => 'hugetlbfs',
                        :vhostuser_socket_user  => 'openvswitch'})
        facts.merge!({ :step => params[:step] })
      end
      it { is_expected.to contain_file('/var/lib/vhostuser_sockets').with(
        :ensure => 'directory',
        :owner  => 'openvswitch',
        :group  => 'hugetlbfs',
        :mode   => '0775',
      ) }
    end

    context 'with empty OpenDaylight API IPs' do
      before do
        params.merge!({
          :odl_api_ips => []
        })
      end
      it 'should fail to configure OVS' do
        is_expected.to compile.and_raise_error(/No IPs assigned to OpenDaylight API Service/)
      end
    end

    context 'with empty OpenDaylight VIP' do
      before do
        params.merge!({
          :odl_url_ip  => []
        })
      end
      it 'should fail to configure OVS' do
        is_expected.to compile.and_raise_error(/OpenDaylight API VIP is Empty/)
      end
    end

    context 'with no TLS' do

      it 'should configure OVS for ODL' do
        is_expected.to contain_class('neutron::plugins::ovs::opendaylight').with(
          :tunnel_ip       => params[:tunnel_ip],
          :odl_check_url   => "http://#{params[:odl_url_ip]}:#{params[:odl_port]}/#{params[:odl_check_url]}",
          :odl_ovsdb_iface => "tcp:#{params[:odl_api_ips][0]}:6640",
          :enable_tls      => false,
          :tls_key_file    => nil,
          :tls_cert_file   => nil
        )
      end
    end

    context 'with TLS enabled' do
      before do
        File.stubs(:file?).returns(true)
        File.stubs(:readlines).returns(["MIIFGjCCBAKgAwIBAgICA"])
        params.merge!({
          :enable_internal_tls => true,
          :conn_proto          => 'https',
          :certificate_specs => {
             "service_certificate" => "/etc/pki/tls/certs/ovs.crt",
             "service_key" => "/etc/pki/tls/private/ovs.key"}
        })
      end
      it 'should configure OVS for ODL' do
        is_expected.to contain_class('neutron::plugins::ovs::opendaylight').with(
          :tunnel_ip       => params[:tunnel_ip],
          :odl_check_url   => "https://#{params[:odl_url_ip]}:#{params[:odl_port]}/#{params[:odl_check_url]}",
          :odl_ovsdb_iface => "ssl:#{params[:odl_api_ips][0]}:6640",
          :enable_tls      => true,
          :tls_key_file    => params[:certificate_specs]['service_key'],
          :tls_cert_file   => params[:certificate_specs]['service_certificate']
        )
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ :hostname => 'node.example.com' })
      end

      it_behaves_like 'tripleo::profile::base::neutron::plugins::ovs::opendaylight'
    end
  end
end

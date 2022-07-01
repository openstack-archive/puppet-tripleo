#
# Copyright (C) 2022 Red Hat, Inc.
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

describe 'tripleo::profile::base::neutron::plugins::ml2::ovn' do

  shared_examples_for 'tripleo::profile::base::neutron::plugins::ml2::ovn' do

    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'with step less than 4' do
      let(:params) { {
        :step             => 3,
        :ovn_db_node_ips  => ['192.168.111.10', '192.168.111.11'],
        :ovn_db_clustered => true,
        :ovn_sb_port      => 999,
        :ovn_nb_port      => 998,
      } }
      it 'should do nothing' do
        is_expected.to contain_class('tripleo::profile::base::neutron::plugins::ml2::ovn')
        is_expected.to_not contain_class('neutron::plugins::ml2::ovn')
      end
    end

    context 'with step 4 and later and clustered ovn dbs' do
      let(:params) { {
        :step             => 4,
        :ovn_db_node_ips  => ['192.168.111.10', '192.168.111.11'],
        :ovn_db_clustered => true,
        :ovn_sb_port      => 999,
        :ovn_nb_port      => 998,
      } }
      it 'should configure ovn ML2 plugin with clustered node ips' do
        is_expected.to contain_class('neutron::plugins::ml2::ovn').with({
          :ovn_nb_connection  => ['tcp:192.168.111.10:998,tcp:192.168.111.11:998'],
          :ovn_sb_connection  => ['tcp:192.168.111.10:999,tcp:192.168.111.11:999'],
          :ovn_nb_private_key => '<SERVICE DEFAULT>',
          :ovn_nb_certificate => '<SERVICE DEFAULT>',
          :ovn_nb_ca_cert     => '<SERVICE DEFAULT>',
          :ovn_sb_private_key => '<SERVICE DEFAULT>',
          :ovn_sb_certificate => '<SERVICE DEFAULT>',
          :ovn_sb_ca_cert     => '<SERVICE DEFAULT>',
          :dns_servers        => '<SERVICE DEFAULT>'
        })
      end
    end

    context 'with step 4 and later and clustered ovn dbs, ssl connections' do
      let(:params) { {
        :step               => 4,
        :ovn_db_node_ips    => ['192.168.111.10', '192.168.111.11'],
        :ovn_db_clustered   => true,
        :ovn_sb_port        => 999,
        :ovn_nb_port        => 998,
        :protocol           => 'ssl',
        :ovn_nb_private_key => 'nb private key',
        :ovn_nb_certificate => 'nb certificate',
        :ovn_sb_private_key => 'sb private key',
        :ovn_sb_certificate => 'sb certificate',
        :ovn_sb_ca_cert     => 'sb ca cert',
        :ovn_nb_ca_cert     => 'nb ca cert',
      } }
      it 'should configure ovn ML2 plugin with clustered node ips and ssl connections' do
        is_expected.to contain_class('neutron::plugins::ml2::ovn').with({
          :ovn_nb_connection  => ['ssl:192.168.111.10:998,ssl:192.168.111.11:998'],
          :ovn_sb_connection  => ['ssl:192.168.111.10:999,ssl:192.168.111.11:999'],
          :ovn_nb_private_key => 'nb private key',
          :ovn_nb_certificate => 'nb certificate',
          :ovn_sb_private_key => 'sb private key',
          :ovn_sb_certificate => 'sb certificate',
          :ovn_sb_ca_cert     => 'sb ca cert',
          :ovn_nb_ca_cert     => 'nb ca cert',
          :dns_servers        => '<SERVICE DEFAULT>'
        })
      end
    end

    context 'with step 4 and later and non clustered ovn dbs' do
      let(:params) { {
        :step             => 4,
        :ovn_db_node_ips  => ['192.168.111.10', '192.168.111.11'],
        :ovn_db_host      => ['192.168.100.99'],
        :ovn_db_clustered => false,
        :ovn_sb_port      => 999,
        :ovn_nb_port      => 998,
      } }
      it 'should configure ovn ML2 plugin with non-clustered node ips' do
        is_expected.to contain_class('neutron::plugins::ml2::ovn').with({
          :ovn_nb_connection  => ['tcp:192.168.100.99:998'],
          :ovn_sb_connection  => ['tcp:192.168.100.99:999'],
          :ovn_nb_private_key => '<SERVICE DEFAULT>',
          :ovn_nb_certificate => '<SERVICE DEFAULT>',
          :ovn_nb_ca_cert     => '<SERVICE DEFAULT>',
          :ovn_sb_private_key => '<SERVICE DEFAULT>',
          :ovn_sb_certificate => '<SERVICE DEFAULT>',
          :ovn_sb_ca_cert     => '<SERVICE DEFAULT>',
          :dns_servers        => '<SERVICE DEFAULT>'
        })
      end
    end

    context 'with step 4 and dns integration enabled, unbound resolvers present' do
      let(:params) { {
        :step                    => 4,
        :ovn_db_node_ips         => ['192.168.111.10', '192.168.111.11'],
        :ovn_db_host             => ['192.168.100.99'],
        :ovn_db_clustered        => false,
        :ovn_sb_port             => 999,
        :ovn_nb_port             => 998,
        :neutron_dns_integration => true,
        :unbound_resolvers       => ['10.0.0.50', '10.0.3.20']
      } }
      it 'should configure ovn ML2 plugin with non-clustered node ips' do
        is_expected.to contain_class('neutron::plugins::ml2::ovn').with({
          :ovn_nb_connection  => ['tcp:192.168.100.99:998'],
          :ovn_sb_connection  => ['tcp:192.168.100.99:999'],
          :ovn_nb_private_key => '<SERVICE DEFAULT>',
          :ovn_nb_certificate => '<SERVICE DEFAULT>',
          :ovn_nb_ca_cert     => '<SERVICE DEFAULT>',
          :ovn_sb_private_key => '<SERVICE DEFAULT>',
          :ovn_sb_certificate => '<SERVICE DEFAULT>',
          :ovn_sb_ca_cert     => '<SERVICE DEFAULT>',
          :dns_servers        => ['10.0.0.50', '10.0.3.20']
        })
      end
    end

    context 'with step 4 and dns integration enabled, unbound resolvers missing' do
      let(:params) { {
        :step                    => 4,
        :ovn_db_node_ips         => ['192.168.111.10', '192.168.111.11'],
        :ovn_db_host             => ['192.168.100.99'],
        :ovn_db_clustered        => false,
        :ovn_sb_port             => 999,
        :ovn_nb_port             => 998,
        :neutron_dns_integration => true,
      } }
      it 'should configure ovn ML2 plugin with non-clustered node ips' do
        is_expected.to contain_class('neutron::plugins::ml2::ovn').with({
          :ovn_nb_connection  => ['tcp:192.168.100.99:998'],
          :ovn_sb_connection  => ['tcp:192.168.100.99:999'],
          :ovn_nb_private_key => '<SERVICE DEFAULT>',
          :ovn_nb_certificate => '<SERVICE DEFAULT>',
          :ovn_nb_ca_cert     => '<SERVICE DEFAULT>',
          :ovn_sb_private_key => '<SERVICE DEFAULT>',
          :ovn_sb_certificate => '<SERVICE DEFAULT>',
          :ovn_sb_ca_cert     => '<SERVICE DEFAULT>',
          :dns_servers        => '<SERVICE DEFAULT>'
        })
      end
    end

    context 'with step 4 and dns integration disabled, unbound resolvers present' do
      let(:params) { {
        :step                    => 4,
        :ovn_db_node_ips         => ['192.168.111.10', '192.168.111.11'],
        :ovn_db_host             => ['192.168.100.99'],
        :ovn_db_clustered        => false,
        :ovn_sb_port             => 999,
        :ovn_nb_port             => 998,
        :neutron_dns_integration => false,
        :unbound_resolvers       => ['10.0.0.50', '10.0.3.20']
      } }
      it 'should configure ovn ML2 plugin with non-clustered node ips' do
        is_expected.to contain_class('neutron::plugins::ml2::ovn').with({
          :ovn_nb_connection  => ['tcp:192.168.100.99:998'],
          :ovn_sb_connection  => ['tcp:192.168.100.99:999'],
          :ovn_nb_private_key => '<SERVICE DEFAULT>',
          :ovn_nb_certificate => '<SERVICE DEFAULT>',
          :ovn_nb_ca_cert     => '<SERVICE DEFAULT>',
          :ovn_sb_private_key => '<SERVICE DEFAULT>',
          :ovn_sb_certificate => '<SERVICE DEFAULT>',
          :ovn_sb_ca_cert     => '<SERVICE DEFAULT>',
          :dns_servers        => '<SERVICE DEFAULT>'
        })
      end
    end

    context 'with step 4 and dns integration enabled, unbound resolvers missing, but user def DNS present' do
      let(:params) { {
        :step                    => 4,
        :ovn_db_node_ips         => ['192.168.111.10', '192.168.111.11'],
        :ovn_db_host             => ['192.168.100.99'],
        :ovn_db_clustered        => false,
        :ovn_sb_port             => 999,
        :ovn_nb_port             => 998,
        :neutron_dns_integration => true,
        :dns_servers             => ['10.0.0.99']
      } }
      it 'should configure ovn ML2 plugin with non-clustered node ips' do
        is_expected.to contain_class('neutron::plugins::ml2::ovn').with({
          :ovn_nb_connection  => ['tcp:192.168.100.99:998'],
          :ovn_sb_connection  => ['tcp:192.168.100.99:999'],
          :ovn_nb_private_key => '<SERVICE DEFAULT>',
          :ovn_nb_certificate => '<SERVICE DEFAULT>',
          :ovn_nb_ca_cert     => '<SERVICE DEFAULT>',
          :ovn_sb_private_key => '<SERVICE DEFAULT>',
          :ovn_sb_certificate => '<SERVICE DEFAULT>',
          :ovn_sb_ca_cert     => '<SERVICE DEFAULT>',
          :dns_servers        => ['10.0.0.99']
        })
      end
    end

    context 'with step 4 and dns integration disabled, but user def DNS present' do
      let(:params) { {
        :step                    => 4,
        :ovn_db_node_ips         => ['192.168.111.10', '192.168.111.11'],
        :ovn_db_host             => ['192.168.100.99'],
        :ovn_db_clustered        => false,
        :ovn_sb_port             => 999,
        :ovn_nb_port             => 998,
        :neutron_dns_integration => false,
        :dns_servers             => ['10.0.0.99']
      } }
      it 'should configure ovn ML2 plugin with non-clustered node ips' do
        is_expected.to contain_class('neutron::plugins::ml2::ovn').with({
          :ovn_nb_connection  => ['tcp:192.168.100.99:998'],
          :ovn_sb_connection  => ['tcp:192.168.100.99:999'],
          :ovn_nb_private_key => '<SERVICE DEFAULT>',
          :ovn_nb_certificate => '<SERVICE DEFAULT>',
          :ovn_nb_ca_cert     => '<SERVICE DEFAULT>',
          :ovn_sb_private_key => '<SERVICE DEFAULT>',
          :ovn_sb_certificate => '<SERVICE DEFAULT>',
          :ovn_sb_ca_cert     => '<SERVICE DEFAULT>',
          :dns_servers        => ['10.0.0.99']
        })
      end
    end

  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(OSDefaults.get_facts({ :hostname => 'node.example.com'}))
      end
      it_behaves_like 'tripleo::profile::base::neutron::plugins::ml2::ovn'
    end
  end

end

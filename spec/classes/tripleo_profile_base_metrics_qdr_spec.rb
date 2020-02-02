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

describe 'tripleo::profile::base::metrics::qdr' do

  let :params do
    {
      :step => 3,
      :username   => 'openstack',
      :password   => 'secret',
    }
  end

  shared_examples_for 'tripleo::profile::base::metrics::qdr' do

    context 'with step 3 node in edge-only mode' do
      before do
        params.merge!({
          :interior_mesh_nodes => '',
          :router_mode => 'edge',
          :ssl_internal_profile_name => 'sslProfile',
        })
      end

      it 'should avoid setting additional listeners or connectors' do
        is_expected.to contain_class('qdr').with(
          :extra_listeners => [],
          :connectors => [],
        )
      end
    end

    context 'with step 3, edge node with defined interior_node and explicit external connectors' do
      before do
        params.merge!({
          :connectors => [
            {'host' => 'saf-node1.example.com','port' => '5666','role' => 'interior','authenticatePeer' => 'no',
             'saslMechanisms' => 'ANONYMOUS','sslProfile' => 'sslProfile'},
            {'host' => 'saf-node2.example.com','port' => '5666','role' => 'interior','authenticatePeer' => 'no',
             'saslMechanisms' => 'ANONYMOUS','sslProfile' => 'sslProfile'}],
          :interior_mesh_nodes => '192.168.24.124,',
          :router_mode => 'edge',
          :ssl_internal_profile_name => 'sslProfile',
        })
      end

      it 'should setup connector to interior node and avoid setting explicit connectors' do
        is_expected.to contain_class('qdr').with(
          :extra_listeners => [],
          :connectors => [
            {'host' => '192.168.24.124','port' => '5668','role' => 'edge','verifyHostname' => false,
             'saslMechanisms' => 'ANONYMOUS','sslProfile' => 'sslProfile'}],
        )
      end
    end

    context 'with step 3, interior node with defined interior_node and explicit external connectors' do
      before do
        params.merge!({
          :listener_addr => '172.17.1.1',
          :connectors => [
            {'host' => 'saf-node1.example.com','port' => '5666','role' => 'interior','authenticatePeer' => 'no',
             'saslMechanisms' => 'ANONYMOUS','sslProfile' => 'sslProfile'},
            {'host' => 'saf-node2.example.com','port' => '5666','role' => 'interior','authenticatePeer' => 'no',
             'saslMechanisms' => 'ANONYMOUS','sslProfile' => 'sslProfile'}],
          :interior_mesh_nodes => '192.168.24.123,',
          :router_mode => 'interior',
          :ssl_internal_profile_name => 'sslProfile',
        })
      end

      it 'should setup explicit connectors and edge listener' do
        is_expected.to contain_class('qdr').with(
          :extra_listeners => [
            {'host' => '192.168.24.123','port' => '5668','role' => 'edge','authenticatePeer' => 'no',
             'saslMechanisms' => 'ANONYMOUS','sslProfile' => 'sslProfile'}],
          :connectors => [
            {'host' => 'saf-node1.example.com','port' => '5666','role' => 'interior','authenticatePeer' => 'no',
             'saslMechanisms' => 'ANONYMOUS','sslProfile' => 'sslProfile'},
            {'host' => 'saf-node2.example.com','port' => '5666','role' => 'interior','authenticatePeer' => 'no',
             'saslMechanisms' => 'ANONYMOUS','sslProfile' => 'sslProfile'}],
        )
      end
    end

    context 'with step 3 and three interior nodes, on node1' do
      before do
        params.merge!({
          :listener_addr => '172.17.1.1',
          :interior_mesh_nodes => '192.168.24.1,192.168.24.2,192.168.24.3,',
          :interior_ip => '192.168.24.1',
          :router_mode => 'interior',
          :ssl_internal_profile_name => 'sslProfile',
        })
      end

      it 'should set edge listener, interior listener and no connectors' do
        is_expected.to contain_class('qdr').with(
          :extra_listeners => [
            {'sslProfile' => 'sslProfile', 'host' => '192.168.24.1', 'port' => '5668',
             'role' => 'edge', 'authenticatePeer' => 'no', 'saslMechanisms' => 'ANONYMOUS'},
            {'sslProfile' => 'sslProfile', 'host' => '192.168.24.1', 'port' => '5667',
             'role' => 'inter-router', 'authenticatePeer' => 'no', 'saslMechanisms' => 'ANONYMOUS'}],
          :connectors => [],
        )
      end
    end

    context 'with step 3 and three interior nodes, on node2' do
      before do
        params.merge!({
          :listener_addr => '172.17.1.2',
          :interior_mesh_nodes => '192.168.24.1,192.168.24.2,192.168.24.3,',
          :interior_ip => '192.168.24.2',
          :router_mode => 'interior',
          :ssl_internal_profile_name => 'sslProfile',
        })
      end

      it 'should set up edge listener, interior listener and one interior connector to node1' do
        is_expected.to contain_class('qdr').with(
          :extra_listeners => [
            {'sslProfile' => 'sslProfile', 'host' => '192.168.24.2', 'port' => '5668',
             'role' => 'edge', 'authenticatePeer' => 'no', 'saslMechanisms' => 'ANONYMOUS'},
            {'sslProfile' => 'sslProfile', 'host' => '192.168.24.2', 'port' => '5667',
             'role' => 'inter-router', 'authenticatePeer' => 'no', 'saslMechanisms' => 'ANONYMOUS'}],
          :connectors => [
            {'host' => '192.168.24.1','role' => 'inter-router','port' => '5667',
             'verifyHostname' => 'false','sslProfile' => 'sslProfile'}],
        )
      end
    end

    context 'with step 3 and three interior nodes, on node3' do
      before do
        params.merge!({
          :listener_addr => '172.17.1.3',
          :interior_mesh_nodes => '192.168.24.1,192.168.24.2,192.168.24.3,',
          :interior_ip => '192.168.24.3',
          :router_mode => 'interior',
          :ssl_internal_profile_name => 'sslProfile',
        })
      end

      it 'should set up edge listener, interior listener and two interior connectors to node1 and node2' do
        is_expected.to contain_class('qdr').with(
          :extra_listeners => [
            {'sslProfile' => 'sslProfile', 'host' => '192.168.24.3', 'port' => '5668',
             'role' => 'edge', 'authenticatePeer' => 'no', 'saslMechanisms' => 'ANONYMOUS'},
            {'sslProfile' => 'sslProfile', 'host' => '192.168.24.3', 'port' => '5667',
             'role' => 'inter-router', 'authenticatePeer' => 'no', 'saslMechanisms' => 'ANONYMOUS'}],
         :connectors => [
            {"host"=>"192.168.24.1", "role"=>"inter-router", "port"=>"5667",
             "verifyHostname" => 'false',"sslProfile" => "sslProfile"},
            {"host"=>"192.168.24.2", "role"=>"inter-router", "port"=>"5667",
             "verifyHostname" => 'false',"sslProfile" => "sslProfile"}],
        )
      end
    end

    context 'with step 3 and three interior nodes, on edge node' do
      before do
        params.merge!({
          :interior_mesh_nodes => '192.168.24.1,192.168.24.2,192.168.24.3,',
          :router_mode => 'edge',
          :ssl_internal_profile_name => 'sslProfile',
        })
      end

      it 'should set up connectors to one of the interior nodes and no extra listeners' do
        is_expected.to contain_class('qdr').with(:extra_listeners => [])
        connectors = catalogue.resource('class', 'qdr').send(:parameters)[:connectors]
        expect(connectors.length).to match 1
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ })
      end

      it_behaves_like 'tripleo::profile::base::metrics::qdr'
    end
  end
end

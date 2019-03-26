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
        facts.merge!({
          :hostname => 'node.example.com',
        })
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
        facts.merge!({
          :hostname => 'edge-node.example.com',
        })
        params.merge!({
          :connectors => [
            {'host' => 'saf-node1.example.com','port' => '5666','role' => 'interior','authenticatePeer' => 'no',
             'saslMechanisms' => 'ANONYMOUS','sslProfile' => 'sslProfile'},
            {'host' => 'saf-node2.example.com','port' => '5666','role' => 'interior','authenticatePeer' => 'no',
             'saslMechanisms' => 'ANONYMOUS','sslProfile' => 'sslProfile'}],
          :interior_mesh_nodes => 'interior-node.example.com,',
          :router_mode => 'edge',
          :ssl_internal_profile_name => 'sslProfile',
        })
      end

      it 'should setup connector to interior node and avoid setting explicit connectors' do
        is_expected.to contain_class('qdr').with(
          :extra_listeners => [],
          :connectors => [
            {'host' => 'interior-node.example.com','port' => '5668','role' => 'edge','verifyHostname' => false,
             'saslMechanisms' => 'ANONYMOUS','sslProfile' => 'sslProfile'}],
        )
      end
    end

    context 'with step 3, interior node with defined interior_node and explicit external connectors' do
      before do
        facts.merge!({
          :hostname => 'interior-node.example.com',
        })
        params.merge!({
          :listener_addr => 'interior-node.example.com',
          :connectors => [
            {'host' => 'saf-node1.example.com','port' => '5666','role' => 'interior','authenticatePeer' => 'no',
             'saslMechanisms' => 'ANONYMOUS','sslProfile' => 'sslProfile'},
            {'host' => 'saf-node2.example.com','port' => '5666','role' => 'interior','authenticatePeer' => 'no',
             'saslMechanisms' => 'ANONYMOUS','sslProfile' => 'sslProfile'}],
          :interior_mesh_nodes => 'interior-node.example.com,',
          :router_mode => 'interior',
          :ssl_internal_profile_name => 'sslProfile',
        })
      end

      it 'should setup explicit connectors and edge listener' do
        is_expected.to contain_class('qdr').with(
          :extra_listeners => [
            {'host' => 'interior-node.example.com','port' => '5668','role' => 'edge','authenticatePeer' => 'no',
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
        facts.merge!({
          :hostname => 'node1.example.com',
        })
        params.merge!({
          :listener_addr => 'node1.example.com',
          :interior_mesh_nodes => 'node1.example.com,node2.example.com,node3.example.com,',
          :router_mode => 'interior',
          :ssl_internal_profile_name => 'sslProfile',
        })
      end

      it 'should set edge listener, interior listener and no connectors' do
        is_expected.to contain_class('qdr').with(
          :extra_listeners => [
            {'host' => 'node1.example.com','port' => '5668','role' => 'edge','authenticatePeer' => 'no',
             'saslMechanisms' => 'ANONYMOUS','sslProfile' => 'sslProfile'},
            {'host' => 'node1.example.com','port' => '5667','role' => 'inter-router','authenticatePeer' => 'no',
             'saslMechanisms' => 'ANONYMOUS','sslProfile' => 'sslProfile'}],
          :connectors => [],
        )
      end
    end

    context 'with step 3 and three interior nodes, on node2' do
      before do
        facts.merge!({
          :hostname => 'node2.example.com',
        })
        params.merge!({
          :listener_addr => 'node2.example.com',
          :interior_mesh_nodes => 'node1.example.com,node2.example.com,node3.example.com,',
          :router_mode => 'interior',
          :ssl_internal_profile_name => 'sslProfile',
        })
      end

      it 'should set up edge listener, interior listener and one interior connector to node1' do
        is_expected.to contain_class('qdr').with(
          :extra_listeners => [
            {'host' => 'node2.example.com','port' => '5668','role' => 'edge','authenticatePeer' => 'no',
             'saslMechanisms' => 'ANONYMOUS','sslProfile' => 'sslProfile'},
            {'host' => 'node2.example.com','port' => '5667','role' => 'inter-router','authenticatePeer' => 'no',
             'saslMechanisms' => 'ANONYMOUS','sslProfile' => 'sslProfile'}],
          :connectors => [
            {'host' => 'node1.example.com','role' => 'inter-router','port' => '5667',
             'verifyHostname' => 'false','sslProfile' => 'sslProfile'}],
        )
      end
    end

    context 'with step 3 and three interior nodes, on node3' do
      before do
        facts.merge!({
          :hostname => 'node3.example.com',
        })
        params.merge!({
          :listener_addr => 'node3.example.com',
          :interior_mesh_nodes => 'node1.example.com,node2.example.com,node3.example.com,',
          :router_mode => 'interior',
          :ssl_internal_profile_name => 'sslProfile',
        })
      end

      it 'should set up edge listener, interior listener and two interior connectors to node1 and node2' do
        is_expected.to contain_class('qdr').with(
          :extra_listeners => [
            {'host' => 'node3.example.com','port' => '5668','role' => 'edge','authenticatePeer' => 'no',
             'saslMechanisms' => 'ANONYMOUS','sslProfile' => 'sslProfile'},
            {'host' => 'node3.example.com','port' => '5667','role' => 'inter-router','authenticatePeer' => 'no',
             'saslMechanisms' => 'ANONYMOUS','sslProfile' => 'sslProfile'}],
         :connectors => [
            {"host"=>"node1.example.com", "role"=>"inter-router", "port"=>"5667",
             "verifyHostname" => 'false',"sslProfile" => "sslProfile"},
            {"host"=>"node2.example.com", "role"=>"inter-router", "port"=>"5667",
             "verifyHostname" => 'false',"sslProfile" => "sslProfile"}],
        )
      end
    end

    context 'with step 3 and three interior nodes, on edge node' do
      before do
        facts.merge!({
          :hostname => 'edge.example.com',
        })
        params.merge!({
          :interior_mesh_nodes => 'node1.example.com,node2.example.com,node3.example.com,',
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

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

describe 'tripleo::haproxy' do

  shared_examples_for 'tripleo::haproxy' do
    let :params do {
      :controller_virtual_ip     => '10.1.0.1',
      :public_virtual_ip         => '192.168.0.1',
      :mysql_max_conn            => 100
    }
    end

    describe "default settings" do
      it 'should configure haproxy' do
        is_expected.to contain_haproxy__listen('mysql').with(
          :options => {
            'timeout client' => "90m",
            'timeout server' => "90m",
            'maxconn'        => 100
          }
        )
      end
    end

    describe "set clustercheck" do
      before :each do
        params.merge!({
          :mysql_clustercheck => true,
        })
      end

      it 'should configure haproxy with clustercheck' do
        is_expected.to contain_haproxy__listen('mysql').with(
          :options => {
            'option'         => ["tcpka", "httpchk", "tcplog"],
            'timeout client' => "90m",
            'timeout server' => "90m",
            'stick-table'    => "type ip size 1000",
            'stick'          => "on dst",
            'maxconn'        => 100
          }
        )
      end
    end

    describe "override maxconn with clustercheck" do
      before :each do
        params.merge!({
          :mysql_clustercheck  => true,
          :mysql_max_conn      => 6500,
        })
      end

      it 'should configure haproxy' do
        is_expected.to contain_haproxy__listen('mysql').with(
          :options => {
            'option'         => ["tcpka", "httpchk", "tcplog"],
            'timeout client' => "90m",
            'timeout server' => "90m",
            'stick-table'    => "type ip size 1000",
            'stick'          => "on dst",
            'maxconn'        => 6500
          }
        )
      end
    end

    describe "horizon" do
      before :each do
        params.merge!({
          :horizon      => true,
        })
      end

      it 'should configure haproxy horizon endpoint' do
        is_expected.to contain_class('tripleo::haproxy::horizon_endpoint')
        is_expected.to contain_haproxy__balancermember('horizon_127.0.0.1_controller-1').with(
          :options => ['check', 'inter 2000', 'rise 2', 'fall 5', 'cookie controller-1'],
        )
      end
    end

    describe "override maxconn without clustercheck" do
      before :each do
        params.merge!({
          :mysql_max_conn => 6500,
        })
      end

      it 'should configure haproxy' do
        is_expected.to contain_haproxy__listen('mysql').with(
          :options => {
            'timeout client' => "90m",
            'timeout server' => "90m",
            'maxconn'        => 6500
          }
        )
      end
    end

    describe "default Defaults for haproxy" do
      it 'should NOT activate httplog' do
        is_expected.to contain_class('haproxy').with(
          :defaults_options => {
            "mode"=>"tcp",
            "log"=>"global",
            "retries"=>"3",
            "timeout"=> [
              "http-request 10s",
              "queue 2m",
              "connect 10s",
              "client 2m",
              "server 2m",
              "check 10s",
            ],
            "maxconn"=>4096,
          }
        )
      end
    end

    describe "activate httplog" do
      before :each do
        params.merge!({
          :activate_httplog => true,
        })
      end
      it 'should activate httplog' do
        is_expected.to contain_class('haproxy').with(
          :defaults_options => {
            "mode"=>"tcp",
            "log"=>"global",
            "retries"=>"3",
            "timeout"=> [
              "http-request 10s",
              "queue 2m",
              "connect 10s",
              "client 2m",
              "server 2m",
              "check 10s",
            ],
            "maxconn"=>4096,
            "option"=>"httplog",
          }
        )
      end
    end

    describe "set log facility" do
      before :each do
        params.merge!({
          :haproxy_log_facility => 'local7',
        })
      end
      it 'should set log facility' do
        is_expected.to contain_class('haproxy').with(
          :global_options => {
            'log'     => '/dev/log local7',
            'pidfile' => '/var/run/haproxy.pid',
            'user'    => 'haproxy',
            'group'   => 'haproxy',
            'maxconn' => 20480,
            'ssl-default-bind-ciphers' => "!SSLv2:kEECDH:kRSA:kEDH:kPSK:+3DES:!aNULL:!eNULL:!MD5:!EXP:!RC4:!SEED:!IDEA:!DES",
            'ssl-default-bind-options' => "no-sslv3 no-tlsv10",
            'stats'                    => [
              'socket /var/lib/haproxy/stats mode 600 level user',
              'timeout 2m'
            ],
            'daemon' => '',
          }
        )
      end
    end

    describe "APIs with long running actions to use leastconn" do
      before :each do
        params.merge!({
          :neutron            => true,
          :cinder             => true,
          :swift_proxy_server => true,
          :heat_api           => true,
          :heat_cfn           => true,
          :ironic_inspector   => true,
          :ceph_rgw           => true,
        })
      end

      %w(neutron cinder swift_proxy_server heat_cfn ironic-inspector ceph_rgw).each do |api|
        it 'should configure haproxy ' + api + ' endpoint' do
          is_expected.to contain_haproxy__listen(api)
          p = catalogue.resource('tripleo::haproxy::endpoint', api).send(:parameters)
          expect(p).to include(listen_options: a_hash_including('balance' => 'leastconn'))
        end
      end
    end

    describe "source-based sticky sessions" do
      before :each do
        params.merge!({
          :etcd            => true,
          :ceph_grafana    => true,
          :ceph_dashboard  => true,
          :nova_novncproxy => true,
          :nova_metadata   => true,
        })
      end

      %w(etcd ceph_grafana ceph_dashboard nova_novncproxy nova_metadata).each do |svc|
        it 'should configure haproxy ' + svc + ' endpoint' do
          is_expected.to contain_haproxy__listen(svc)
          p = catalogue.resource('tripleo::haproxy::endpoint', svc).send(:parameters)
          expect(p).to include(listen_options: a_hash_including(
            'balance' => 'source'))
        end
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({ })
      end

      it_behaves_like 'tripleo::haproxy'
    end
  end

end

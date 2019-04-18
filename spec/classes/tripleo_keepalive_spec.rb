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
require 'puppet'

describe 'tripleo::keepalived' do

  shared_examples_for 'tripleo::keeplived' do

    before(:each) do
      # mock interface_for_ip function
      Puppet::Parser::Functions.newfunction(:interface_for_ip, :type => :rvalue) do |arg|
        return 'br-foo'
      end
    end

    let :default_params do
      {
        :controller_virtual_ip     => '10.0.0.1',
        :control_virtual_interface => 'eth0',
        :public_virtual_interface  => 'eth1',
        :public_virtual_ip         => '192.168.0.1',
      }
    end

    context 'with defaults' do
      let :params do
        default_params
      end

      it {
        is_expected.to contain_class('keepalived')
        is_expected.to contain_keepalived__vrrp_script('haproxy').with(
          :name_is_process => platform_params[:name_is_process],
          :script          => platform_params[:vrrp_script]
        )
        is_expected.to contain_keepalived__instance('51').with(
          :interface    => params[:control_virtual_interface],
          :virtual_ips  => [ "#{params[:controller_virtual_ip]} dev #{params[:control_virtual_interface]}" ],
          :state        => 'MASTER',
          :track_script => ['haproxy'],
          :priority     => 101
        )
        is_expected.to contain_keepalived__instance('52').with(
          :interface    => params[:public_virtual_interface],
          :virtual_ips  => [ "#{params[:public_virtual_ip]} dev #{params[:public_virtual_interface]}" ],
          :state        => 'MASTER',
          :track_script => ['haproxy'],
          :priority     => 101
        )

      }
    end

    context 'with custom vrrp script' do
      let :params do
        default_params.merge({
          :custom_vrrp_script => 'foobar'
        })
      end

      it {
        is_expected.to contain_keepalived__vrrp_script('haproxy').with(
          :name_is_process => platform_params[:name_is_process],
          :script          => params[:custom_vrrp_script]
        )
      }
    end

    context 'with redis virtual ipv4' do
      let :params do
        default_params.merge({
          :redis_virtual_ip => '10.1.1.1'
        })
      end

      it {
        is_expected.to contain_keepalived__instance('53').with(
          :interface    => 'br-foo',
          :virtual_ips  => [ "#{params[:redis_virtual_ip]}/32 dev br-foo" ],
          :state        => 'MASTER',
          :track_script => ['haproxy'],
          :priority     => 101
        )
      }
    end

    context 'with redis virtual ipv6' do
      let :params do
        default_params.merge({
          :redis_virtual_ip => 'dead:beef::1'
        })
      end

      it {
        is_expected.to contain_keepalived__instance('53').with(
          :interface    => 'br-foo',
          :virtual_ips  => [ "#{params[:redis_virtual_ip]}/64 dev br-foo" ],
          :state        => 'MASTER',
          :track_script => ['haproxy'],
          :priority     => 101
        )
      }
    end

    context 'with ovndbs virtual ip' do
      let :params do
        default_params.merge({
          :ovndbs_virtual_ip => '10.1.1.1'
        })
      end

      it {
        is_expected.to contain_keepalived__instance('54').with(
          :interface    => 'br-foo',
          :virtual_ips  => [ "#{params[:ovndbs_virtual_ip]} dev br-foo" ],
          :state        => 'MASTER',
          :track_script => ['haproxy'],
          :priority     => 101
        )
      }
    end

    context 'with network ipv4 vips' do
      let :params do
        default_params.merge({
          :network_vips => {
            'internal_api' => { 'ip_address' => '10.1.0.1', 'index' => 1 },
            'tenant'       => { 'ip_address' => '10.2.0.1', 'index' => 2 }
          }
        })
      end

      it {
        is_expected.to contain_class('keepalived')
        is_expected.to contain_keepalived__instance('55').with(
          :interface    => 'br-foo',
          :virtual_ips  => [ "10.1.0.1/32 dev br-foo" ],
          :state        => 'MASTER',
          :track_script => ['haproxy'],
          :priority     => 101
        )
        is_expected.to contain_keepalived__instance('56').with(
          :interface    => 'br-foo',
          :virtual_ips  => [ "10.2.0.1/32 dev br-foo" ],
          :state        => 'MASTER',
          :track_script => ['haproxy'],
          :priority     => 101
        )
      }
    end

    context 'with network ipv6 vips' do
      let :params do
        default_params.merge({
          :network_vips              => {
            'internal_api' => { 'ip_address' => 'dead:beef::1', 'index' => 1 },
          }
        })
      end

      it {
        is_expected.to contain_class('keepalived')
        is_expected.to contain_keepalived__instance('55').with(
          :interface    => 'br-foo',
          :virtual_ips  => [ "dead:beef::1/64 dev br-foo" ],
          :state        => 'MASTER',
          :track_script => ['haproxy'],
          :priority     => 101
        )
      }
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      let (:platform_params) do
        case facts[:osfamily]
        when 'RedHat'
          { :name_is_process => 'false',
            :vrrp_script     => "/bin/sh -c 'test -S /var/lib/haproxy/stats && echo show info | socat /var/lib/haproxy/stats stdio'" }
        when 'Debian'
          { :name_is_process => 'true',
            :vrrp_script     => nil }
        end
      end

      it_behaves_like 'tripleo::keeplived'
    end
  end
end

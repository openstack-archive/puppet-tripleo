require 'spec_helper'

describe 'tripleo::haproxy::endpoint' do

  let(:title) { 'neutron' }

  let :pre_condition do
    'include haproxy'
  end

  let :params do {
    :public_virtual_ip         => '192.168.0.1',
    :internal_ip               => '10.0.0.1',
    :service_port              => 9696,
    :ip_addresses              => ['10.0.0.2', '10.0.0.3', '10.0.0.4'],
    :server_names              => ['controller1', 'controller2', 'controller3'],
    :public_ssl_port           => 19696,
    :member_options            => [ 'check', 'inter 2000', 'rise 2', 'fall 5' ],
    :haproxy_listen_bind_param => ['transparent'],
  }
  end

  shared_examples_for 'tripleo haproxy endpoint' do
    context 'with basic parameters to configure neutron binding' do
      it 'should configure haproxy' do
        is_expected.to contain_haproxy__listen('neutron').with(
          :collect_exported => false,
          :bind             => { "10.0.0.1:9696"    => ["transparent"],
                                 "192.168.0.1:9696" => ["transparent"] },
          :options          => {'option' => [],
                                'timeout client' => '90m',
                                'timeout server' => '90m',
                               },
        )
      end
    end

    context 'with dual-stack' do
      before :each do
        params.merge!({
          :public_virtual_ip => ['fd00:fd00:fd00:2000::14', '192.168.0.1'],
        })
      end
      it 'should configure haproxy' do
        is_expected.to contain_haproxy__listen('neutron').with(
          :collect_exported => false,
          :bind             => { "10.0.0.1:9696"                => ["transparent"],
                                 "fd00:fd00:fd00:2000::14:9696" => ["transparent"],
                                 "192.168.0.1:9696"             => ["transparent"] },
        )
      end
   end

    context 'with userlist' do
      before :each do
        params.merge!({
          :authorized_userlist => 'starwars',
        })
      end
      let :pre_condition do
        'include haproxy
        ::tripleo::haproxy::userlist {"starwars": users => ["leia password sister"]}
        '
      end
      it 'should configure an ACL' do
        is_expected.to compile.with_all_deps
        is_expected.to contain_haproxy__listen('neutron').with(
          :options => {
            'option'         => [],
            'timeout client' => '90m',
            'timeout server' => '90m',
            'acl'            => 'acl Authneutron http_auth(starwars)',
            'http-request'   => 'auth realm neutron if !Authneutron',
          }
        )
      end
    end

    context 'with frontend/backend sections' do
      before :each do
        params.merge!({
          :use_backend_syntax => true,
        })
      end
      it 'should configure haproxy' do
        is_expected.to compile.with_all_deps
        is_expected.to contain_haproxy__frontend('neutron').with(
          :collect_exported => false,
          :bind             => { "10.0.0.1:9696"    => ["transparent"],
                                 "192.168.0.1:9696" => ["transparent"] },
          :options          => {'option'          => [],
                                'timeout client'  => '90m',
                                'default_backend' => 'neutron_be',
                               },
        )
        is_expected.to contain_haproxy__backend('neutron_be').with(
          :options          => {'option'         => [],
                                'timeout server' => '90m',
                               },
        )
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(OSDefaults.get_facts({ :hostname => 'node.example.com' }))
      end

      it_behaves_like 'tripleo haproxy endpoint'
    end
  end
end

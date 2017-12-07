require 'spec_helper'

describe 'tripleo::haproxy::service_endpoints' do


  let :pre_condition do
    'include ::haproxy'
  end

  shared_examples_for 'tripleo haproxy service_endpoints' do
    context 'with basic parameters to configure neutron binding' do
      let(:title) { 'dynamic-stuff' }
      it 'should compile' do
        is_expected.to compile.with_all_deps
      end
      it 'should configure haproxy' do
        is_expected.to contain_tripleo__haproxy__endpoint('neutron')
      end
    end
    context 'with non-existent hiera entry' do
      let(:title) { 'non-existent' }
      it 'should compile' do
        is_expected.to compile.with_all_deps
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian',
        :hostname => 'myhost' }
    end

    it_configures 'tripleo haproxy service_endpoints'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat',
        :hostname => 'myhost' }
    end

    it_configures 'tripleo haproxy service_endpoints'
  end
end

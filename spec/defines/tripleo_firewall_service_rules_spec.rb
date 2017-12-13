require 'spec_helper'

describe 'tripleo::firewall::service_rules' do


  let :pre_condition do
    'include ::tripleo::firewall'
  end

  shared_examples_for 'tripleo firewall service rules' do
    context 'with existing service_rules' do
      let(:title) { 'dynamic-rules' }
      it 'should compile' do
        is_expected.to compile.with_all_deps
      end
      it 'should configure firewall' do
        is_expected.to contain_tripleo__firewall__rule('11-neutron')
      end
    end
    context 'with NON-existing service_rules' do
      let(:title) { 'no-rules' }
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

    it_configures 'tripleo firewall service rules'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat',
        :hostname => 'myhost' }
    end

    it_configures 'tripleo firewall service rules'
  end
end

require 'spec_helper'

describe 'tripleo::haproxy::service_endpoints' do


  let :pre_condition do
    'include haproxy'
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
    context 'with userlist' do
      let(:title) {'haproxy-basic-auth'}
      it 'should compile' do
        is_expected.to compile.with_all_deps
      end
      it 'should create haproxy endpoint' do
        is_expected.to contain_tripleo__haproxy__endpoint('starwars')
      end
      it 'should create userlist' do
        is_expected.to contain_tripleo__haproxy__userlist('starwars')
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      it_behaves_like 'tripleo haproxy service_endpoints'
    end
  end
end

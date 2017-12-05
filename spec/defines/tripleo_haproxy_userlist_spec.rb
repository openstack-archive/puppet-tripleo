require 'spec_helper'

describe 'tripleo::haproxy::userlist' do

  let(:title) { 'starwars' }

  let :pre_condition do
    'include ::haproxy'
  end

  let :params do {
    :groups => [
      'aldebaran users leia,luke',
      'deathstar users anakin,sith',
    ],
    :users  => [
      'leia insecure-password sister',
      'luke insecure-password jedi',
      'anakin insecure-password darthvador',
      'sith password $5$h9LsKUOeCr$UlD62CNEpuZQkGYdBoiFJLsM6TlXluRLBlhEnpjDdaC', # mkpasswd -m sha-256 darkSideOfTheForce
    ],
  }
  end

  shared_examples_for 'tripleo haproxy userlist' do
    context 'with basic parameters to configure neutron binding' do
      it 'should compile' do
        is_expected.to compile.with_all_deps
      end
      it 'should configure haproxy' do
        is_expected.to contain_haproxy__userlist('starwars').with(
          :users  => [
            'leia insecure-password sister',
            'luke insecure-password jedi',
            'anakin insecure-password darthvador',
            'sith password $5$h9LsKUOeCr$UlD62CNEpuZQkGYdBoiFJLsM6TlXluRLBlhEnpjDdaC',
          ],
          :groups => [
            'aldebaran users leia,luke',
            'deathstar users anakin,sith',
          ]
        )
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      it_behaves_like 'tripleo haproxy userlist'
    end
  end
end

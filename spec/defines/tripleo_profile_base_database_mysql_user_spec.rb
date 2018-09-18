require 'spec_helper'

describe 'tripleo::profile::base::database::mysql::user' do
  let(:title) { 'barbican' }

  let :pre_condition do
    'include mysql::server'
  end

  let :params do {
    :password      => 'secrete',
    :dbname        => 'barbican',
    :user          => 'barbican',
    :host          => '127.0.0.1',
    :charset       => 'utf8',
    :collate       => 'utf8_general_ci'
  }
  end

  shared_examples_for 'tripleo  profile  base  database  mysql  user' do
    context 'with basic parameters to configure barbican database' do
      it 'should configure mysql' do
        is_expected.to contain_openstacklib__db__mysql('barbican').with(
          :dbname         => params[:dbname],
          :user           => params[:user],
          :host           => params[:host],
          :charset        => params[:charset],
          :collate        => params[:collate],
        )
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      it_behaves_like 'tripleo  profile  base  database  mysql  user'
    end
  end
end

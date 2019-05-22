require 'spec_helper'

describe 'tripleo::config' do

  let :params do
    { }
  end

  shared_examples_for 'tripleo::config' do
    context 'with glance_api service' do
      before :each do
        params.merge!(
          :configs => { 'glance_api_config' => { 'DEFAULT' => { 'foo' => 'bar', 'foo2' => 'bar2' } } },
        )
      end
      it 'configures arbitrary glance-api configurations' do
        is_expected.to contain_glance_api_config('DEFAULT/foo').with_value('bar')
        is_expected.to contain_glance_api_config('DEFAULT/foo2').with_value('bar2')
      end
    end

    context 'with glance_api service and provider filter' do
      before :each do
        params.merge!(
          :configs   => { 'glance_api_config' => { 'DEFAULT' => { 'foo' => 'bar' } }, 'nova_config' => { 'DEFAULT' => { 'foo' => 'bar' } } },
          :providers => ['glance_api_config'],
        )
      end
      it 'configures arbitrary glance-api configurations without nova_config' do
        is_expected.to contain_glance_api_config('DEFAULT/foo').with_value('bar')
        is_expected.to_not contain_nova_config('DEFAULT/foo').with_value('bar')
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      it_behaves_like 'tripleo::config'
    end
  end
end

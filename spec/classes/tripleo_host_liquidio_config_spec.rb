require 'spec_helper'

describe 'tripleo::host::liquidio::config' do

  let :params do
    { :liquidio_config => {
        'DEFAULT/foo' => { 'value'  => 'fooValue' },
        'DEFAULT/bar' => { 'value'  => 'barValue' },
        'DEFAULT/baz' => { 'ensure' => 'absent' }
      },
    }
  end

  it 'configures arbitrary liquidio configurations' do
    is_expected.to contain_liquidio_config('DEFAULT/foo').with_value('fooValue')
    is_expected.to contain_liquidio_config('DEFAULT/bar').with_value('barValue')
    is_expected.to contain_liquidio_config('DEFAULT/baz').with_ensure('absent')
  end

end

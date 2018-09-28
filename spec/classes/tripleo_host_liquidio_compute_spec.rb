describe 'tripleo::host::liquidio::compute' do

  shared_examples_for 'tripleo::host::liquidio::compute' do

    let :params do
      {
        :vf_nums      => '4',
        :configure_mode => 'ml2-odl',
        :bonding_options => 'active-backup',
        :enable_bonding => true,
        :provider_mappings => 'datacentre:eth1',
      }
    end

    it 'configures parameters' do
      is_expected.to contain_liquidio_config('main/vf_nums').with_value('4')
      is_expected.to contain_liquidio_config('main/configure_mode').with_value('ml2-odl')
      is_expected.to contain_liquidio_config('main/bonding_options').with_value('')
      is_expected.to contain_liquidio_config('main/enable_bonding').with_value(true)
      is_expected.to contain_liquidio_config('main/provider_mappings').with_value('datacentre:eth1')
    end
  end
end
   

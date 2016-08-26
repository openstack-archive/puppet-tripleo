require 'spec_helper'

describe 'tripleo::host::sriov' do

  shared_examples_for 'sriov vfs configuration for Red Hat distributions' do

    let :facts do
      {
        :osfamily                  => 'RedHat',
        :operatingsystemmajrelease => 7,
      }
    end

    let :params do
      {:number_of_vfs => []}
    end

    it 'does not configure numvfs by default' do
      is_expected.not_to contain_sriov_vf_config([])
    end

    context 'when number_of_vfs is configured' do
      let :params do
        {:number_of_vfs => ['eth0:4','eth1:5']}
      end

      it 'configures numvfs' do
        is_expected.to contain_sriov_vf_config('eth0:4').with( :ensure => 'present' )
        is_expected.to contain_sriov_vf_config('eth1:5').with( :ensure => 'present')
        is_expected.to contain_tripleo__host__sriov__numvfs_persistence('persistent_numvfs').with(
          :vf_defs        => ['eth0:4','eth1:5'],
          :content_string => "#!/bin/bash\n"
        )
      end
    end
  end

  it_configures 'sriov vfs configuration for Red Hat distributions'
end

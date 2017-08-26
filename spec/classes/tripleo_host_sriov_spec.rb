require 'spec_helper'

describe 'tripleo::host::sriov' do

  shared_examples_for 'tripleo::host::sriov' do
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
        is_expected.to contain_sriov_vf_config('eth1:5').with( :ensure => 'present' )
        is_expected.to contain_tripleo__host__sriov__numvfs_persistence('persistent_numvfs').with(
          :vf_defs        => ['eth0:4','eth1:5'],
          :content_string => "#!/bin/bash\n"
        )
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      it_behaves_like 'tripleo::host::sriov'
    end
  end
end

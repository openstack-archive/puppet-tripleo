require 'puppet'
require 'spec_helper'
require 'puppet/provider/sriov_vf_config/numvfs'

provider_class = Puppet::Type.type(:sriov_vf_config).
  provider(:numvfs)

describe provider_class do

  let(:test_cfg_path) { "/tmp/test-ifup-local.txt" }
  let :numvfs_conf do
    {
      :name   => 'eth0:10',
      :ensure => 'present',
    }
  end

  describe 'when setting the attributes' do
    let :resource do
      Puppet::Type::Sriov_vf_config.new(numvfs_conf)
    end

    let :provider do
      provider_class.new(resource)
    end

    it 'should return the correct interface name' do
      expect(provider.sriov_get_interface).to eql('eth0')
    end

    it 'should return the correct numvfs value' do
      expect(provider.sriov_numvfs_value).to eql(10)
    end

    it 'should return path of the file to enable vfs' do
      expect(provider.sriov_numvfs_path).to eql('/sys/class/net/eth0/device/sriov_numvfs')
    end
  end

end

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
    it 'should return ovs mode: legacy' do
      expect(provider.ovs_mode).to eql('legacy')
    end
  end

  let :numvfs_conf_switchdev do
    {
      :name   => 'eth1:12:switchdev',
      :ensure => 'present',
    }
  end

  describe 'when setting the attributes' do
    let :resource_switchdev do
      Puppet::Type::Sriov_vf_config.new(numvfs_conf_switchdev)
    end

    let :provider_switchdev do
      provider_class.new(resource_switchdev)
    end

    it 'should return the correct interface name' do
      expect(provider_switchdev.sriov_get_interface).to eql('eth1')
    end

    it 'should return the correct numvfs value' do
      expect(provider_switchdev.sriov_numvfs_value).to eql(12)
    end

    it 'should return path of the file to enable vfs' do
      expect(provider_switchdev.sriov_numvfs_path).to eql('/sys/class/net/eth1/device/sriov_numvfs')
    end

    it 'should return path of the vendor file' do
      expect(provider_switchdev.vendor_path).to eql('/sys/class/net/eth1/device/vendor')
    end

    it 'should return ovs mode: switchdev' do
      expect(provider_switchdev.ovs_mode).to eql('switchdev')
    end
  end

  let :numvfs_conf_legacy do
    {
      :name   => 'eth2:14:legacy',
      :ensure => 'present',
    }
  end

  describe 'when setting the attributes' do
    let :resource_legacy do
      Puppet::Type::Sriov_vf_config.new(numvfs_conf_legacy)
    end

    let :provider_legacy do
      provider_class.new(resource_legacy)
    end

    it 'should return the correct interface name' do
      expect(provider_legacy.sriov_get_interface).to eql('eth2')
    end

    it 'should return the correct numvfs value' do
      expect(provider_legacy.sriov_numvfs_value).to eql(14)
    end

    it 'should return path of the file to enable vfs' do
      expect(provider_legacy.sriov_numvfs_path).to eql('/sys/class/net/eth2/device/sriov_numvfs')
    end

    it 'should return path of the vendor file' do
      expect(provider_legacy.vendor_path).to eql('/sys/class/net/eth2/device/vendor')
    end

    it 'should return ovs mode: legacy' do
      expect(provider_legacy.ovs_mode).to eql('legacy')
    end
  end

end

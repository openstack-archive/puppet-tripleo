require 'puppet'
require 'puppet/type/sriov_vf_config'

describe 'Puppet::Type.type(:sriov_vf_config)' do
  it 'should allow name to be passed' do
    expect{Puppet::Type.type(:sriov_vf_config).new(
      :name   => 'eth0:10',
      :ensure => 'present'
    )}.not_to raise_error
  end
  it 'should allow name to be passed with -' do
    expect{Puppet::Type.type(:sriov_vf_config).new(
      :name   => 'eth-0:10',
      :ensure => 'present'
    )}.not_to raise_error
  end
  it 'should allow name to be passed with _' do
    expect{Puppet::Type.type(:sriov_vf_config).new(
      :name   => 'eth_0:10',
      :ensure => 'present'
    )}.not_to raise_error
  end
  it 'should throw error for invalid format' do
    expect{Puppet::Type.type(:sriov_vf_config).new(
      :name   => 'eth0',
      :ensure => 'present'
    )}.to raise_error(Puppet::ResourceError)
  end
  it 'should throw error for invalid format without interface name' do
    expect{Puppet::Type.type(:sriov_vf_config).new(
      :name   => ':9',
      :ensure => 'present'
    )}.to raise_error(Puppet::ResourceError)
  end
  it 'should throw error for invalid format for numvfs' do
    expect{Puppet::Type.type(:sriov_vf_config).new(
      :name   => 'eth8:none',
      :ensure => 'present'
    )}.to raise_error(Puppet::ResourceError)
  end
  it 'should throw error for invalid format without numvfs' do
    expect{Puppet::Type.type(:sriov_vf_config).new(
      :name   => 'eth0:',
      :ensure => 'present'
    )}.to raise_error(Puppet::ResourceError)
  end
end

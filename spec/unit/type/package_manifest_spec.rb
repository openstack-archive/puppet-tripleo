
require 'puppet'
require 'puppet/type/package_manifest'

describe 'Puppet::Type.type(:package_manifest)' do
  before :each do
    @manifest = Puppet::Type.type(:package_manifest).new(
        :path => '/tmp/test_package_manifest.txt', :ensure => 'present'
    )
  end

  it 'should require a path' do
    expect {
      Puppet::Type.type(:package_manifest).new({})
  }.to raise_error Puppet::Error
  end

  it 'should not require a value when ensure is absent' do
    Puppet::Type.type(:package_manifest).new(
        :path => '/tmp/test_package_manifest.txt', :ensure => :absent
    )
  end

  it 'should accept valid ensure values' do
    @manifest[:ensure] = :present
    expect(@manifest[:ensure]).to eq(:present)
    @manifest[:ensure] = :absent
    expect(@manifest[:ensure]).to eq(:absent)
  end

  it 'should not accept invalid ensure values' do
    expect {
      @manifest[:ensure] = :latest
    }.to raise_error(Puppet::Error, /Invalid value/)
  end

end

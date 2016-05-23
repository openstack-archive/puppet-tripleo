require 'spec_helper'
require 'puppet'

# puppet 4.0 call_function() has no visibility of 3.x functions and will fail anyway
unless Puppet.version =~ /^4\.0/
  describe 'lookup_hiera_hash' do
    # working version
    it { should run.with_params('my_hash', 'network').and_return('127.0.0.1') }
    # raise if key does not exist
    it { should run.with_params('my_hash', 'not_network').and_raise_error(Puppet::ParseError) }
    # raise if hash value returned by hiera is not a hash
    it { should run.with_params('not_hash', 'key').and_raise_error(Puppet::ParseError) }
    # raise if arguments are not two
    it { should run.with_params('hash', 'key', 'unexpected').and_raise_error(ArgumentError) }
    it { should run.with_params('hash').and_raise_error(ArgumentError) }
    # raise if arguments are not strings
    it { should run.with_params({}, 'key').and_raise_error(Puppet::ParseError) }
    it { should run.with_params('hash', true).and_raise_error(Puppet::ParseError) }
  end
end

require 'spec_helper'
require 'puppet'

describe 'ip_to_erl_format' do
  it { should run.with_params('192.168.2.1').and_return('{192,168,2,1}') }
  it { should run.with_params('0.0.0.0').and_return('{0,0,0,0}') }
  it { should run.with_params('5a40:79cf:8251:5dc5:1624:3c03:3c04:9ba8').and_return('{23104,31183,33361,24005,5668,15363,15364,39848}') }
  it { should run.with_params('fe80::204:acff:fe17:bf38').and_return('{65152,0,0,0,516,44287,65047,48952}') }
  it { should run.with_params('::1:2').and_return('{0,0,0,0,0,0,1,2}') }
  it { should run.with_params('192.256.0.0').and_raise_error(IPAddr::InvalidAddressError) }
end

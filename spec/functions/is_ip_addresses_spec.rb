require 'spec_helper'
require 'puppet'

describe 'is_ip_addresses' do
  it { should run.with_params('192.168.2.1').and_return(true) }
  it { should run.with_params('::1').and_return(true) }
  it { should run.with_params('192.168.2.256').and_return(false) }
  it { should run.with_params(['192.168.2.1']).and_return(true) }
  it { should run.with_params(['192.168.2.1', '5a40:79cf:8251:5dc5:1624:3c03:3c04:9ba8', 'fe80::204:acff:fe17:bf38', '::1:2']).and_return(true) }
  it { should run.with_params(['192.168.2.1', 'a.b.c.d']).and_return(false) }
  it { should run.with_params(['c.d.d.e', 'a.b.c.d']).and_return(false) }
end

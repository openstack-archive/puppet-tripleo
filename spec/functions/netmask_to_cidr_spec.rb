require 'spec_helper'
require 'puppet'

describe 'netmask_to_cidr' do
  it { should run.with_params('255.255.255.0').and_return(24) }
end

require 'spec_helper'

describe 'extract_id' do
  it { should run.with_params('127.0.0.1', '127.0.0.1').and_return(1) }
  it { should run.with_params(["127.0.0.1", "127.0.0.2"], "127.0.0.2").and_return(2) }
end

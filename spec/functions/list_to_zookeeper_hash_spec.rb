require 'spec_helper'

describe 'list_to_zookeeper_hash' do
  it {
    should run.with_params('127.0.0.1').and_return([
      { 'ip' => '127.0.0.1', 'port' => 2181 }
    ])
  }
  it {
    should run.with_params(['127.0.0.1', '127.0.0.2']).and_return([
      { 'ip' => '127.0.0.1', 'port' => 2181 },
      { 'ip' => '127.0.0.2', 'port' => 2181 }
    ])
  }
end

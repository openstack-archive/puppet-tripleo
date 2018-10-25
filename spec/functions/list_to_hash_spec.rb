require 'spec_helper'

describe 'list_to_hash' do
  it {
    should run.with_params(['192.168.0.1:5000', '192.168.0.2:5000'], ['transparent'])
      .and_return({
      '192.168.0.1:5000' => ['transparent'],
      '192.168.0.2:5000' => ['transparent'],
    })
  }
end

require 'spec_helper'

describe 'noop_resource' do
  it {
    should run.with_params('nova_config').and_return(true)
  }
  context 'noop a puppet resource' do
    let (:pre_condition) {
      'noop_resource("file")
      file { "bar": path => "/baz" }'
    }
    it {
      expect(-> {catalogue}).to contain_file('bar')
    }
  end
end

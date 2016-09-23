require 'puppetlabs_spec_helper/module_spec_helper'
require 'shared_examples'
require 'rspec-puppet-facts'
include RspecPuppetFacts

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

RSpec.configure do |c|
  c.alias_it_should_behave_like_to :it_configures, 'configures'
  c.alias_it_should_behave_like_to :it_raises, 'raises'
  c.hiera_config = File.join(fixture_path, 'hiera.yaml')
  c.module_path = File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, 'manifests')

  # custom global facts for all rspec tests
  add_custom_fact :concat_basedir, '/var/lib/puppet/concat'
end

at_exit { RSpec::Puppet::Coverage.report! }

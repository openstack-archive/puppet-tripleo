# Load libraries from openstacklib here to simulate how they live together in a real puppet run (for provider unit tests)
$LOAD_PATH.push(File.join(File.dirname(__FILE__), 'fixtures', 'modules', 'openstacklib', 'lib'))
require 'puppetlabs_spec_helper/module_spec_helper'
require 'shared_examples'

require 'puppet-openstack_spec_helper/defaults'
require 'rspec-puppet-facts'
include RspecPuppetFacts

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

RSpec.configure do |c|
  c.alias_it_should_behave_like_to :it_configures, 'configures'
  c.alias_it_should_behave_like_to :it_raises, 'raises'

  c.hiera_config = File.join(fixture_path, 'hiera.yaml')
  c.module_path = File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, 'manifests')

  c.default_facts = {
    :kernel         => 'Linux',
    :concat_basedir => '/var/lib/puppet/concat',
    :memorysize     => '1000 MB',
    :processorcount => '1',
    :puppetversion  => '3.7.3',
    :uniqueid       => '123'
  }
end

at_exit { RSpec::Puppet::Coverage.report! }

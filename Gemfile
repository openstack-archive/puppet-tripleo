source 'https://rubygems.org'

group :development, :test do
  gem 'puppetlabs_spec_helper', :require => false
  gem 'puppet-lint'
  gem 'puppet-lint-param-docs', '1.1.0'
  gem 'metadata-json-lint'
  gem 'rake', '10.1.1'
  gem 'puppet-syntax'
  gem 'rspec-puppet', :git => 'https://github.com/rodjek/rspec-puppet.git'
  gem 'rspec'
  gem 'json'
  gem 'webmock'
  gem 'r10k'
  gem 'librarian-puppet-simple', '~> 0.0.3'
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end

# vim:ft=ruby

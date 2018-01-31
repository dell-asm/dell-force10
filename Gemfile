source 'https://rubygems.org'

group :development, :test do
  gem 'rake'
  gem 'rspec', '~>3.4.0', :require => false
  gem 'puppetlabs_spec_helper', '0.4.1', :require => false
  gem 'json_pure', '2.0.1'
  if puppetversion = ENV['PUPPET_GEM_VERSION']
    gem 'puppet', puppetversion
  else
    gem 'puppet', '3.6.2'
  end
end


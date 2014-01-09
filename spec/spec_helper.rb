require 'rspec-puppet'
require 'spec_helper'
require 'yaml'
require 'puppet/provider/dell_ftos'
require 'puppet/util/network_device/dell_ftos/device'
require 'puppet/util/network_device/base_ftos'
require 'rspec/mocks'
require 'puppet/provider/dell_ftos'
require 'rspec/expectations'
require 'puppetlabs_spec_helper/module_spec_helper'

module_path = File.expand_path(File.join(File.dirname(__FILE__), '..'))
$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..','lib'))

# Don't want puppet getting the command line arguments for rake or autotest
ARGV.clear

RSpec.configure do |c|
  c.module_path = module_path
  c.manifest_dir = File.join(module_path, 'manifests')

  if Puppet::Util::Platform.windows?
    c.output_stream = $stdout
    c.error_stream = $stderr

    c.formatters.each do |f|
      if not f.instance_variable_get(:@output).kind_of?(::File)
        f.instance_variable_set(:@output, $stdout)
      end
    end
  end
end

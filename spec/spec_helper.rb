require 'rspec-puppet'
require 'puppet_x/force10/model'
require 'puppet_x/force10/model/base'
require 'puppet_x/force10/transport'
require 'puppet_x/force10/transport/ssh'

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

module PuppetSpec
  FIXTURE_DIR = File.join(dir = File.expand_path(File.dirname(__FILE__)), "fixtures") unless defined?(FIXTURE_DIR)
end

RSpec.configure do |c|
  c.module_path = File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, 'manifests')
  c.environmentpath = File.join(Dir.pwd, 'spec')
end

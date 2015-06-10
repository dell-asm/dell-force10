#VLAN base class
#Compares all registered params IS and SHOULD values and so performs update operations on properties
require 'puppet_x/force10/model/base'

class PuppetX::Force10::Model::Feature < PuppetX::Force10::Model::Base

  attr_reader :params, :name
  def initialize(transport, facts, options)
    super(transport, facts)
    # Initialize some defaults
    @params         ||= {}
    @name           = options[:name] if options.key? :name

    # Register all needed Modules based on the availiable Facts
    register_modules
  end

  def update(is = {}, should = {})
    return unless configuration_changed?(is, should, :keep_ensure => true)
    missing_commands = [is.keys, should.keys].flatten.uniq.sort - @params.keys.flatten.uniq.sort
    missing_commands.delete(:ensure)
    raise Puppet::Error, "Undefined commands for #{missing_commands.join(', ')}" unless missing_commands.empty?
    [is.keys, should.keys].flatten.uniq.sort.each do |property|
      next if property == :acl_type
      next if should[property] == :undef
      @params[property].value = :absent if should[property] == :absent || should[property].nil?
      @params[property].value = should[property] unless should[property] == :absent || should[property].nil?
    end
    before_update
    perform_update(is, should)
    after_update
  end

  def perform_update(is, should)
    features = []
    case @params[:ensure].value
    when :present
      Puppet.debug("should: #{should}")
      response = transport.command("feature #{name}", :prompt => /\(conf\)#\s?\z/n)
      raise(Exception,"Command failed with response: #{response}") if response.include?('Error:')
      transport.command("exit")
    when :absent
      transport.command("no feature #{name}", :prompt => /\(conf\)#\s?\z/n)
      transport.command("exit")
    else
      Puppet.debug("No value given for ensure")
    end
  end

  def mod_path_base
    return 'puppet_x/force10/model/feature'
  end

  def mod_const_base
    return PuppetX::Force10::Model::Feature
  end

  def register_modules
    register_new_module(:base)
  end
end

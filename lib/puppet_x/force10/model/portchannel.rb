#This class has the responsibility of creating and deleting the portchannel resource
require 'puppet_x/force10/model/base'

class PuppetX::Force10::Model::Portchannel < PuppetX::Force10::Model::Base

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
    params_to_update = []
    PuppetX::Force10::Sorter.new(@params).tsort.each do |param|
      # We dont want to change undefined values
      next if should[param.name] == :undef || should[param.name].nil?
      params_to_update << param unless is[param.name] == should[param.name]
    end
    before_update(params_to_update)
    params_to_update.each do |param|
      param.update(@transport, is[param.name])
    end
    after_update
  end

  def perform_update(is, should)
    case @params[:ensure].value
    when :present
      transport.command("interface port-channel #{name}", :prompt => /\(conf-if-po-#{name}\)#\s?\z/n)
      PuppetX::Force10::Sorter.new(@params).tsort.each do |param|
        # We dont want to change undefined values
        next if should[param.name] == :undef || should[param.name].nil?
        # Skip the ensure property
        next if param.name == :ensure
        param.update(@transport, is[param.name]) unless is[param.name] == should[param.name]
      end
    when :absent
      transport.command("no interface port-channel #{name}")
	else
	  Puppet.debug("No value given for ensure")
    end
  end

  def before_update(params_to_update=[])
    super
    full_name = "po %s" % name

    # Need to remove portchannel from all vlans if we want to change the portmode
    if params_to_update.collect{|param| param.name}.include?(:portmode)
      Puppet.info("Removing all vlans for %s so portmode can be set." % full_name)
      transport.command("interface range vlan 1-4094")
      transport.command("no tagged %s" % full_name)
      transport.command("no untagged %s" % full_name)
      transport.command("exit")
    end
    transport.command("interface %s" % full_name, :prompt => /\(conf-if-\S+\)#\z/n)
  end

  def mod_path_base
    'puppet_x/force10/model/portchannel'
  end

  def mod_const_base
    PuppetX::Force10::Model::Portchannel
  end

  def param_class
    PuppetX::Force10::Model::ScopedValue
  end

  def register_modules
    register_new_module(:base)
  end
end

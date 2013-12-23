require 'puppet/util/network_device/ipcalc'
require 'puppet/util/network_device/dell_ftos/model'
require 'puppet/util/network_device/dell_ftos/model/base'
require 'puppet/util/network_device/dell_ftos/model/scoped_value'

class Puppet::Util::NetworkDevice::Dell_ftos::Model::Interface < Puppet::Util::NetworkDevice::Dell_ftos::Model::Base

  attr_reader :params, :name
  def initialize(transport, facts, options)
    super(transport, facts)
    # Initialize some defaults
    @params         ||= {}
    @name           = options[:name] if options.key? :name

    # Register all needed Modules based on the availiable Facts
    register_modules
  end

  def mod_path_base
    return 'puppet/util/network_device/dell_ftos/model/interface'
  end

  def mod_const_base
    return Puppet::Util::NetworkDevice::Dell_ftos::Model::Interface
  end

  def param_class
    return Puppet::Util::NetworkDevice::Dell_ftos::Model::ScopedValue
  end

  def register_modules
    register_new_module(:base)
  end

  def before_update

    transport.command("show interface #{@name}")do |out|
      if out =~/Error:\s*(.*)/
        Puppet.debug "errror msg ::::#{$1}"
        raise "interface does not exists provide the valid interface"
      end
    end

    super

    transport.command("interface #{@name}", :prompt => /\(conf-if-\S+\)#\z/n)
  end

  def after_update
    transport.command("exit")
    super
  end

end

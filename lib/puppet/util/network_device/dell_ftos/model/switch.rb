#This class represents the switch model which contains the switch resources. 
require 'puppet/util/network_device/dell_ftos/model'
require 'puppet/util/network_device/dell_ftos/model/vlan'
require 'puppet/util/network_device/dell_ftos/model/base'
require 'puppet/util/network_device/dell_ftos/model/generic_value'
require 'puppet/util/network_device/dell_ftos/model/interface'
require 'puppet/util/network_device/dell_ftos/model/portchannel'
require 'puppet/util/network_device/dell_ftos/model/feature'
require 'puppet/util/network_device/dell_ftos/model/zone'

class Puppet::Util::NetworkDevice::Dell_ftos::Model::Switch < Puppet::Util::NetworkDevice::Dell_ftos::Model::Base

  attr_reader :params, :vlans
  def initialize(transport, facts)
    super
    # Initialize some defaults
    @params         ||= {}
    @vlans          ||= []
    @portchannels   ||= []
    @features       ||= []
    # Register all needed Modules based on the availiable Facts
    register_modules
  end

  def mod_path_base
    return 'puppet/util/network_device/dell_ftos/model/switch'
  end

  def mod_const_base
    return Puppet::Util::NetworkDevice::Dell_ftos::Model::Switch
  end

  def param_class
    return Puppet::Util::NetworkDevice::Dell_ftos::Model::GenericValue
  end

  def register_modules
    register_new_module(:base)
  end

  def skip_params_to_hash
    [ :snmp, :archive ]
  end

  def interface(name)
    int = params[:interfaces].value.find { |int| int.name == name }
    int.evaluate_new_params
    return int
  end

  [
    :vlan,
    :interface,
    :portchannel,
    :feature,
    :zone
  ].each do |key|
    define_method key.to_s do |name|
      grp = params[key].value.find { |resourcegrp| resourcegrp.name == name }
      if grp.nil?
        grp = Puppet::Util::NetworkDevice::Dell_ftos::Model.const_get(key.to_s.capitalize).new(transport, facts, {:name => name})
        params[key].value << grp
      end
      grp.evaluate_new_params
      return grp
    end
  end

end

require 'puppet/util/network_device/dell_ftos/model'
require 'puppet/util/network_device/dell_ftos/model/model_value'
require 'puppet/util/network_device/dell_ftos/model/switch'
require 'puppet/util/network_device/dell_ftos/model/interface'

module Puppet::Util::NetworkDevice::Dell_ftos::Model::Switch::Base

  def self.register(base)

    base.register_model(:vlan, Puppet::Util::NetworkDevice::Dell_ftos::Model::Vlan, /^(\d+)\s\S+/, 'sh vlan brief')
	base.register_model(:interface, Puppet::Util::NetworkDevice::Dell_ftos::Model::Interface, /^interface\s+(\S+)\r*$/, 'show running-config')	
	base.register_model(:portchannel, Puppet::Util::NetworkDevice::Dell_ftos::Model::Portchannel, /^L*\s*(\d+)\s+.*/, 'show interfaces port-channel brief')

    if base.facts && base.facts['canonicalized_hardwaremodel'] == 'c4500'
      base.register_new_module('c4500', 'hardware')
    end

    if base.facts && base.facts['canonicalized_hardwaremodel'] == 'c2960'
      base.register_new_module('c2960', 'hardware')
    end

  end
end

require 'puppet/util/network_device/dell_ftos/model'
require 'puppet/util/network_device/dell_ftos/model/model_value'
require 'puppet/util/network_device/dell_ftos/model/switch'
require 'puppet/util/network_device/dell_ftos/model/interface'

module Puppet::Util::NetworkDevice::Dell_ftos::Model::Switch::Base
  def self.register(base)

    base.register_model(:vlan, Puppet::Util::NetworkDevice::Dell_ftos::Model::Vlan, /^(\d+)\s\S+/, 'show vlan brief')
    base.register_model(:interface, Puppet::Util::NetworkDevice::Dell_ftos::Model::Interface, /^interface\s+(\S+)\r*$/, 'show running-config')
    base.register_model(:portchannel, Puppet::Util::NetworkDevice::Dell_ftos::Model::Portchannel, /^L*\s*(\d+)\s+.*/, 'show interfaces port-channel brief')
    base.register_model(:feature, Puppet::Util::NetworkDevice::Dell_ftos::Model::Feature, /feature*\s*(\S+)/, 'show running-config')
    base.register_model(:zone, Puppet::Util::NetworkDevice::Dell_ftos::Model::Zone, /^(\S+)\s+/, 'show fc zone')
  end
end

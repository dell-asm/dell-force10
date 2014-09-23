require 'puppet/util/network_device/dell_ftos/model'
require 'puppet/util/network_device/dell_ftos/model/model_value'
require 'puppet/util/network_device/dell_ftos/model/switch'
require 'puppet/util/network_device/dell_ftos/model/interface'
require 'puppet/util/network_device/dell_ftos/model/feature'
require 'puppet/util/network_device/dell_ftos/model/zone'
require 'puppet/util/network_device/dell_ftos/model/zoneset'
require 'puppet/util/network_device/dell_ftos/model/fcoemap'
require 'puppet/util/network_device/dell_ftos/model/dcbmap'
require 'puppet/util/network_device/dell_ftos/model/uplinkstategroup'
require 'puppet/util/network_device/dell_ftos/model/quadmode'

module Puppet::Util::NetworkDevice::Dell_ftos::Model::Switch::Base
  def self.register(base)

    base.register_model(:vlan, Puppet::Util::NetworkDevice::Dell_ftos::Model::Vlan, /^(\d+)\s\S+/, 'show vlan brief')
    base.register_model(:interface, Puppet::Util::NetworkDevice::Dell_ftos::Model::Interface, /^interface\s+(\S+)\r*$/, 'show running-config')
    base.register_model(:portchannel, Puppet::Util::NetworkDevice::Dell_ftos::Model::Portchannel, /^L*\s*(\d+)\s+.*/, 'show interfaces port-channel brief')
    base.register_model(:feature, Puppet::Util::NetworkDevice::Dell_ftos::Model::Feature, /feature*\s*(\S+)/, 'show running-config')
    base.register_model(:zone, Puppet::Util::NetworkDevice::Dell_ftos::Model::Zone, /^(\S+)\s+/, 'show fc zone')
    base.register_model(:zoneset, Puppet::Util::NetworkDevice::Dell_ftos::Model::Zoneset, /^(\S+)\s+/, 'show fc zoneset')
    base.register_model(:fcoemap, Puppet::Util::NetworkDevice::Dell_ftos::Model::Fcoemap, /^fcoe-map\s+(\S+)/, 'show running-config')
    base.register_model(:dcbmap, Puppet::Util::NetworkDevice::Dell_ftos::Model::Dcbmap, /^dcb-map\s+(\S+)/, 'show running-config')
    base.register_model(:uplinkstategroup, Puppet::Util::NetworkDevice::Dell_ftos::Model::Uplinkstategroup, /^uplink-state-group\s+(\S+)/, 'show running-config')
    base.register_model(:quadmode, Puppet::Util::NetworkDevice::Dell_ftos::Model::Quadmode, /^stack-unit 0 port\s+(\d+)/, 'show running-config | grep quad')
  end
end

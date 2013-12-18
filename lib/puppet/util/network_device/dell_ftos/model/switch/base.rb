require 'puppet/util/network_device/dell_ftos/model'
require 'puppet/util/network_device/dell_ftos/model/model_value'
require 'puppet/util/network_device/dell_ftos/model/switch'

module Puppet::Util::NetworkDevice::Dell_ftos::Model::Switch::Base

  def self.register(base)

    base.register_model(:vlan, Puppet::Util::NetworkDevice::Dell_ftos::Model::Vlan, /^(\d+)\s\S+/, 'sh vlan brief')

    if base.facts && base.facts['canonicalized_hardwaremodel'] == 'c4500'
      base.register_new_module('c4500', 'hardware')
    end

    if base.facts && base.facts['canonicalized_hardwaremodel'] == 'c2960'
      base.register_new_module('c2960', 'hardware')
    end

  end
end

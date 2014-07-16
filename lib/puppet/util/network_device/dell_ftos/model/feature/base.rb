#Feature model
#Registers all the properties as parameters and so apply required changes

require 'puppet/util/network_device/dell_ftos/model'
require 'puppet/util/network_device/dell_ftos/model/vlan'

module Puppet::Util::NetworkDevice::Dell_ftos::Model::Feature::Base
  def self.ifprop(base, param, base_command = param, &block)
    base.register_scoped param, /^(feature\s+(\S+))/m do
      cmd 'show running-config'
      match /^\s*#{base_command}\s+(.*?)\s*$/
      add do |transport, value|
        transport.command("#{base_command} #{value}")
      end
      remove do |transport, old_value|
        transport.command("no #{base_command} #{old_value}")
      end
      evaluate(&block) if block
    end
  end

  def self.register(base)
    txt = ''
    ifprop(base, :ensure) do
      match do |txt|
        unless txt.nil?
          txt.match(/\S+/) ? :present : :absent
        else
          :absent
        end
      end
      default :absent
      add { |*_| }
      remove { |*_| }
    end
    
    ifprop(base, :features) do
      match /^feature\s+(\S+)$/m
      add do |transport, value|
        transport.command("feature #{value}")
      end
      remove { |*_| }
    end


  end

end

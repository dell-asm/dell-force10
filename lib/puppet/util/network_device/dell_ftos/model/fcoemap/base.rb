#FCOE MAP model
#Registers all the properties as parameters and so apply required changes

require 'puppet/util/network_device/dell_ftos/model'
require 'puppet/util/network_device/dell_ftos/model/fcoemap'

module Puppet::Util::NetworkDevice::Dell_ftos::Model::Fcoemap::Base
  def self.ifprop(base, param, base_command = param, &block)
    base.register_scoped param, /^(fcoe-map\s+(\S+).*?)^!/m do
      cmd 'sh run'
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

    base.register_scoped :fcoe_map, /^(fcoe-map\s+(\S+).*?)^!/m do
      match /^\s*fc-map\s+(.*?)\s*$/
      cmd 'sh run'
      add do |transport, value|
        if value != ''
          transport.command("fc-map #{value}")
        end
      end
      remove { |*_| }
    end
    
    base.register_scoped :fcoe_vlan, /^(fcoe-map\s+(\S+).*?)^!/m do
      match /^\s*fabric-id\s+(.*?)\s*/
      cmd 'sh run'
      add do |transport, value|
        if value != ''
          transport.command("fabric-id #{value} vlan #{value}")
        end
      end
      remove { |*_| }
    end
    
    base.register_scoped :fabric_type, /^(fcoe-map\s+(\S+).*?)^!/m do
      match /^\s*fabric_type\s+(.*?)/
      cmd 'sh run'
      add do |transport, value|
        if value != ''
          transport.command("fabric-type #{value}")
        end
      end
      remove { |*_| }
    end
  end

end

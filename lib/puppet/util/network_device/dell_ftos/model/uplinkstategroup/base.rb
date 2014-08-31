#uplink-state-group model
#Registers all the properties as parameters and so apply required changes

require 'puppet/util/network_device/dell_ftos/model'
require 'puppet/util/network_device/dell_ftos/model/uplinkstategroup'

module Puppet::Util::NetworkDevice::Dell_ftos::Model::Uplinkstategroup::Base
  def self.ifprop(base, param, base_command = param, &block)
    base.register_scoped param, /^(uplink-state-group\s+(\S+).*?)^!/m do
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

    base.register_scoped :downstream_interface, /^(downstream\s+TenGigabitEthernet\s+(\S+).*?)^!/m do
      match /^\s*downstream\s+TenGigabitEthernet\s+(.*?)\s*$/
      cmd 'sh run'
      add do |transport, value|
        if value != ''
          transport.command("downstream #{value}")
        end
      end
      remove { |*_| }
    end
    
    base.register_scoped :upstream_interface, /^(upstream\s+(TenGigabitEthernet|Port-channel)\s+(\S+).*?)^!/m do
      match /^\s*downstream\s+(TenGigabitEthernet|Port-channel)\s+(.*?)\s*$/
      cmd 'sh run'
      add do |transport, value|
        if value != ''
          transport.command("upstream #{value}")
        end
      end
      remove { |*_| }
    end
    
    base.register_scoped :downstream_property, /^(downstream\s+(auto-recover|disable).*?)^!/m do
      match /^\s*downstream\s+(auto-recover|disable)\s*/
      cmd 'sh run'
      add do |transport, value|
        if value != ''
          transport.command("downstream #{value}")
        end
      end
      remove { |*_| }
    end
  end

end

require 'puppet/util/network_device/dell_ftos/model'
require 'puppet/util/network_device/dell_ftos/model/vlan'

module Puppet::Util::NetworkDevice::Dell_ftos::Model::Vlan::Base
  
  def self.ifprop(base, param, base_command = param, &block)
    base.register_scoped param, /^(interface Vlan\s+(\S+).*?)^!/m do
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
	
    ifprop(base, :desc) do      
      add do |transport, value|
        transport.command("name #{value}")
      end
      remove { |*_| }
    end

	
	base.register_scoped :tagged_tengigabitethernet, /^(interface Vlan\s+(\S+).*?)^!/m do      
      match /^\s*tagged TenGigabitEthernet\s+(.*?)\s*$/
	  cmd 'sh run'
      add do |transport, value|        
        transport.command("tagged TenGigabitEthernet #{value}")
      end
      remove do |transport, old_value|        
        transport.command("no tagged TenGigabitEthernet #{old_value}")
      end      
    end
	
	base.register_scoped :tagged_portchannel, /^(interface Vlan\s+(\S+).*?)^!/m do      
      match /^\s*tagged Port-channel\s+(.*?)\s*$/
	  cmd 'sh run'
      add do |transport, value|        
        transport.command("tagged Port-channel #{value}")
      end
      remove do |transport, old_value|        
        transport.command("no tagged Port-channel #{old_value}")
      end      
    end
	
	base.register_scoped :tagged_gigabitethernet, /^(interface Vlan\s+(\S+).*?)^!/m do      
      match /^\s*tagged GigabitEthernet\s+(.*?)\s*$/
	  cmd 'sh run'
      add do |transport, value|        
        transport.command("tagged GigabitEthernet #{value}")
      end
      remove do |transport, old_value|        
        transport.command("no tagged GigabitEthernet #{old_value}")
      end      
    end
	
	base.register_scoped :tagged_sonet, /^(interface Vlan\s+(\S+).*?)^!/m do      
      match /^\s*tagged Sonet\s+(.*?)\s*$/
	  cmd 'sh run'
      add do |transport, value|        
        transport.command("tagged Sonet #{value}")
      end
      remove do |transport, old_value|        
        transport.command("no tagged Sonet #{old_value}")
      end      
    end	
      
  end
end

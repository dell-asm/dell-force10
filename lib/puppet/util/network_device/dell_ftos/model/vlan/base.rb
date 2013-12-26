#VLAN model
#Registers all the properties as parameters and so apply required changes

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
	
    ifprop(base, :desc) do   
     match /^\s*name\s+(.*?)\s*$/	
      add do |transport, value|
	  if value != 'absent'
        transport.command("name #{value}") do |out|			
			txt<< out
		end
		parseforerror(txt," adding 'name' property value")
		end
      end
     remove do |transport, old_value|        
        transport.command("no name #{old_value}") do |out|			
			txt<< out
		end
		parseforerror(txt," removing 'name' property old value")
      end 
    end

	
	base.register_scoped :tagged_tengigabitethernet, /^(interface Vlan\s+(\S+).*?)^!/m do      
      match /^\s*tagged TenGigabitEthernet\s+(.*?)\s*$/
	  cmd 'sh run'
      add do |transport, value|  
		if value != 'absent'
			transport.command("tagged TenGigabitEthernet #{value}") do |out|			
			  txt<< out
		    end
			parseforerror(txt," adding 'tagged TenGigabitEthernet' property value")
		end
      end
      remove do |transport, old_value|        
        transport.command("no tagged TenGigabitEthernet #{old_value}") do |out|			
			txt<< out
		end
		parseforerror(txt," removing 'tagged TenGigabitEthernet' property old value")
      end      
    end
	
	base.register_scoped :tagged_portchannel, /^(interface Vlan\s+(\S+).*?)^!/m do      
      match /^\s*tagged Port-channel\s+(.*?)\s*$/
	  cmd 'sh run'
      add do |transport, value| 
      if value != 'absent'	  
        transport.command("tagged Port-channel #{value}") do |out|			
			txt<< out
		end
		parseforerror(txt," adding 'tagged Port-channel' property value")
		end
      end
      remove do |transport, old_value|        
        transport.command("no tagged Port-channel #{old_value}") do |out|			
			txt<< out
		end
		parseforerror(txt," removing 'tagged Port-channel' property old value")
      end      
    end
	
	base.register_scoped :tagged_gigabitethernet, /^(interface Vlan\s+(\S+).*?)^!/m do      
      match /^\s*tagged GigabitEthernet\s+(.*?)\s*$/
	  cmd 'sh run'
      add do |transport, value|   
		if value != 'absent'		  
        transport.command("tagged GigabitEthernet #{value}") do |out|			
			txt<< out
		end
		parseforerror(txt," adding 'tagged GigabitEthernet'' property value")
		end
      end
      remove do |transport, old_value|        
        transport.command("no tagged GigabitEthernet #{old_value}") do |out|			
			txt<< out
		end
		parseforerror(txt," removing 'tagged GigabitEthernet' property old value")
      end      
    end
	
	base.register_scoped :tagged_sonet, /^(interface Vlan\s+(\S+).*?)^!/m do      
      match /^\s*tagged Sonet\s+(.*?)\s*$/
	  cmd 'sh run'
      add do |transport, value|   
		if value != 'absent'		  
        transport.command("tagged Sonet #{value}") do |out|			
			txt<< out
		end
		parseforerror(txt," adding 'tagged Sonet' property value")
		end
      end
      remove do |transport, old_value|        
        transport.command("no tagged Sonet #{old_value}") do |out|			
			txt<< out
		end
		parseforerror(txt," removing 'tagged Sonet' property old value")
      end      
    end	      
	
	base.register_scoped :untagged_tengigabitethernet, /^(interface Vlan\s+(\S+).*?)^!/m do      
      match /^\s*untagged TenGigabitEthernet\s+(.*?)\s*$/
	  cmd 'sh run'
      add do |transport, value|  
		if value != 'absent'
			transport.command("untagged TenGigabitEthernet #{value}") do |out|			
			  txt<< out
		    end
			parseforerror(txt," adding 'untagged TenGigabitEthernet' property value")
		end
      end
      remove do |transport, old_value|        
        transport.command("no untagged TenGigabitEthernet #{old_value}") do |out|			
			txt<< out
		end
		parseforerror(txt," removing 'untagged TenGigabitEthernet' property old value")
      end      
    end
	
	base.register_scoped :untagged_portchannel, /^(interface Vlan\s+(\S+).*?)^!/m do      
      match /^\s*untagged Port-channel\s+(.*?)\s*$/
	  cmd 'sh run'
      add do |transport, value| 
      if value != 'absent'	  
        transport.command("untagged Port-channel #{value}") do |out|			
			txt<< out
		end
		parseforerror(txt," adding 'untagged Port-channel' property value")
		end
      end
      remove do |transport, old_value|        
        transport.command("no untagged Port-channel #{old_value}") do |out|			
			txt<< out
		end
		parseforerror(txt," removing 'untagged Port-channel' property old value")
      end      
    end
	
	base.register_scoped :untagged_gigabitethernet, /^(interface Vlan\s+(\S+).*?)^!/m do      
      match /^\s*untagged GigabitEthernet\s+(.*?)\s*$/
	  cmd 'sh run'
      add do |transport, value|   
		if value != 'absent'		  
        transport.command("untagged GigabitEthernet #{value}") do |out|			
			txt<< out
		end
		parseforerror(txt," adding 'untagged GigabitEthernet'' property value")
		end
      end
      remove do |transport, old_value|        
        transport.command("no untagged GigabitEthernet #{old_value}") do |out|			
			txt<< out
		end
		parseforerror(txt," removing 'untagged GigabitEthernet' property old value")
      end      
    end
	
	base.register_scoped :tagged_sonet, /^(interface Vlan\s+(\S+).*?)^!/m do      
      match /^\s*untagged Sonet\s+(.*?)\s*$/
	  cmd 'sh run'
      add do |transport, value|   
		if value != 'absent'		  
        transport.command("untagged Sonet #{value}") do |out|			
			txt<< out
		end
		parseforerror(txt," adding 'untagged Sonet' property value")
		end
      end
      remove do |transport, old_value|        
        transport.command("no untagged Sonet #{old_value}") do |out|			
			txt<< out
		end
		parseforerror(txt," removing 'untagged Sonet' property old value")
      end      
    end	      
  end  
  
end

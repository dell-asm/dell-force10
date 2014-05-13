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
      match /^\s*description\s+(.*?)\s*$/
      add do |transport, value|
        if value != 'absent'
          transport.command("desc #{value}") do |out|
            txt<< out
          end
          parseforerror(txt,"add the property value for the parameter 'desc'")
        end
      end
      remove do |transport, old_value|
        transport.command("no desc #{old_value}") do |out|
          txt<< out
        end
        parseforerror(txt,"remove the old property value of the parameter 'desc'")
      end
    end

    ifprop(base, :vlan_name) do
      match /^\s*name\s+(.*?)\s*$/
      add do |transport, value|
        if value != 'absent'
          transport.command("name #{value}") do |out|
            txt<< out
          end
          parseforerror(txt,"add the property value for the parameter 'name'")
        end
      end
      remove do |transport, old_value|
        transport.command("no name #{old_value}") do |out|
          txt<< out
        end
        parseforerror(txt,"remove the old property value of the parameter 'name'")
      end
    end

    ifprop(base, :shutdown) do
      shutdowntxt=''
      match do |shutdowntxt|
        unless shutdowntxt.nil?
          if shutdowntxt.include? "no shutdown"
            :false
          else
            :true
          end
        end
      end
      add do |transport, value|
        if value==:true
          transport.command("shutdown")
        else
          transport.command("no shutdown")
        end
      end
      remove { |*_| }
    end

    ifprop(base, :mtu) do
      match /^\s*mtu\s+(.*?)\s*$/
      add do |transport, value|
        if value != :absent
          transport.command("mtu #{value}") do |out|
            txt<< out
          end
          parseforerror(txt,"add the property value for the parameter 'mtu'")
        end
      end
      remove do |transport, old_value|
        transport.command("no mtu #{old_value}") do |out|
          txt<< out
        end
        parseforerror(txt,"remove the old property value of the parameter 'mtu'")
      end
    end

    base.register_scoped :tagged_tengigabitethernet, /^(interface Vlan\s+(\S+).*?)^!/m do
      match /^\s*tagged TenGigabitEthernet\s+(.*?)\s*$/
      cmd 'sh run'
      add do |transport, value|
        if value != 'absent'
          transport.command("no untagged TenGigabitEthernet #{value}")
          transport.command("tagged TenGigabitEthernet #{value}") do |out|
            txt<< out
          end
          parseforerror(txt,"add the property value for the parameter 'tagged TenGigabitEthernet'")
        end
      end
      remove do |transport, old_value|
        #transport.command("no tagged TenGigabitEthernet #{old_value}") do |out|
        #  txt<< out
        #end
        parseforerror(txt,"remove the old property value of the parameter 'tagged TenGigabitEthernet'")
      end
    end

    base.register_scoped :tagged_fortygigabitethernet, /^(interface Vlan\s+(\S+).*?)^!/m do
      match /^\s*tagged fortyGigE\s+(.*?)\s*$/
      cmd 'sh run'
      add do |transport, value|
        if value != 'absent'
          transport.command("no untagged fortyGigE #{value}")
          transport.command("tagged fortyGigE #{value}") do |out|
            txt<< out
          end
          parseforerror(txt,"add the property value for the parameter 'tagged fortyGigE'")
        end
      end
      remove do |transport, old_value|
        transport.command("no tagged fortyGigE #{old_value}") do |out|
          txt<< out
        end
        parseforerror(txt,"remove the old property value of the parameter 'tagged fortyGigE'")
      end
    end

    base.register_scoped :tagged_portchannel, /^(interface Vlan\s+(\S+).*?)^!/m do
      match /^\s*tagged Port-channel\s+(.*?)\s*$/
      cmd 'sh run'
      add do |transport, value|
        if value != 'absent'
          transport.command("no untagged Port-channel #{value}")
          transport.command("tagged Port-channel #{value}") do |out|
            txt<< out
          end
          parseforerror(txt,"add the property value for the parameter 'tagged Port-channel'")
        end
      end
      remove do |transport, old_value|
        transport.command("no tagged Port-channel #{old_value}") do |out|
          txt<< out
        end
        parseforerror(txt,"to remove the old property value of the parameter 'tagged Port-channel'")
      end
    end

    base.register_scoped :tagged_gigabitethernet, /^(interface Vlan\s+(\S+).*?)^!/m do
      match /^\s*tagged GigabitEthernet\s+(.*?)\s*$/
      cmd 'sh run'
      add do |transport, value|
        if value != 'absent'
          transport.command("no untagged GigabitEthernet #{value}")
          transport.command("tagged GigabitEthernet #{value}") do |out|
            txt<< out
          end
          parseforerror(txt,"add the property value for the parameter 'tagged GigabitEthernet'")
        end
      end
      remove do |transport, old_value|
        transport.command("no tagged GigabitEthernet #{old_value}") do |out|
          txt<< out
        end
        parseforerror(txt,"remove the property value of the parameter 'tagged GigabitEthernet'")
      end
    end

    base.register_scoped :tagged_sonet, /^(interface Vlan\s+(\S+).*?)^!/m do
      match /^\s*tagged Sonet\s+(.*?)\s*$/
      cmd 'sh run'
      add do |transport, value|
        if value != 'absent'
          transport.command("no untagged Sonet #{value}")
          transport.command("tagged Sonet #{value}") do |out|
            txt<< out
          end
          parseforerror(txt,"add the property value for the parameter 'tagged Sonet property'")
        end
      end
      remove do |transport, old_value|
        transport.command("no tagged Sonet #{old_value}") do |out|
          txt<< out
        end
        parseforerror(txt,"remove the property value of the parameter 'tagged Sonet property'")
      end
    end

    base.register_scoped :untagged_tengigabitethernet, /^(interface Vlan\s+(\S+).*?)^!/m do
      match /^\s*untagged TenGigabitEthernet\s+(.*?)\s*$/
      cmd 'sh run'
      add do |transport, value|
        if value != 'absent'
          #untagged interfaces can only belong to one VLAN at a time - and so checking for mappings and so doing no untag
          nountagintffromoothervlans("TenGigabitEthernet",value,base.name)
          transport.command("no tagged TenGigabitEthernet #{value}")
          transport.command("untagged TenGigabitEthernet #{value}") do |out|
            txt<< out
          end
          transport.command("exit")
          transport.command("exit")
          parseforerror(txt,"add the property value for the parameter 'untagged TenGigabitEthernet'")
        end
      end
      remove do |transport, old_value|
        #transport.command("no untagged TenGigabitEthernet #{old_value}") do |out|
        #  txt<< out
        #end
        parseforerror(txt,"remove the old property value of the parameter 'untagged TenGigabitEthernet'")
      end
    end

    base.register_scoped :untagged_fortygigabitethernet, /^(interface Vlan\s+(\S+).*?)^!/m do
      match /^\s*untagged fortyGigE\s+(.*?)\s*$/
      cmd 'sh run'
      add do |transport, value|
        if value != 'absent'
          nountagintffromoothervlans("fortyGigE",value,base.name)
          transport.command("no tagged fortyGigE #{value}")
          transport.command("untagged fortyGigE #{value}") do |out|
            txt<< out
          end
          parseforerror(txt,"add the property value for the parameter 'untagged fortyGigE'")
        end
      end
      remove do |transport, old_value|
        transport.command("no untagged fortyGigE #{old_value}") do |out|
          txt<< out
        end
        parseforerror(txt,"remove the old property value of the parameter 'untagged fortyGigE'")
      end
    end

    base.register_scoped :untagged_portchannel, /^(interface Vlan\s+(\S+).*?)^!/m do
      match /^\s*untagged Port-channel\s+(.*?)\s*$/
      cmd 'sh run'
      add do |transport, value|
        if value != 'absent'
          nountagintffromoothervlans("Port-channel",value,base.name)
          transport.command("no tagged Port-channel #{value}")
          transport.command("untagged Port-channel #{value}") do |out|
            txt<< out
          end
          parseforerror(txt,"add the property value for the parameter 'untagged Port-channel'")
        end
      end
      remove do |transport, old_value|
        transport.command("no untagged Port-channel #{old_value}") do |out|
          txt<< out
        end
        parseforerror(txt,"to remove the old property value of the parameter 'untagged Port-channel'")
      end
    end

    base.register_scoped :untagged_gigabitethernet, /^(interface Vlan\s+(\S+).*?)^!/m do
      match /^\s*untagged GigabitEthernet\s+(.*?)\s*$/
      cmd 'sh run'
      add do |transport, value|
        if value != 'absent'
          nountagintffromoothervlans("GigabitEthernet",value,base.name)
          transport.command("no tagged GigabitEthernet #{value}")
          transport.command("untagged GigabitEthernet #{value}") do |out|
            txt<< out
          end
          parseforerror(txt,"add the property value for the parameter 'untagged GigabitEthernet'")
        end
      end
      remove do |transport, old_value|
        transport.command("no untagged GigabitEthernet #{old_value}") do |out|
          txt<< out
        end
        parseforerror(txt,"remove the property value of the parameter 'untagged GigabitEthernet'")
      end
    end

    base.register_scoped :tagged_sonet, /^(interface Vlan\s+(\S+).*?)^!/m do
      match /^\s*untagged Sonet\s+(.*?)\s*$/
      cmd 'sh run'
      add do |transport, value|
        if value != 'absent'
          nountagintffromoothervlans("Sonet",value,base.name)
          transport.command("no tagged Sonet #{value}")
          transport.command("untagged Sonet #{value}") do |out|
            txt<< out
          end
          parseforerror(txt,"add the property value for the parameter 'untagged Sonet'")
        end
      end
      remove do |transport, old_value|
        transport.command("no untagged Sonet #{old_value}") do |out|
          txt<< out
        end
        parseforerror(txt,"remove the property value of the parameter 'untagged Sonet'")
      end
    end
  end

end

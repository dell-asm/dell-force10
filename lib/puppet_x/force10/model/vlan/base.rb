#VLAN model
#Registers all the properties as parameters and so apply required changes

require 'puppet_x/force10/model'
require 'puppet_x/force10/model/base'
require 'puppet_x/force10/model/vlan'

module PuppetX::Force10::Model::Vlan::Base
  def self.ifprop(base, param, base_command = param, &block)
    base.register_scoped param, /^(interface Vlan\s+(\S+).*?)^!/m do
      cmd 'show running-config interface'
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

    [[:tagged_gigabitethernet, "GigabitEthernet"],
     [:tagged_tengigabitethernet, "TenGigabitEthernet"],
     [:tagged_twentyfivegigabitethernet, "twentyFiveGigE"],
     [:tagged_fortygigabitethernet, "fortyGigE"],
     [:tagged_hundredgigabitethernet, "hundredGigE"]].each do |tagged_param, port_speed|
      base.register_scoped tagged_param, /^(interface Vlan\s+(\S+).*?)^!/m do
        match /^\s*tagged #{port_speed}\s+(.*?)\s*$/
        cmd 'sh run'
        add do |transport, value|
          if value != 'absent'
            transport.command("no untagged #{port_speed} #{value}")
            transport.command("tagged #{port_speed} #{value}") do |out|
              txt << out
            end
            parseforerror(txt, "add the property value for the parameter 'tagged #{port_speed}'")
          end
        end
        remove do |transport, old_value|
          #transport.command("no tagged TenGigabitEthernet #{old_value}") do |out|
          #  txt<< out
          #end
          parseforerror(txt, "remove the old property value of the parameter 'tagged #{port_speed}'")
        end
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
        #transport.command("no tagged Port-channel #{old_value}") do |out|
        #  txt<< out
        #end
        parseforerror(txt,"to remove the old property value of the parameter 'tagged Port-channel'")
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
        #transport.command("no tagged Sonet #{old_value}") do |out|
        #  txt<< out
        #end
        parseforerror(txt,"remove the property value of the parameter 'tagged Sonet property'")
      end
    end

    [[:untagged_gigabitethernet, "GigabitEthernet"],
     [:untagged_tengigabitethernet, "TenGigabitEthernet"],
     [:untagged_twentyfivegigabitethernet, "twentyFiveGigE"],
     [:untagged_fortygigabitethernet, "fortyGigE"],
     [:untagged_hundredgigabitethernet, "hundredGigE"]].each do |tagged_param, port_speed|
      base.register_scoped tagged_param, /^(interface Vlan\s+(\S+).*?)^!/m do
        port_speed = PuppetX::Force10::Model::Base.convert_to_full_name(port_speed)
        match /^\s*tagged #{port_speed}\s+(.*?)\s*$/
        cmd 'sh run'
        add do |transport, value|
          if value != 'absent'
            #untagged interfaces can only belong to one VLAN at a time - and so checking for mappings and so doing no untag
            nountagintffromoothervlans(port_speed,value,base.name)
            transport.command("no tagged #{port_speed} #{value}")
            transport.command("untagged #{port_speed} #{value}") do |out|
              txt << out
            end
            parseforerror(txt, "add the property value for the parameter 'untagged #{port_speed}'")
          end
        end
        remove do |transport, old_value|
          #transport.command("no untagged TenGigabitEthernet #{old_value}") do |out|
          #  txt<< out
          #end
          parseforerror(txt, "remove the old property value of the parameter 'untagged #{port_speed}'")
        end
      end
    end

    base.register_scoped :untagged_portchannel, /^(interface Vlan\s+(\S+).*?)^!/m do
      match /^\s*untagged Port-channel\s+(.*?)\s*$/
      cmd 'sh run'
      add do |transport, value|
        if value != 'absent'
          nountagintffromoothervlans("Port-channel",Integer(value),base.name)
          # Skip for native vlan, since that will cause issues.
          unless base.name == "1"
            transport.command("no tagged Port-channel #{value}")
            transport.command("untagged Port-channel #{value}") do |out|
              txt<< out
            end
            parseforerror(txt,"add the property value for the parameter 'untagged Port-channel'")
          end
        end
      end
      remove do |transport, old_value|
        #transport.command("no untagged Port-channel #{old_value}") do |out|
        # txt<< out
        #end
        parseforerror(txt,"to remove the old property value of the parameter 'untagged Port-channel'")
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
        #transport.command("no untagged Sonet #{old_value}") do |out|
        #  txt<< out
        #end
        parseforerror(txt,"remove the property value of the parameter 'untagged Sonet'")
      end
    end
    
    base.register_scoped :fc_map, /^(interface Vlan\s+(\S+).*?)^!/m do
      match /^\s*fip-snooping fc-map\s+(.*?)\s*$/
      cmd 'sh run'
      add do |transport, value|
        if value != ''
          transport.command("fip-snooping fc-map #{value}",:prompt => /Changing fc-map deletes sessions using it.*/)
          transport.command("y")
          transport.command("fip-snooping enable") 
        end
      end
      remove { |*_| }
    end
  end
end

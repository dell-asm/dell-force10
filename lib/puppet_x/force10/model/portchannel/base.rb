require 'puppet_x/force10/model'
require 'puppet_x/force10/model/portchannel'

module PuppetX::Force10::Model::Portchannel::Base
  def self.register(base)
    portchannel_scope = /^(L*\s*(\d+)\s+(.*))/
    general_scope = /(^Port-channel (\d+).*)\s+/m
    portchannelval = base.name

    base.register_scoped :ensure, portchannel_scope do
      match do |txt|
        unless txt.nil?
          txt.match(/\S+/) ? :present : :absent
        else
          :absent
        end
      end
      cmd 'show interface port-channel brief'
      default :absent
      add { |*_| }
      remove { |*_| }
    end

    base.register_scoped :mtu, general_scope do

      match do |txt|
          paramsarray=txt.match(/^MTU (\d+)/)
          if paramsarray.nil?
            param1 = :absent
          else
            param1 = paramsarray[1]
          end
          param1
      end

      cmd "show interface port-channel #{portchannelval}"
      default :absent
      add do |transport, value|
        transport.command("mtu #{value}")
      end
      remove { |*_| }
    end

    base.register_scoped :shutdown, general_scope do
      
      match do |txt|
          paramsarray=txt.match(/^Port-channel (\d+) is up/)
          if paramsarray.nil?
            param1 = :true
          else
            param1 = :false
          end
          param1
      end


      cmd "show interface port-channel #{portchannelval}"
      default :absent
      add do |transport, value|
        if value == :false
          transport.command("no shutdown")
        else
          transport.command("shutdown")
        end
      end
      remove { |*_| }
    end

    base.register_scoped :portmode, portchannel_scope do
      cmd "show interface port-channel #{portchannelval}"
      match /^\s*portmode\s+(.*?)\s*$/
      add do |transport, value|
        #transport.command("fabric #{value}")
        #Remove existing config to allow to set portmode
        existing_config=(transport.command('show config') || '').split("\n").reverse
        updated_config = existing_config.find_all {|x| x.match(/dcb|switchport|spanning|vlan|portmode/)}
        updated_config.each do |remove_command|
          transport.command("no #{remove_command}")
        end
        transport.command('portmode hybrid')
        updated_config.reverse.each do |remove_command|
          transport.command("#{remove_command}")
        end
      end
    end

    base.register_scoped :switchport, portchannel_scope do

      match do |txt|
        txt =~ /L2/ ? :true : :false
      end

      cmd "show interfaces port-channel brief"
      add do |transport, value|
        if value == :false
          transport.command("no switchport")
        else
          transport.command("portmode hybrid")
          transport.command("switchport")
        end
      end
      remove { |*_| }
    end

    base.register_scoped :fip_snooping_fcf, general_scope do
      match do |txt|
        txt =~ /fip-snooping port-mode fcf/ ? :true : :false
      end

      cmd "show interface port-channel #{portchannelval}"
      default :absent
      add do |transport, value|
        if value == :true
          transport.command("fip-snooping port-mode fcf")
        else
          transport.command("no fip-snooping port-mode fcf")
        end
      end
      remove { |*_| }
    end


      

    base.register_scoped :desc, general_scope do
      match do |txt|
          paramsarray=txt.match(/^Description: (.*)/)
          if paramsarray.nil?
            param1 = :absent
          else
            param1 = paramsarray[1]
          end
          param1
      end

      cmd "show interface port-channel #{portchannelval}"
      add do |transport, value|
        transport.command("desc #{value}")
      end
      remove { |*_| }
    end
    
    base.register_scoped :fcoe_map, general_scope do
      match do |txt|
        paramsarray=txt.match(/^fcoe-map\s+(\S+)/)
        if paramsarray.nil?
          param1 = :absent
        else
          param1 = paramsarray[1]
        end
        param1
      end

      cmd "show running-config interface port-channel #{portchannelval}"
      add do |transport, value|
        transport.command("fcoe-map #{value}")
      end
      remove { |*_| }
    end

    base.register_scoped :vltpeer, portchannel_scope do
      match do |txt|
        paramsarray=txt.match(/^\d+\s+(\w2)\s+\w+/)
        if paramsarray.nil?
          param1 = true
        else
          param1 = false
        end
        param1
      end

      cmd "show interface port-channel #{portchannelval}"
      add do |transport, value|
        if value == :true
          transport.command("vlt-peer-lag po#{portchannelval}")
        end
      end
      remove { |*_| }
    end

    base.register_scoped :tagged_vlan, portchannel_scope do
      cmd "show interface port-channel #{portchannelval}"
      match do |txt|
        params_array=txt.match(/^T\s+(\S+)/)
        if params_array.nil?
          param = :absent
        else
          param = params_array[1]
        end
        param
      end
      add do |transport, value|
        # Find the VLANS which are already configured
        existing_config = transport.command("show config")
        tagged_vlan = ( existing_config.scan(/vlan tagged\s+(.*?)$/m).flatten.first || "" )
        vlans = tagged_vlan.split(",")
        # This array will just contain all the currently tagged vlans individually, instead of being in a range such as 1-5
        unranged_tagged_vlans = []
        vlans.each do |vlan|
          if vlan.include?("-")
            vlan_range = vlan.split("-").flatten
            vlan_value = (vlan_range[0]..vlan_range[1]).to_a
            unranged_tagged_vlans.concat(vlan_value)
          else
            unranged_tagged_vlans.push(vlan)
          end
        end
        requested_vlans = value.split(",").uniq.sort

        # Find VLANs that need to be skipped
        missing_vlans = []
        vlans_to_add = []
        (1..4094).each do |vlan_id|
          missing_vlans.push(vlan_id) unless requested_vlans.include?(vlan_id.to_s)
        end

        missing_vlans = missing_vlans.to_ranges.join(",").gsub(/\.\./,"-")
        Puppet.debug "Missing VLAN Range: #{missing_vlans}"

        if unranged_tagged_vlans == requested_vlans
          Puppet.debug "No change to tagged_vlans"
        else
          if unranged_tagged_vlans.empty?
            vlans_to_add = value
          else
            requested_vlans.map { |x| vlans_to_add.push(x) if !unranged_tagged_vlans.include?(x) }
            vlans_to_add = vlans_to_add.compact.flatten.uniq.to_ranges.join(",").gsub(/\.\./,'-')
          end
        end

        # Untag VLAN needs to be updated only if there is a overlap of untag VLAN with existing list of tag vlans
        untag_vlan = ( existing_config.scan(/vlan untagged\s+(.*?)$/m).flatten.first || "" )
        transport.command("no vlan untagged") if requested_vlans.include?(untag_vlan)

        transport.command("no vlan tagged #{missing_vlans}") if !missing_vlans.nil?
        transport.command("vlan tagged #{vlans_to_add}") if !vlans_to_add.nil?
      end

      remove { |*_| }
    end

    base.register_scoped :untagged_vlan, portchannel_scope do
      cmd "show interface port-channel #{portchannelval}"
      match  do |txt|
        params_array=txt.match(/^U\s+(\S+)/)
        if params_array.nil?
          param = :absent
        else
          param = params_array[1]
        end
        param
      end

      add do |transport, value|
        transport.command("no vlan untagged")
        transport.command("no vlan tagged #{value}")
        transport.command("vlan untagged #{value}")
      end
      remove do |transport, old_value|
        transport.command("no vlan untagged")
      end
    end


    base.register_scoped(:ungroup, /port-channel (\d)+$/) do
      match /^lacp ungroup member-independent port-channel #{portchannelval}$/
      cmd "show running-config | grep member-independent"
      add do |transport, _|
        # Needs to be configured at top level configuration mode
        transport.command("exit")
        transport.command("lacp ungroup member-independent port-channel %s" % portchannelval)
        transport.command("interface port-channel %s" % portchannelval)
      end
      remove do |transport, _|
        transport.command("exit")
        transport.command("no lacp ungroup member-independent port-channel %s" % portchannelval)
        transport.command("interface port-channel %s" % portchannelval)
      end
    end

  end
end

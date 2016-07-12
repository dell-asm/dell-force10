require 'puppet_x/force10/model'
require 'puppet_x/force10/model/interface'

module PuppetX::Force10::Model::Interface::Base

  def self.ifprop(base, param, base_command = param, &block)
    base.register_scoped param, /^(interface\s+(\S+\s\S+).*?shutdown)/m do
      cmd 'sh run'
      match /^\s*#{base_command}\s+(.*?)\s*$/
      add do |transport, value|
        Puppet.debug(" command #{base_command} value  #{value}")
        transport.command("#{base_command} #{value}")
      end
      remove do |transport, old_value|
        Puppet.debug(" No  command #{base_command} value  #{value}")
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
      add { |*_|}
      remove { |*_|}
    end

    ifprop(base, :portchannel) do
      match /^  port-channel (\d+)\s+.*$/
      add do |transport, value|
        Puppet.debug("Need to remove existing configuration")
        existing_config=(transport.command("show config") || "").split("\n").reverse
        updated_config = existing_config.find_all do |x|
          x.match(/dcb|switchport|spanning|vlan|portmode/)
        end
        updated_config.each do |remove_command|
          transport.command("no #{remove_command}")
        end

        existing_config=(transport.command("show config") || "").split("\n")
        # Remove existing port channel if one exists
        if existing_config.find {|line| line =~ /port-channel/}
          transport.command("no port-channel-protocol lacp")
        end
        transport.command("port-channel-protocol lacp")
        transport.command("port-channel #{value} mode active")
        transport.command("exit")
      end
      remove do |transport, value|
        transport.command("no port-channel-protocol lacp")
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
      remove { |*_|}
    end

    ifprop(base, :mtu) do
      match /^\s*mtu\s+(.*?)\s*$/
      add do |transport, value|
        transport.command("mtu #{value}")
      end
      remove { |*_|}
    end

    ifprop(base, :switchport) do
      switchporttxt=''
      match do |switchporttxt|
        unless switchporttxt.nil?
          if switchporttxt.include? "switchport"
            :true
          else
            :false
          end
        end
      end
      add do |transport, value|
        if value == :true
          transport.command("switchport") do |out|
            if out =~/Error:\s*(.*)/
              Puppet.debug "#{$1}"
            end
          end
        end
        if value == :false
          transport.command("no switchport") do |out|
            if out =~/Error:\s*(.*)/
              Puppet.debug "#{$1}"
            end
          end
        end

      end
      remove { |*_|}
    end

    ifprop(base, :dcb_map) do
      match /^\s*dcb-map\s+(.*?)\s*$/
      add do |transport, value|
        # Commands to remove the dcb ets and pfc settings
        # Without these settings removed, DCB is not applied
        transport.command("no dcb-policy input pfc")
        transport.command("no dcb-policy output ets")

        # Command to enable the spanning tree edge port
        transport.command("spanning-tree estp edge-port")

        # Command to associate DCB map with the interface
        transport.command("dcb-map #{value}")
      end
      remove { |*_|}
    end

    ifprop(base, :fcoe_map) do
      match /^\s*fcoe-map\s+(.*?)\s*$/
      add do |transport, value|
        transport.command("fcoe-map #{value}")
      end
      remove { |*_|}
    end

    ifprop(base, :fabric) do
      match /^\s*fabric\s+(.*?)\s*$/
      add do |transport, value|
        transport.command("fabric #{value}")
      end
      remove { |*_|}
    end

    ifprop(base, :portmode) do
      match /^\s*portmode\s+(.*?)\s*$/
      add do |transport, value|
        #transport.command("fabric #{value}")
        Puppet.debug('Need to remove existing configuration')
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
      remove { |*_|}
    end

    ifprop(base, :portfast) do
      match /^\s*spanning-tree 0 (.*?)\s*$/
      add do |transport, value|
        transport.command("spanning-tree 0 #{value}")
      end
      remove { |*_|}
    end

    ifprop(base, :edge_port) do
      match /^\s*spanning-tree pvst\s+(.*?)\s*$/
      add do |transport, value|
        value = value.split(",")
        stp_val = PuppetX::Force10::Model::Interface::Base.show_stp_val(transport, scope_name)
        PuppetX::Force10::Model::Interface::Base.update_stp(transport, scope_name, stp_val, value)
      end
      remove { |*_|}
    end

    ifprop(base, :protocol) do
      match /^\s*protocol\s+(.*?)\s*$/
      add do |transport, value|
        transport.command('protocol lldp')
        # Need to come out of the lldp context
        transport.command('exit')
      end
      remove do |transport, value|
        transport.command("no protocol lldp")
      end
    end

    ifprop(base, :untagged_vlan) do
      empty_match=''
      match do |empty_match|
        unless empty_match.nil?
          :false #This is so we always go through the "add" swimlane
        end
      end
      add do |transport, value|
        untagged, tagged = PuppetX::Force10::Model::Interface::Base.show_interface_vlans(transport, scope_name)
        PuppetX::Force10::Model::Interface::Base.update_untagged_vlans(transport, value, untagged, scope_name)
      end
      remove { |*_|}
    end

    ifprop(base, :tagged_vlan) do
      empty_match=''
      match do |empty_match|
        unless empty_match.nil?
          :false
        end
      end
      add do |transport, value|
        untagged, tagged = PuppetX::Force10::Model::Interface::Base.show_interface_vlans(transport, scope_name)
        PuppetX::Force10::Model::Interface::Base.update_tagged_vlans(transport, value, tagged, scope_name)
      end
      remove { |*_|}
    end
  end

  # Return the untagged and tagged vlans associated with the switch port as a tuple
  #
  # @param transport [PuppetX::Force10::Transport::Ssh] the switch ssh transport
  # @param interface_info [String] the interface id e.g. Tengigabitethernet 0/14
  # @return [Array] tuple of untagged vlan and list of tagged vlans
  def self.show_interface_vlans(transport, interface_info)
    untagged_vlan = nil
    tagged_vlans = []
    transport.command("exit") # Bring us back to config state
    transport.command("exit") # Bring us back to main

    current_vlan_info = transport.command("show interfaces switchport #{interface_info}")
    current_vlan_info.match /^U\s+([\d]+)$/
    if $1.nil? || $1.empty?
      untagged_vlan = []
    else
      untagged_vlan = [$1.to_i]
    end
    vlan_info = current_vlan_info.match /^T\s+([\d\-,]+)$/
    str = vlan_info.nil? ? "" : vlan_info[1]
    str_arr = str.split(",")
    str_arr.each do |num_str|
      num = num_str.to_i
      if num_str == num.to_s
        tagged_vlans << num
      else
        nums = num_str.split("-").map(&:to_i)
        nums[0].upto(nums[1]).each do |range_num|
          tagged_vlans << range_num
        end
      end
    end
    return [untagged_vlan, tagged_vlans]
  end

  def self.update_untagged_vlans(transport, value, existing_vlan, interface_id)
    raise(ArgumentError, "Too many untagged vlans on port %s: %s" %[interface_id, existing_vlan.join(",")]) if existing_vlan.size > 1

    value = value.split(",").map(&:to_i)
    raise(ArgumentError, "Too many untagged vlans requested %s" %value) if existing_vlan.size > 1

    transport.command("config")

    vlans_to_remove = existing_vlan - value
    vlans_to_remove.each do |vlan|
      next if vlan == 1
      Puppet.debug("removing vlan #{vlan} from interface : #{interface_id}")
      transport.command("interface vlan #{vlan}")
      transport.command("no untagged #{interface_id}")
      transport.command("exit")
    end

    vlans_to_add = value - existing_vlan
    vlans_to_add.each do |vlan|
      next if vlan == 1
      Puppet.debug("Adding vlan #{vlan} to interface: #{interface_id}")
      transport.command("interface vlan #{vlan}")
      transport.command("untagged #{interface_id}")
      transport.command("exit")
    end
    transport.command("interface #{interface_id}") # Return transport back to configured interface state
  end

  def self.update_tagged_vlans(transport, value, existing_vlans, interface_id)
    value = value.split(",").map(&:to_i)

    transport.command("config")

    vlans_to_remove = existing_vlans - value
    vlans_to_remove.each do |vlan|
      Puppet.debug("Removing vlan #{vlan} tagged traffic from interface: #{interface_id}")
      transport.command("interface vlan #{vlan}")
      transport.command("no tagged #{interface_id}")
      transport.command("exit")
    end

    vlans_to_add = value - existing_vlans
    vlans_to_add.each do |vlan|
      Puppet.debug("Adding vlan #{vlan} tagged traffic to interface: #{interface_id}")
      transport.command("interface vlan #{vlan}")
      transport.command("tagged #{interface_id}")
      transport.command("exit")
    end
    transport.command("exit") #Bring us back to main state
    transport.command("show interfaces switchport #{interface_id}")
    transport.command("config") #Return configuration back to original state
    transport.command("interface #{interface_id}")
  end

  def self.show_stp_val(transport, interface_id)
    meta_data = transport.command('show config') || ''
    result = []
    regex = /spanning\-tree (\w+) edge-port/
    meta_data.split("\n").each do |line|
      match_data = line.match(regex)
      if !match_data.nil?
        result << match_data[1]
      end
    end
    result
  end

  def self.update_stp(transport, interface_id, existing_stp_val, value)
    remove_stp = existing_stp_val - value
    transport.command("exit") # Bring back to configure state

    remove_stp.each do |type|
      transport.command("interface #{interface_id}")
      transport.command("no spanning-tree #{type} edge-port")
      transport.command("exit")
    end

    adding_stp = value - existing_stp_val
    adding_stp.each do |type|
      transport.command("interface #{interface_id}")
      transport.command("spanning-tree #{type} edge-port")
      transport.command("exit")
    end
    transport.command("interface #{interface_id}") # Return transport back to configured interface state
  end
end

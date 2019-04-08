require 'puppet_x/force10/model'
require 'puppet_x/force10/model/base'
require 'puppet_x/force10/model/interface'

module PuppetX::Force10::Model::Interface::Base

  def self.ifprop(base, param, base_command = param, &block)
    base.register_scoped param, /^(interface\s+(\S+\s\S+).*?shutdown)/m do
      cmd 'sh run'
      match /^\s*#{base_command}\s+(.*?)\s*$/
      add do |transport, value|
        Puppet.debug(" command #{base_command} value  #{value}" )
        transport.command("#{base_command} #{value}")
      end
      remove do |transport, old_value|
        Puppet.debug(" No  command #{base_command} value  #{value}" )
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

    ifprop(base, :is_lacp) do
      match do |protocol_txt|
        if protocol_txt =~ /port-channel-protocol LACP$/
          :true
        else
          :false
        end
      end
    end

    ifprop(base, :portchannel) do
      match do |txt|
        unless txt.nil?
          :false #This is so we always go through the "add" swimlane
        end
      end

      add do |transport, value|
        existing_config = (transport.command("show config") || "").split("\n")
        port_channel = PuppetX::Force10::Model::Interface::Base.get_existing_port_channel(transport, base.name)
        inclusive_vlan = base.params[:inclusive_vlans].value
        existing_lacp = false
        existing_config.each do |line|
          if line =~ / port-channel\s+(\d+)\s+mode\s+active/
            port_channel = $1
            existing_lacp = true
          end
        end

        # Further config should be skipped as vlans are managed by port-channel resource
        next if inclusive_vlan == :true

        #Skip of there is no existing port-channel and expected value is empty
        next if port_channel.nil? && value.empty?

        Puppet.debug("Need to remove existing configuration")
        PuppetX::Force10::Model::Interface::Base.update_vlans(transport, [], true, base.name.split)
        PuppetX::Force10::Model::Interface::Base.update_vlans(transport, [], false, base.name.split) unless inclusive_vlan == :true

        existing_config=(transport.command("show config") || "").split("\n").reverse
        updated_config = existing_config.find_all do |x|
          x.match(/dcb|switchport|spanning|vlan|portmode/)
        end
        updated_config.each do |remove_command|
          transport.command("no #{remove_command}")
        end

        # Remove existing port channel if one exists
        if port_channel && !existing_lacp
          PuppetX::Force10::Model::Interface::Base.update_port_channel(transport, port_channel, base.name.split, true)
        elsif existing_lacp && port_channel
          existing_config.each do |line|
            if line =~ / port-channel\s+(\d+)\s+mode\s+active/
              transport.command("no port-channel-protocol lacp")
            end
          end
        end

        if port_channel && port_channel != value
          PuppetX::Force10::Model::Interface::Base.remove_port_channel(transport, port_channel, base.name.split)
        end

        next if value.to_s.empty?
        # ASM-7311 even if the port doesn't say it's in switchport mode,the
        # 'no switchport' command is still necessary at times, otherwise the lacp
        # commands will fail. Shouldn't hurt to just run the command everytime
        transport.command("no switchport")
        if base.params[:is_lacp].value == :false
          PuppetX::Force10::Model::Interface::Base.update_port_channel(transport, value, base.name.split, false)
        else
          transport.command("port-channel-protocol lacp")
          transport.command("port-channel #{value} mode active")
          transport.command("exit")
        end
      end
      default " "
    end

    ifprop(base, :port_desc) do
      match do |description_txt|
        if description_txt.split("\n").any? {|line| line.match(/description\s+(.*)/)}
          $1
        end
      end
      add do |transport, value|
        next if value == "none"
        inclusive_vlan = base.params[:inclusive_vlans].value
        transport.command("description %s" %[value]) unless inclusive_vlan == :true
      end
      remove do |transport, value|
        transport.command("no description")
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
        transport.command("mtu #{value}")
      end
      default :absent
      remove do |transport, value|
        transport.command("no mtu")
      end
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
      remove { |*_| }
    end

    ifprop(base, :fcoe_map) do
      match /^\s*fcoe-map\s+(.*?)\s*$/
      add do |transport, value|
        transport.command("fcoe-map #{value}")
      end
      remove { |*_| }
    end

    ifprop(base, :fabric) do
      match /^\s*fabric\s+(.*?)\s*$/
      add do |transport, value|
        transport.command("fabric #{value}")
      end
      remove { |*_| }
    end

    ifprop(base, :portmode) do
      match /^\s*portmode\s+(.*?)\s*$/
      add do |transport, value|
        if value == :none
          # Need to remove vlans first else will raise "Port is part of a non-default VLAN"
          inclusive_vlans = base.params[:inclusive_vlans].value
          PuppetX::Force10::Model::Interface::Base.update_vlans(transport, [], true, base.name.split, inclusive_vlans)
          PuppetX::Force10::Model::Interface::Base.update_vlans(transport, [], false, base.name.split, inclusive_vlans)
        end

        #transport.command("fabric #{value}")
        Puppet.debug('Need to remove existing configuration')
        existing_config = (transport.command('show config') || '').split("\n").reverse
        updated_config = existing_config.find_all {|x| x.match(/dcb|switchport|spanning|vlan|portmode|port-channel/)}
        updated_config.each do |remove_command|
          transport.command("no #{remove_command}")
        end

        next if value == :none
        # Switch some times behaves in switchport mode even though "switchport" configuration was not exist on interface
        # which will raise Error on configuring portmode for instance :  Error : Te 0/9 is in Layer 2 LAG
        # By running no switchport before setting portmode will resolve the Error on configuring portmode
        transport.command('no switchport') unless updated_config.include?("switchport")
        transport.command('portmode hybrid')
        updated_config.reverse.each do |remove_command|
          # Can't enable port-channel mode if in portmode hybrid, so skip
          next if remove_command =~ /port-channel/

          transport.command("#{remove_command}")
        end
      end
      remove { |*_| }
    end

    ifprop(base, :switchport) do
      after :portmode
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
          transport.command("switchport")do |out|
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

      remove do |transport, value|
        transport.command("no switchport") do |out|
          if out =~ /Error:\s*(.*)/
            Puppet.debug "#{$1}"
          end
        end
      end
    end

    ifprop(base, :portfast) do
      match /^\s*spanning-tree 0 (.*?)\s*$/
      add do |transport, value|

        if value == :none
          transport.command("no spanning-tree 0 portfast")
        else
          transport.command("spanning-tree 0 #{value}")
        end

      end
      remove { |*_| }
    end

    ifprop(base, :edge_port) do
      match /^\s*spanning-tree pvst\s+(.*?)\s*$/
      add do |transport, value|
        if value == :none
          existing_config = (transport.command("show config") || "").split("\n").reverse
          updated_config = existing_config.find_all do |x|
            x.match(/edge-port/)
          end
          updated_config.each do |remove_command|
            transport.command("no #{remove_command}")
          end
        else
          value = value.split(",")
          stp_val = PuppetX::Force10::Model::Interface::Base.show_stp_val(transport, scope_name)
          PuppetX::Force10::Model::Interface::Base.update_stp(transport, scope_name, stp_val, value)
        end
      end
      remove {|*_|}
    end

    ifprop(base, :protocol) do
      match /^\s*protocol\s+(.*?)\s*$/
      add do |transport, value|
        next if base.params[:inclusive_vlans].value == :true
        if value == :none
          transport.command('no protocol lldp')
        else
          transport.command('protocol lldp')
          # Need to come out of the lldp contextis
          transport.command('exit')
        end
      end
      default :none

      remove do |transport, value|
        transport.command("no protocol lldp") unless base.params[:inclusive_vlans].value == :true
      end
    end

    ifprop(base, :untagged_vlan) do
      empty_match=''
      match do |empty_match|
        unless empty_match.nil?
          :false  #This is so we always go through the "add" swimlane
        end
      end
      add do |transport, value|
        next if value.empty? && base.params[:inclusive_vlans].value == :true
        existing_config = transport.command('show config') || ''
        iface = existing_config.match(/\s*interface\s+(.*?)\s*$/)[1]
        type, interface_id = PuppetX::Force10::Model::Interface::Base.parse_interface(iface)
        vlans = PuppetX::Force10::Model::Interface::Base.vlans_from_list(value)
        inclusive_vlans = base.params[:inclusive_vlans].value
        PuppetX::Force10::Model::Interface::Base.update_vlans(transport, vlans, false, [type, interface_id], inclusive_vlans)
      end
      remove { |*_| }
    end

    ifprop(base, :tagged_vlan) do
      empty_match=''
      match do |empty_match|
        unless empty_match.nil?
          :false
        end
      end
      add do |transport, value|
        next if value.empty? && base.params[:inclusive_vlans].value == :true
        existing_config = transport.command('show config') || ''
        iface = existing_config.match(/\s*interface\s+(.*?)\s*$/)[1]
        type, interface_id = PuppetX::Force10::Model::Interface::Base.parse_interface(iface)
        vlans = PuppetX::Force10::Model::Interface::Base.vlans_from_list(value)
        inclusive_vlans = base.params[:inclusive_vlans].value
        PuppetX::Force10::Model::Interface::Base.update_vlans(transport, vlans, true, [type, interface_id], inclusive_vlans)
      end
      remove { |*_| }
    end

    ifprop(base, :inclusive_vlans) do
      match do |txt|
        paramsarray = txt.match(/^T\s+(\S+)/)
        paramsarray.nil? ? :absent : paramsarray[1]
      end

      add {|*_|}
      remove { |*_| }
    end

  end

  # Return the untagged and tagged vlans associated with the switch port as a tuple
  #
  # @param transport [PuppetX::Force10::Transport::Ssh] the switch ssh transport
  # @param interface_type [String] the interface type e.g. Tengigabitethernet
  # @param interface_id [String] the interface port, e.g. 0/4
  # @return [Array] tuple of untagged vlan and list of tagged vlans
  def self.show_interface_vlans(transport, interface_type, interface_id)
    untagged_vlan = nil
    tagged_vlans = []
    interface_type = PuppetX::Force10::Model::Base.convert_to_full_name(interface_type)
    current_vlan_info = transport.command("show interfaces switchport #{interface_type} #{interface_id}")
    current_vlan_info.each_line do |line|
      if line =~ /^U\s+(\d+)$/
        untagged_vlan = $1
      elsif line =~ /^T\s+([0-9,-]+)$/
        tagged_vlans = vlans_from_list($1)
      end
    end
    [untagged_vlan, tagged_vlans]
  end

  def self.get_existing_port_channel(transport, interface_info)
    transport.command("exit")
    transport.command("exit")
    interface_type, interface_id = interface_info.split
    interface_type = PuppetX::Force10::Model::Base.convert_to_full_name(interface_type)
    port_channel_config = (transport.command("show interface port-channel br") || "").split("\n")
    transport.command("conf") # Navigating back to interface context
    transport.command("interface #{interface_type} #{interface_id}")

    # Only checks if interface is assigned to a static port-channel
    port_channel_config.each do |line|
      if line =~ /^L*(\s+\S+){4}\s+(\w+\s+\S+).*\)$/ && interface_info == $2
        return $1 if line =~ /^\s+(\d+).*/
      end
    end

    nil
  end


  def self.update_vlans(transport, new_vlans, tagged, interface_info, inclusive_vlans=false)
    vlan_type = tagged ? "tagged" : "untagged"
    opposite_vlan_type = tagged ? "untagged" : "tagged"
    interface_type, interface_id = interface_info
    interface_type = PuppetX::Force10::Model::Base.convert_to_full_name(interface_type)
    transport.command("exit") # bring us back to config
    transport.command("exit") # bring us back to main

    curr_untagged_vlan, curr_tagged_vlans = show_interface_vlans(transport, interface_type, interface_id)
    if tagged
      current_vlans = curr_tagged_vlans
      opposite_vlans_to_remove = new_vlans & [curr_untagged_vlan].compact
    else
      current_vlans = [curr_untagged_vlan].compact
      opposite_vlans_to_remove = new_vlans & curr_tagged_vlans
    end
    transport.command("config")

    # Remove all the unused vlans
    vlans_to_remove = current_vlans - new_vlans

    if inclusive_vlans == :true && !opposite_vlans_to_remove.empty?
      raise("Untagged VLAN configuration cannot be updated when inclusive vlan flag is true")
    end

    # Remove VLANs from the opposing VLAN type
    opposite_vlans_to_remove.each do |vlan|
      Puppet.debug("Removing opposing vlan #{vlan} from interface #{interface_id}")
      transport.command("interface vlan #{vlan}")
      transport.command("no #{opposite_vlan_type} #{interface_type} #{interface_id}")
      transport.command("exit")
    end

    unless inclusive_vlans == :true
      vlans_to_remove.each do |vlan|
        Puppet.debug("Removing vlan #{vlan} from interface #{interface_id}")
        transport.command("interface vlan #{vlan}")
        transport.command("no #{vlan_type} #{interface_type} #{interface_id}")
        transport.command("exit")
      end
    end

    # Add the new vlans
    if inclusive_vlans == :true && vlan_type == "untagged" &&  current_vlans != new_vlans
      Puppet.warning("Skipping untag vlan configuration as there is an existing untag vlan")
      Puppet.debug("Interface %s is already configured with untag vlan %s " % [interface_id, current_vlans]) unless current_vlans.empty?
    else
      vlans_to_add = new_vlans - current_vlans
      vlans_to_add.each do |vlan|
        next if vlan == "NONE"
        Puppet.debug("Adding vlan #{vlan} to interface #{interface_id}")
        transport.command("interface vlan #{vlan}")

        transport.command("#{vlan_type} #{interface_type} #{interface_id}")
      end
    end
    # Return transport back to beginning location
    transport.command("interface #{interface_type} #{interface_id}")
  end

  def self.update_port_channel(transport, port_channel, interface_info, should_remove, inclusive_vlans=false)
    interface_type, interface_id = interface_info
    interface_type = PuppetX::Force10::Model::Base.convert_to_full_name(interface_type)
    transport.command("exit") # bring us back to config when call from interface context
    transport.command("interface port-channel #{port_channel}")

    if should_remove
      Puppet.debug("removing interface #{interface_type} #{interface_id} from #{port_channel}")
      transport.command("no channel-member #{interface_type} #{interface_id}")
    else
      transport.command("channel-member #{interface_type} #{interface_id}")
    end
    transport.command("exit")

    # Return transport back to beginning location
    transport.command("interface #{interface_type} #{interface_id}")
  end

  def self.remove_port_channel(transport, port_channel, interface_info)
    interface_type, interface_id = interface_info
    interface_type = PuppetX::Force10::Model::Base.convert_to_full_name(interface_type)
    transport.command("exit") # bring us back to config when call from interface context
    transport.command("no interface port-channel #{port_channel}")

    # Return transport back to beginning location
    transport.command("interface #{interface_type} #{interface_id}")
  end

  def self.parse_interface(iface)
    if iface.include? 'TenGigabitEthernet'
      iface.slice! 'TenGigabitEthernet '
      type = 'TenGigabitEthernet'
    elsif iface.include? 'twentyFiveGigE'
      iface.slice! 'twentyFiveGigE '
      type = 'twentyFiveGigE'
    elsif iface.include? 'FortyGigE'
      iface.slice! 'FortyGigE '
      type = 'fortyGigE'
    elsif iface.include? 'hundredGigE'
      iface.slice! 'hundredGigE '
      type = 'hundredGigE'
    else
      raise Puppet::Error, "Unknown interface type #{iface}"
    end
    [type, iface]
  end

  def self.vlans_from_list(value)
    vlans = []
    value = value.to_s
    values = []
    value.split(",").each do |vlan_group|
      values << vlan_group
    end
    values.each do |vlan_group|
      if vlan_group.include? "-"
        first = vlan_group.split("-")[0]
        last = vlan_group.split("-")[1]
        vlans.concat((Integer(first)..Integer(last)).to_a.map(&:to_s))
      else
        vlans << vlan_group
      end
    end
    vlans.uniq!
    vlans
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
    remove_stp.each do |type|
      transport.command("config")
      transport.command("interface #{interface_id}")
      transport.command("no spanning-tree #{type} edge-port")
    end

    adding_stp = value - existing_stp_val
    adding_stp.each do |type|
      transport.command("config")
      transport.command("interface #{interface_id}")
      transport.command("spanning-tree #{type} edge-port")
    end
  end
end


require 'puppet/util/network_device/dell_ftos/possible_facts'
require 'puppet/util/network_device/dell_ftos/possible_facts/hardware'

module Puppet::Util::NetworkDevice::Dell_ftos::PossibleFacts::Hardware::S_series

  # Module Constants
  CMD_SHOW_SYSTEM_BRIEF="show system brief"

  CMD_SHOW_VLAN  ="show vlan"

  CMD_SHOW_INTERFACES  ="show interfaces switchport"

  CMD_SHOW_PORT_CHANNELS  ="show interfaces port-channel brief"

  #CMD_SHOW_LLDP_NEIGHBORS  ="show lldp neighbors detail"

  CMD_SHOW_LLDP_NEIGHBORS1  ="show lldp neighbors"

  CMD_SHOW_STARTUP_CONFIG_VERSION="show startup-config | grep \"! Version\""

  CMD_SHOW_RUNNING_CONFIG_VERSION="show running-config | grep \"! Version\""
  def self.register(base)

    base.register_param 'system_power_status' do
      found = false
      power_status = 'Unknown'
      match do |txt|
        txt.each_line do |line|
          case line
          when /^.*Unit\s+Bay\s+Status\s+Type\s+FanStatus.*$/
            #Puppet.debug("Power Line: #{line}")
            found = true
          when /^.*(\d+)\s+(\d+)\s+(\S+)\s+(\S+)\s+(\S+).*$/
            #Puppet.debug("Power Status Line: #{line}")
            if found then
              power_status = $3.strip
              if power_status =~ /up/i then
                #Puppet.debug("Unit: #{$1}-----Power status: #{$3}")
                break
              end
            end
          when /^.*Unit\s+Bay\s+TrayStatus.*$/
            #Puppet.debug("Fan Line: #{line}")
            break
          else
            next
          end
        end
        power_status
      end
      cmd CMD_SHOW_SYSTEM_BRIEF
    end

    # Display Layer 2 information about the interfaces in json format.
    base.register_param 'interfaces' do
      interfaces = {}
      interface = nil
      match do |txt|
        txt.each_line do |line|
          case line
          when /^Name:\s+(.*)/
            #Puppet.debug("Name: #{$1}")
            interface = { :name => $1.strip, :description =>"", :untagged_vlan => "", :tagged_vlan => ""}
            interfaces[interface[:name]] = interface
          when /^Description:\s+(.*)/
            raise "Invalid show interfaces switchport output" unless interface
            #Puppet.debug("Description: #{$1}")
            interface[:description] = $1.strip
          when /^(U)\s+(.*)/
            raise "Invalid show interfaces switchport output" unless interface
            #Puppet.debug("#{$1} untagged_vlan #{$2}")
            interface[:untagged_vlan] = $2.strip
          when /^(T)\s+(.*)/
            raise "Invalid show interfaces switchport output" unless interface
            #Puppet.debug("#{$1} tagged_vlan #{$2}")
            interface[:tagged_vlan] = $2.strip
          else
            next
          end
        end
        interfaces.to_json
      end
      cmd CMD_SHOW_INTERFACES
    end

    # Display VLAN configuration in JSON format
    base.register_param 'vlans' do
      vlans = {}
      vlan = nil
      match do |txt|
        txt.each_line do |line|
          case line
          # codes, num, status, desc, qualifier, ports
          when /^(\*|\s)\s+(\d+)\s+(\S+\b)\s+(.*)\s+(U|T|x|X|G|M|H|i|I|v|V)\s+(.*$)/
            #Puppet.debug("VLAN: #{$2}")
            vlan = { :id => $2.strip, :status => $3.strip, :description => $4.strip,  :interfaces => [] }
            vlan[:interfaces] = $5.strip+" "+$6.strip+"|"
            vlans[vlan[:id]] = vlan
            # codes, num, status, desc
          when /^(\*|\s)\s+(\d+)\s+(\S+\b)\s+(.*)+$/
            #Puppet.debug("VLAN: #{$2}")
            vlan = { :id => $2.strip, :status => $3.strip, :description =>$4.strip,  :interfaces => ""}
            vlans[vlan[:id]] = vlan
            # qualifier, ports
          when /^\s*(U|T|x|X|G|M|H|i|I|v|V)\s*([^\-]\b.*$)/
            #Puppet.debug("Interface: #{$2}")
            raise "Invalid show vlan output" unless vlan
            vlan[:interfaces] += $1.strip+" "+$2.strip+"|"
          else
            next
          end
        end
        vlans.to_json
      end
      cmd CMD_SHOW_VLAN
    end

    #Display information on configured Port Channel groups in JSON Format
    base.register_param 'port_channels' do
      port_channels = {}
      port_channel = nil
      match do |txt|
        txt.each_line do |line|
          case line
          when /^.*LAG\s+Mode\s+Status\s+Uptime\s+Ports.*$/
            #Puppet.debug("starting: #{line}")
            next
          when /^(L*)\s+(\d+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+\s+\d+\/\d+)\s+(\S+).*$/
            #Puppet.debug("port_channels with ports: #{line}")
            lacp = "true"
            if $1.nil? || $1.empty? then
              lacp = "false"
            end
            port_channel = { :port_channel => $2.strip, :lacp => lacp, :mode => $3.strip,:status => $4.strip,:uptime => $5.strip,:ports => [] }
            port_channel[:ports] = $6.strip+" "+$7.strip
            port_channels[port_channel[:port_channel]] = port_channel
          when /^(L*)\s+(\d+)\s+(\S+)\s+(\S+)\s+(\S+)\s+.*$/
            #Puppet.debug("port_channels with no ports: #{line}")
            lacp = "true"
            if $1.nil? || $1.empty? then
              lacp = "false"
            end
            port_channel = { :port_channel => $2.strip, :lacp => lacp, :mode => $3.strip,:status => $4.strip,:uptime => $5.strip, :ports => "" }
            #port_channel[:ports] = $6.strip
            port_channels[port_channel[:port_channel]] = port_channel
          when /^\s+(\S+\s+\d+\/\d+)\s+(\S+).*$/
            raise "Invalid show interfaces port-channel brief" unless port_channel
            #Puppet.debug("ports: #{line}")
            port_channel[:ports] += ","+$1.strip+" "+$2.strip
          else
            next
          end
        end
        port_channels.to_json
      end
      cmd CMD_SHOW_PORT_CHANNELS
    end

    #Display LLDP neighbor information for all interfaces in JSON Format
    #    base.register_param 'remote_device_info' do
    #      remote_device_info = {}
    #      remote_device = nil
    #      match do |txt|
    #        txt.each_line do |line|
    #          case line
    #          when /^.*Local\s+Interface\s+(.*)\s+has.*$/
    #            #Puppet.debug("starting: #{line}")
    #            remote_device = { :local_interface => $1.strip, :local_port_id => "", :remote_port_id => "",:remote_mac_address => "",:remote_system_name => ""}
    #            remote_device_info[remote_device[:local_interface]] = remote_device
    #          when /^.*Remote Chassis ID:\s+(.*)$/
    #            raise "show lldp neighbors detail output" unless remote_device
    #            #Puppet.debug("remote_mac_address: #{$1}")
    #            remote_device[:remote_mac_address] = $1.strip
    #          when /^.*Remote Port ID:\s+(.*)$/
    #            raise "show lldp neighbors detail output" unless remote_device
    #            #Puppet.debug("remote_port_id: #{$1}")
    #            remote_device[:remote_port_id] = $1.strip
    #          when /^.*Local Port ID:\s+(.*)$/
    #            raise "show lldp neighbors detail output" unless remote_device
    #            #Puppet.debug("local_port_id: #{$1}")
    #            remote_device[:local_port_id] = $1.strip
    #          when /^.*Remote System Name:\s+(.*)$/
    #            raise "show lldp neighbors detail output" unless remote_device
    #            #Puppet.debug("remote_system_name: #{$1}")
    #            remote_device[:remote_system_name] = $1.strip
    #          else
    #            next
    #          end
    #        end
    #        remote_device_info.to_json
    #      end
    #      cmd CMD_SHOW_LLDP_NEIGHBORS
    #    end

    #Display LLDP neighbor information for all interfaces in JSON Format
    base.register_param 'remote_device_info' do
      remote_device_info = {}
      remote_device = nil
      match do |txt|
        txt.each_line do |line|
          case line
          when /^\s+(\S+\s+\d+\/\d+)\s+(\S+)\s+(.*)\s+(([0-9a-fA-F]{2}[:-]){5}([0-9a-fA-F]{2})).*$/
            #Puppet.debug("remote device info: #{line}")
            #remote_device = { :local_interface => $1.strip, :local_port_id => "", :remote_port_id => $3.strip,:remote_mac_address => $4.strip,:remote_system_name => $2.strip}
            #remote_device_info[remote_device[:local_interface]] = remote_device
            remote_device = { :interface => $1.strip, :location => $3.strip,:remote_mac => $4.strip,:remote_system_name => $2.strip}
            remote_device_info[remote_device[:interface]] = remote_device
          else
            next
          end
        end
        remote_device_info.to_json
      end
      cmd CMD_SHOW_LLDP_NEIGHBORS1
    end

    base.register_param 'startup_config_version' do
      match /^.*Version\s(.*$)/
      cmd CMD_SHOW_STARTUP_CONFIG_VERSION
    end

    base.register_param 'running_config_version' do
      match /^.*Version\s(.*$)/
      cmd CMD_SHOW_RUNNING_CONFIG_VERSION
    end

  end
end

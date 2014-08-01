require 'puppet/util/network_device/dell_ftos/possible_facts'
require 'puppet/util/network_device/dell_ftos/possible_facts/hardware'

module Puppet::Util::NetworkDevice::Dell_ftos::PossibleFacts::Hardware::S_series

  # Module Constants
  CMD_SHOW_SYSTEM_BRIEF="show system brief" unless const_defined?(:CMD_SHOW_SYSTEM_BRIEF)

  CMD_SHOW_VLAN  ="show vlan" unless const_defined?(:CMD_SHOW_VLAN)

  CMD_SHOW_INTERFACES  ="show interfaces switchport" unless const_defined?(:CMD_SHOW_INTERFACES)

  CMD_SHOW_PORT_CHANNELS  ="show interfaces port-channel brief" unless const_defined?(:CMD_SHOW_PORT_CHANNELS)

  #CMD_SHOW_LLDP_NEIGHBORS  ="show lldp neighbors detail" unless const_defined?(:CMD_SHOW_LLDP_NEIGHBORS)

  CMD_SHOW_LLDP_NEIGHBORS  ="show lldp neighbors" unless const_defined?(:CMD_SHOW_LLDP_NEIGHBORS)

  CMD_SHOW_STARTUP_CONFIG_VERSION="show startup-config | grep \"! Version\"" unless const_defined?(:CMD_SHOW_STARTUP_CONFIG_VERSION)

  CMD_SHOW_RUNNING_CONFIG_VERSION="show running-config | grep \"! Version\"" unless const_defined?(:CMD_SHOW_RUNNING_CONFIG_VERSION)
  
  CMD_FC_MODE="show fc switch" unless const_defined?(:CMD_FC_MODE)    

  CMD_SHOW_FC_NEIGHBORS="show fc ns fabric" unless const_defined?(:CMD_SHOW_FC_NEIGHBORS)
    
  CMD_SHOW_ACTIVE_ZONESET="show fc zoneset" unless const_defined?(:CMD_SHOW_ACTIVE_ZONESET)
  
  CMD_SHOW_DCB_MAP="show running-config dcb-map" unless const_defined?(:CMD_SHOW_DCB_MAP)
  CMD_SHOW_FCOE_MAP="show running-config fcoe-map" unless const_defined?(:CMD_SHOW_FCOE_MAP)
          
  def self.register(base)

    base.register_param 'system_description' do
      match do |system_type,hostname|
        #Puppet.debug("system_type: #{system_type}")
        #Puppet.debug("hostname: #{hostname}")
        "Dell Force10 #{system_type} System" unless system_type.nil?
      end
      cmd false
      match_param [ 'system_type','hostname']
      after 'system_type'
    end

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
            interface = { :name => $1.strip, :description =>"", :untagged_vlans => "", :tagged_vlans => ""}
            interfaces[interface[:name]] = interface
          when /^Description:\s+(.*)/
            raise "Invalid show interfaces switchport output" unless interface
            #Puppet.debug("Description: #{$1}")
            interface[:description] = $1.strip
          when /^(U)\s+(.*)/
            raise "Invalid show interfaces switchport output" unless interface
            #Puppet.debug("#{$1} untagged_vlans #{$2}")
            interface[:untagged_vlans] = $2.strip
          when /^(T)\s+(.*)/
            raise "Invalid show interfaces switchport output" unless interface
            #Puppet.debug("#{$1} tagged_vlans #{$2}")
            interface[:tagged_vlans] = $2.strip
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
      cmd CMD_SHOW_LLDP_NEIGHBORS
    end

    base.register_param 'startup_config_version' do
      match /^.*Version\s(.*$)/
      cmd CMD_SHOW_STARTUP_CONFIG_VERSION
    end

    base.register_param 'running_config_version' do
      match /^.*Version\s(.*$)/
      cmd CMD_SHOW_RUNNING_CONFIG_VERSION
    end
    
    base.register_param 'switch_fc_mode' do
      match /^.*Switch Mode\s:\s+(.*$)/
      cmd CMD_FC_MODE
    end
    
    base.register_param 'switch_fc_active_zoneset' do
      match /^.*Active Zoneset:\s+(.*$)/
      cmd CMD_SHOW_ACTIVE_ZONESET
    end
    
    base.register_param 'dcb-map' do
      match /^.*dcb-map\s+(.*$)/
      cmd CMD_SHOW_DCB_MAP
    end
    
    base.register_param 'fcoe-map' do
      match /^.*fcoe-map\s+(.*$)/
      cmd CMD_SHOW_FCOE_MAP
    end
    
    base.register_param 'remote_fc_device_info' do
      remote_device_info = {}
      remote_device = nil
      output = ""
      match do |txt|
        txt.each_line do |line|
          output << line
        end
        results = output.scan(/(Switch Name.*?Port Type\s+\S+)/m)
        fc_device_info = {}
        (results || []).each_with_index do |result,index|
          fc_info = {}
          fc_info['switch_name']=result[0].scan(/Switch Name\s+(\S+)/)[0][0]
          fc_info['domain_id']=result[0].scan(/Domain Id\s+(\d+)/)[0][0]
          fc_info['port_name']=result[0].scan(/Port Name\s+(\S+)/)[0][0]
          fc_info['node_name']=result[0].scan(/Node Name\s+(\S+)/)[0][0]
          fc_info['cos'] =result[0].scan(/Class of Service\s+(\d+)/)[0][0]
          fc_info['sym_port_name'] = result[0].scan(/Symbolic Port Name\s+(.*)?$/)[0][0]
          fc_info['port_type'] = result[0].scan(/Port Type\s+(\S+)/)[0][0]
          fc_device_info[index] = fc_info
        end
        fc_device_info.to_json
      end
      cmd CMD_SHOW_FC_NEIGHBORS
    end

  end
end

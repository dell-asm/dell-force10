require 'puppet_x/force10/possible_facts'
require 'puppet_x/force10/possible_facts/hardware'

module PuppetX::Force10::PossibleFacts::Hardware::M_series

  # Module Constants
  CMD_SHOW_SYSTEM_STACK_UNIT = "show system stack-unit" unless const_defined?(:CMD_SHOW_SYSTEM_STACK_UNIT)
  CMD_SHOW_INTERFACES = "show interface status" unless const_defined?(:CMD_SHOW_INTERFACES)
  CMD_SHOW_INVENTORY_MEDIA = "show inventory media" unless const_defined?(:CMD_SHOW_INVENTORY_MEDIA)
  CMD_SHOW_DCB_MAP="show running-config dcb-map" unless const_defined?(:CMD_SHOW_DCB_MAP)
  CMD_SHOW_FCOE_MAP="show running-config fcoe-map" unless const_defined?(:CMD_SHOW_FCOE_MAP)
  CMD_SHOW_PORT_CHANNELS  ="show interfaces port-channel brief" unless const_defined?(:CMD_SHOW_PORT_CHANNELS)
  CMD_SHOW_QUAD_MODE_INTERFACES  ="show running-config | grep \"portmode quad\"" unless const_defined?(:CMD_SHOW_QUAD_MODE_INTERFACES)
  CMD_SHOW_RUNNING_INTERFACE ="show running-config interface" unless const_defined?(:CMD_SHOW_RUNNING_INTERFACE)
  CMD_SHOW_SYSTEM_STACK_UNIT_IOM = 'show system stack-unit 0 iom-mode' unless const_defined?(:CMD_SHOW_SYSTEM_STACK_UNIT_IOM)
  CMD_RUNNING_CONFIG = 'show running-config' unless const_defined?(:CMD_RUNNING_CONFIG)
  CMD_STACK_PORT_TOPOLOGY = 'show system stack-port topology' unless const_defined?(:CMD_STACK_PORT_TOPOLOGY)
  CMD_SHOW_LLDP_NEIGHBORS  ="show lldp neighbors" unless const_defined?(:CMD_SHOW_LLDP_NEIGHBORS)

  def self.register(base)

    # system_management_unit is expected to be populated before this registration
    # Puppet.debug("system_management_unit: #{base.facts['system_management_unit'].value }")
    unit_number = base.facts['system_management_unit'].value
    if unit_number.nil? || unit_number.empty? then
      # if not available default to 0
      unit_number="0"
    end

    base.register_param 'system_description' do
      match do |system_type,hostname|
        #Puppet.debug("system_type: #{system_type}")
        #Puppet.debug("hostname: #{hostname}")
        unless system_type.nil?
          if system_type =~ /I\/O-Aggregator/i then
            "Dell PowerEdge M I/O Aggregator"
          elsif system_type  =~ /MXL/i then
            "Dell Force10 MXL 10/40GbE Switch IO Module"
          else
            system_type
          end
        end
      end
      cmd false
      match_param [ 'system_type','hostname']
      after 'system_type'
    end

    base.register_param 'system_power_status' do
      power_status = 'Unknown'
      match do |txt|
        item = txt.scan(/^.*Switch Power\s*:\s+(.*)$/).flatten.first
        status = item.strip unless item.nil?
        #Puppet.debug("Switch Power: #{status}")
        if status =~ /GOOD/i then
          power_status = 'up'
        elsif status =~ /BAD/i then
          power_status = 'down'
        end
      end
      cmd CMD_SHOW_SYSTEM_STACK_UNIT+" "+unit_number
    end

    base.register_param 'asset_tag' do
      match do |txt|
        item = txt.scan(/^.*Asset tag\s*:\s+(.*)$/).flatten.first
        #Puppet.debug("Asset Tag: #{item}")
        asset_tag = item.strip unless item.nil?
        if asset_tag !~ /PSOC/ then
          asset_tag
        end
      end
      cmd CMD_SHOW_SYSTEM_STACK_UNIT+" "+unit_number
    end

    base.register_param 'product_name' do
      match do |txt|
        item = txt.scan(/^.*Product Name\s*:\s+(.*)$/).flatten.first
        item.strip unless item.nil?
      end
      cmd CMD_SHOW_SYSTEM_STACK_UNIT+" "+unit_number
    end

    base.register_param 'fabric_id' do
      match do |txt|
        item = txt.scan(/^.*Fabric Id\s*:\s+(.*)$/).flatten.first
        item.strip unless item.nil?
      end
      cmd CMD_SHOW_SYSTEM_STACK_UNIT+" "+unit_number
    end

    base.register_param 'chassis_service_tag' do
      match do |txt|
        item = txt.scan(/^.*Chassis Svce Tag\s*:\s+(.*)$/).flatten.first
        item.strip unless item.nil?
      end
      cmd CMD_SHOW_SYSTEM_STACK_UNIT+" "+unit_number
    end

    base.register_param 'interfaces' do
      match do |txt|
        item = txt.scan(/^(\S+\s+\d+\/\d+)/m).flatten
        #item.strip unless item.nil?
      end
      cmd CMD_SHOW_INTERFACES
    end


    base.register_param 'modules' do
      match do |txt|
        item = txt.scan(/^\s+(\d+)\s+(\d+)\s+(\S+)\s+(\S+)\s+(\S+).*?Yes/)
        #item.strip unless item.nil?
      end
      cmd CMD_SHOW_INVENTORY_MEDIA
    end

    base.register_param 'dcb-map' do
      match do |txt|
        item = txt.scan(/!\s*dcb-map\s+(.*$)/).flatten
      end
      cmd CMD_SHOW_DCB_MAP
    end

    base.register_param 'fcoe-map' do
      match do |txt|
        item = txt.scan(/!\s.*fcoe-map\s+(.*$)/).flatten
      end
      cmd CMD_SHOW_FCOE_MAP
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

    #Display information on configured Port Channel groups in JSON Format
    base.register_param 'port_channel_members' do
      match do |txt|
        port_channels = {}
        interfaces = (txt.scan(/(!\s+interface\s+.*?shutdown\s+)/m) || [] ).flatten
        interfaces.each do |interface_detail|
          if interface_detail.match(/^interface\s+(\w+\s+\d+\/\d+).*port-channel\s+(\d+)/m)
            port_channels[$2.strip] ||= []
            port_channels[$2.strip].push($1.strip)
          end
          if interface_detail.match(/channel-member\s+(.*)/m)
            type, port_strings = $1.split
            prefix = ""
            ports = []
            port_strings.split(",").each do |port_string|
              port_id = port_string
              if port_string.include?("/")
                prefix = "%s" % port_string.split("/").first
              else
                port_id = "%s/%s" % [prefix, port_string]
              end
              ports << "%s %s" % [type, port_id]
            end
            port_channel = interface_detail.scan(/port-channel\s+(\d+)/im).flatten.first
            port_channels[port_channel] ||= []
            port_channels[port_channel].concat(ports)
          end
        end
        port_channels.to_json
      end
      cmd CMD_SHOW_RUNNING_INTERFACE
    end

    base.register_param 'quad_port_interfaces' do
      retval = []
      match do |txt|
        item = (txt.scan(/port\s+(\d+)/) || []).flatten
      end
      cmd CMD_SHOW_QUAD_MODE_INTERFACES
    end

    base.register_param 'flexio_modules' do
      flexio_module_info = {}
      module1_interfaces = 33..40
      module2_interfaces = 41..48
      module3_interfaces = 49..56
      module1_interface = []
      module2_interface = []
      module3_interface = []
      interface_info = {}
      match do |txt|
        base.facts['product_name'].value.match(/IOA|PE-FN|Dell PowerEdge FN/) ? module1_interfaces = 9..12 : module1_interfaces = 33..40
        txt.each_line do |line|
          case line
          when /^(\S+)\s+(\d+)\/(\d+)/m
            if module1_interfaces.include?($3.strip.to_i)
              module1_interface.push("#{$1} #{$2}/#{$3}")
            end
            if module2_interfaces.include?($3.strip.to_i)
              module2_interface.push("#{$1} #{$2}/#{$3}")
            end
            if module3_interfaces.include?($3.strip.to_i)
              module3_interface.push("#{$1} #{$2}/#{$3}")
            end
            next
          end
        end
        interface_info[:module1_interface] = module1_interface.flatten
        interface_info[:module2_interface] = module2_interface.flatten
        interface_info[:module3_interface] = module3_interface.flatten
        interface_info.to_json
      end
      cmd CMD_SHOW_INTERFACES
    end

    base.register_param 'iom_mode' do
      retval = []
      match do |txt|
        item = (txt.scan(/^\d+\s+(\S+)/) || []).flatten.first
      end
      cmd CMD_SHOW_SYSTEM_STACK_UNIT_IOM
    end

    base.register_param 'running_config' do
      match do |txt|
        item = txt
      end
      cmd CMD_RUNNING_CONFIG
    end

    base.register_param 'ioa_ethernet_mode' do
      match do |txt|
        txt = (txt.scan(/(stack-unit 0 port-group 0 portmode ethernet)/) || []).flatten.first
      end
      cmd CMD_RUNNING_CONFIG
    end

    base.register_param 'stack_port_topology' do
      match do |txt|
        txt = (txt.scan(/Topology:\s*(.*)?/) || []).flatten.first
      end
      cmd CMD_STACK_PORT_TOPOLOGY
    end

    base.register_param 'stack_port_topology' do
      match do |txt|
        txt = (txt.scan(/Topology:\s*(.*)?/) || []).flatten.first
      end
      cmd CMD_STACK_PORT_TOPOLOGY
    end

    base.register_param 'stack_unit_0' do
      match do |txt|
        item = txt
      end
      cmd 'show system stack-unit 0'
    end

    base.register_param 'stack_unit_1' do
      match do |txt|
        item = txt
      end
      cmd 'show system stack-unit 1'
    end

    base.register_param 'stack_unit_2' do
      match do |txt|
        item = txt
      end
      cmd 'show system stack-unit 2'
    end

    base.register_param 'stack_unit_3' do
      match do |txt|
        item = txt
      end
      cmd 'show system stack-unit 3'
    end

    base.register_param 'stack_unit_4' do
      match do |txt|
        item = txt
      end
      cmd 'show system stack-unit 4'
    end

    base.register_param 'stack_unit_5' do
      match do |txt|
        item = txt
      end
      cmd 'show system stack-unit 5'
    end

    base.register_param 'remote_device_info' do
      remote_device_info = []
      remote_device = nil
      match do |txt|
        txt.each_line do |line|
          case line
            when /^\s+(\S+\s+\d+\/\d+)\s+([^\.{3}\s]+)\s*\.{0,3}(.*)\s+(([0-9a-fA-F]{2}[:-]){5}([0-9a-fA-F]{2})).*$/
              remote_device = { :interface => $1.strip, :location => $3.strip,:remote_mac => $4.strip,:remote_system_name => $2.strip}
              remote_device_info <<  remote_device
            else
              next
          end
        end
        remote_device_info.uniq.to_json
      end
      cmd CMD_SHOW_LLDP_NEIGHBORS
    end

  end
end

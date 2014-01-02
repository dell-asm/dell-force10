require 'pp'
require 'json'
require 'puppet/util/network_device/dell_ftos/possible_facts'

module Puppet::Util::NetworkDevice::Dell_ftos::PossibleFacts::Base

  # Module Constants
  CMD_SHOW_INVENTORY = "show inventory"

  CMD_SHOW_VERSION = "show version"

  CMD_SHOW_ENVIRONMENT = "show environment"

  CMD_SHOW_VLAN  ="show vlan"

  CMD_SHOW_INTERFACES  ="show interfaces switchport"

  CMD_SHOW_SYSTEM_BRIEF="show system brief"

  CMD_SHOW_IP_INTERFACE_BRIEF="show ip interface brief"

  CMD_SHOW_STARTUP_CONFIG_VERSION="show startup-config | grep \"! Version\""

  CMD_SHOW_RUNNING_CONFIG_VERSION="show running-config | grep \"! Version\""
  def self.register(base)

    base.register_param ['hostname', 'uptime'] do
      match /^\s*([\w-]+)\s+uptime is (.*?)$/
      cmd CMD_SHOW_VERSION
    end

    base.register_param 'uptime_seconds' do
      match do |uptime|
        #uptime_to_seconds(uptime)
      end
      cmd false
      match_param 'uptime'
      after 'uptime'
    end

    base.register_param 'uptime_days' do
      match do |uptime_seconds|
        (uptime_seconds / 86400) if uptime_seconds
      end
      cmd false
      match_param 'uptime_seconds'
      after 'uptime_seconds'
    end

    base.register_param 'management_ip' do
      match do |txt|
        item = txt.scan(/ManagementEthernet\s\d+\/\d+\s+((?:\d{1,3}\.){3}\d{1,3})\s+.*/).flatten.first
        item.strip unless item.nil?
      end
      cmd CMD_SHOW_IP_INTERFACE_BRIEF
    end

    base.register_param '34_port_interfaces' do
      #match /(.*)\s34-port GE\/TE \(XL\)/
      match do |txt|
        item = txt.scan(/(\d*)\s34-port/).flatten.first
        item.strip unless item.nil?
      end
      cmd CMD_SHOW_VERSION
    end

    base.register_param '48_port_interfaces' do
      #match /(.*)\s48-port E\/FE\/GE \(SD\)/
      match do |txt|
        item = txt.scan(/(\d*)\s48-port/).flatten.first
        item.strip unless item.nil?
      end
      cmd CMD_SHOW_VERSION
    end

    base.register_param '52_port_interfaces' do
      #match /(.*)\s52-port GE\/TE\/FG \(SE\)/
      match do |txt|
        item = txt.scan(/(\d*)\s52-port/).flatten.first
        item.strip unless item.nil?
      end
      cmd CMD_SHOW_VERSION
    end

    base.register_param 'gigabit_ethernet_interfaces' do
      #match /(.*)\sGigabitEthernet/
      match do |txt|
        item = txt.scan(/(\d*)\sGigabitEthernet/).flatten.first
        item.strip unless item.nil?
      end
      cmd CMD_SHOW_VERSION
    end

    base.register_param 'ten_gigabit_ethernet_interfaces' do
      #match /(.*)\sTen GigabitEthernet/
      match do |txt|
        item = txt.scan(/(\d*)\sTen GigabitEthernet/).flatten.first
        item.strip unless item.nil?
      end
      cmd CMD_SHOW_VERSION
    end

    base.register_param 'forty_gigabit_ethernet_interfaces' do
      #match /(.*)\sForty GigabitEthernet/
      match do |txt|
        item = txt.scan(/(\d*)\sForty GigabitEthernet/).flatten.first
        item.strip unless item.nil?
      end
      cmd CMD_SHOW_VERSION
    end

    base.register_param 'stack_mac' do
      match /^.*Stack MAC\s\:\s(\S+).*/
      cmd CMD_SHOW_SYSTEM_BRIEF
    end

    base.register_param 'system_management_unit_status' do
      match /^.*Management\s*(\w*\b).*/
      cmd CMD_SHOW_SYSTEM_BRIEF
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
              if power_status.to_s.eql?('up') then
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

    base.register_param ['system_management_unit_serial_number','system_management_unit_part_number','system_management_unit_service_tag'] do
      match /^\*\s+\d+\s+\S+\s+(\S+)\s+(\S+)\s+\S+\s+\S+\s+\S+\s+(\S+)\s+.*$/
      cmd CMD_SHOW_INVENTORY
    end

    base.register_param 'system_image' do
      match /^System image file is\s*"(.*)"/
      cmd CMD_SHOW_VERSION
    end

    base.register_param 'dell_force10_operating_system_version' do
      match /^Dell\s+Force10\s+Operating\s+System\s+Version:\s+(\S+)$/
      cmd CMD_SHOW_VERSION
    end

    base.register_param 'dell_force10_application_software_version' do
      match /^Dell\s+Force10\s+Application\s+Software\s+Version:\s+(\S+)$/
      cmd CMD_SHOW_VERSION
    end

    base.register_param 'system_type' do
      match /^System\s+Type:\s+(\S+)\s+$/
      cmd CMD_SHOW_VERSION
    end

    base.register_param 'control_processor' do
      match /^Control\s+Processor:\s+(.*?)$/
      cmd CMD_SHOW_VERSION
    end

    base.register_param 'system_mode' do
      match /^System\s+Mode\s+:\s+(\S+)\s+$/
      cmd CMD_SHOW_INVENTORY
    end

    base.register_param 'software_protocol_configured' do
      match do |txt|
        res = Hash.new
        txt.split(/^$/).map do |line|
          if line =~ /^Software\s+Protocol\s+Configured\s+$/ then
            count=0
            line.split(/\r?\n/).map do |item|
              #Puppet.debug("Item******: OUT #{item}")
              #removed "-" since it is valid char in protocol like Spanning-Tree
              special = "?<>',?[]}{=)(*&^%$#`~{}"
              regexspecial = /[#{special.gsub(/./){|char| "\\#{char}"}}]/
              if item.nil? || item.empty? || item =~ regexspecial || item =~ /^Software\s+Protocol\s+Configured\s+$/ || item =~ /^\s+$/ || item =~ /^-{2,}+$/ then
                next
              else
                #Puppet.debug("Match Protocol******: OUT #{item}")
                count=count+1
                res["software_protocol_configured_#{count}"] = item.strip
              end
            end
          end
        end
        res
      end
      cmd CMD_SHOW_INVENTORY
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

    base.register_param 'startup_config_version' do
      match /^.*Version\s(.*$)/
      cmd CMD_SHOW_STARTUP_CONFIG_VERSION
    end

    base.register_param 'running_config_version' do
      match /^.*Version\s(.*$)/
      cmd CMD_SHOW_RUNNING_CONFIG_VERSION
    end

    base.register_module_after 'system_type', 'ioa', 'hardware' do
      base.facts['system_type'].value =~ /I\/O-Aggregator/
    end

    base.register_module_after 'system_type', 'mxl', 'hardware' do
      base.facts['system_type'].value =~ /MXL/
    end

  end

end

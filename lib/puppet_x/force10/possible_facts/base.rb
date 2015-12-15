require 'json'
require 'puppet_x/force10/possible_facts'

module PuppetX::Force10::PossibleFacts::Base

  # Module Constants
  CMD_SHOW_INVENTORY = "show inventory" unless const_defined?(:CMD_SHOW_INVENTORY)

  CMD_SHOW_VERSION = "show version" unless const_defined?(:CMD_SHOW_VERSION)

  CMD_SHOW_ENVIRONMENT = "show environment" unless const_defined?(:CMD_SHOW_ENVIRONMENT)

  CMD_SHOW_SYSTEM_BRIEF="show system brief" unless const_defined?(:CMD_SHOW_SYSTEM_BRIEF)
    
  CMD_SHOW_HOSTNAME="show running-config | grep hostname" unless const_defined?(:CMD_SHOW_HOSTNAME)
   
  CMD_SHOW_IP_INTERFACE_BRIEF="show ip interface brief | grep ManagementEthernet" unless const_defined?(:CMD_SHOW_IP_INTERFACE_BRIEF)
    
  CMD_SHOW_PORTCHANNEL_BRIEF="show interface port-channel brief" unless const_defined?(:CMD_SHOW_PORTCHANNEL_BRIEF)

  CMD_SHOW_RUNNING_INTERFACE ="show running-config interface" unless const_defined?(:CMD_SHOW_RUNNING_INTERFACE)
      
  def self.register(base)

    base.register_param 'hostname' do
      match /^hostname\s+(\S+)$/
      cmd CMD_SHOW_HOSTNAME
    end
        
    base.register_param 'uptime' do
      match /uptime is (.*?)$/
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
    base.transport.host
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
      match /^.*Stack MAC\s*\:\s*(\S+).*/
      cmd CMD_SHOW_SYSTEM_BRIEF
    end

    base.register_param 'system_management_unit_status' do
      match /^.*Management\s*(\w*\b).*/
      cmd CMD_SHOW_SYSTEM_BRIEF
    end

    base.register_param ['system_management_unit','system_management_unit_serial_number','system_management_unit_part_number','system_management_unit_service_tag'] do
      match /^\*\s+(\d+)\s+\S+\s+(\S+)\s+(\S+)\s+\S+\s+\S+\s+\S+\s+(\S+)\s+.*$/
      cmd CMD_SHOW_INVENTORY
    end

    base.register_param 'system_image' do
      match /^System image file is\s*"(.*)"/
      cmd CMD_SHOW_VERSION
    end

    base.register_param 'operating_system' do
      match do |txt|
        item = txt.split(/\r?\n/).select{ |s| s[/Dell/i] }.first
        item.strip unless item.nil?
      end
      cmd CMD_SHOW_VERSION
    end

    base.register_param 'dell_force10_operating_system_version' do
      match do |txt|
        version = txt.scan(/^Dell\s+Force10\s+Operating\s+System\s+Version:\s+(\S+)$|Dell Operating System Version:\s+(.*?)$/m).flatten.compact.first
      end
      cmd CMD_SHOW_VERSION
    end

    base.register_param 'dell_force10_application_software_version' do
      match do |txt|
        version = txt.scan(/^Dell\s+Force10\s+Application\s+Software\s+Version:\s+(\S+)$|Dell Application Software Version:\s+(.*?)$/m).flatten.compact.first
      end
      cmd CMD_SHOW_VERSION
    end

    base.register_param 'system_type' do
      match /^System\s+Type:\s+(\S+)\s+$/
      cmd CMD_SHOW_VERSION
    end

    base.register_param ['control_processor', 'control_processor_memory'] do
      match /^Control\s+Processor:\s*(.*)\s+with\s*(.*)\s+of.*$/
      cmd CMD_SHOW_VERSION
    end

    base.register_param 'boot_flash_memory' do
      match /^(.*)\s+of boot flash memory.*$/
      cmd CMD_SHOW_VERSION
    end

    base.register_param 'system_mode' do
      match /^System\s+Mode\s+:\s+(\S+)\s+$/
      cmd CMD_SHOW_INVENTORY
    end

    base.register_param 'software_protocol_configured' do
      match do |txt|
        res = {}
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
                #res["software_protocol_configured_#{count}"] = item.strip
                res["protocol_#{count}"] = item.strip
              end
            end
          end
        end
        res.to_json
        #res
      end
      cmd CMD_SHOW_INVENTORY
    end

    #Display information on configured Port Channel groups in JSON Format
    base.register_param 'vlan_information' do
      vlan_information = {}
      match do |txt|
        interfaces = (txt.scan(/((!\s+interface\s+Vlan\s+\d+.*?shutdown\s+))/m) || [] ).flatten
        interfaces.each do |interface_detail|
          interface_location = interface_detail.scan(/^interface Vlan\s+(\d+)/).flatten.first
          vlan_information[interface_location] ||= {}
          vlan_information[interface_location]['tagged_tengigabit'] ||= {}
          vlan_information[interface_location]['untagged_tengigabit'] ||= {}
          vlan_information[interface_location]['tagged_fortygigabit'] ||= {}
          vlan_information[interface_location]['untagged_fortygigabit'] ||= {}
          vlan_information[interface_location]['tagged_portchannel'] ||= {}
          vlan_information[interface_location]['untagged_portchannel'] ||= {}

          if interface_detail.match(/^\stagged\s+TenGigabitEthernet\s+(.*?)$/mi)
            vlan_information[interface_location]['tagged_tengigabit'] = $1
          end

          if interface_detail.match(/^\stagged\s+Port-channel\s+(.*?)$/mi)
            vlan_information[interface_location]['tagged_portchannel'] = $1
          end

          if interface_detail.match(/^\suntagged\s+TenGigabitEthernet\s+(.*?)$/mi)
            vlan_information[interface_location]['untagged_tengigabit'] = $1
          end

          if interface_detail.match(/^\suntagged\s+Port-channel\s+(.*?)$/mi)
            vlan_information[interface_location]['untagged_portchannel'] = $1
          end

          if interface_detail.match(/^\stagged\s+FortyGigE\s+(.*?)$/mi)
            vlan_information[interface_location]['tagged_fortygigabit'] = $1
          end

          if interface_detail.match(/^\suntagged\s+FortyGigE\s+(.*?)$/mi)
            vlan_information[interface_location]['untagged_fortygigabit'] = $1
          end
        end
        vlan_information.to_json
      end
      cmd CMD_SHOW_RUNNING_INTERFACE
    end
    
    

    base.register_module_after 'system_type', 's_series', 'hardware' do
      base.facts['system_type'].value =~ /S48*/i ||  base.facts['system_type'].value =~ /S5000/i ||  base.facts['system_type'].value =~ /S6000/i
    end

    base.register_module_after 'system_type', 'm_series', 'hardware' do
      base.facts['system_type'].value =~ /I\/O-Aggregator|IOA/i || base.facts['system_type'].value =~ /MXL/i
    end

    base.register_module_after 'vlan_information', 'ioa', 'hardware' do
      base.facts['system_type'].value =~ /I\/O-Aggregator|IOA/i
    end

  end

end

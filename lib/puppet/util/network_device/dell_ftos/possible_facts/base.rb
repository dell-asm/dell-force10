require 'json'
require 'puppet/util/network_device/dell_ftos/possible_facts'

module Puppet::Util::NetworkDevice::Dell_ftos::PossibleFacts::Base

  # Module Constants
  CMD_SHOW_INVENTORY = "show inventory" unless const_defined?(:CMD_SHOW_INVENTORY)

  CMD_SHOW_VERSION = "show version" unless const_defined?(:CMD_SHOW_VERSION)

  CMD_SHOW_ENVIRONMENT = "show environment" unless const_defined?(:CMD_SHOW_ENVIRONMENT)

  CMD_SHOW_SYSTEM_BRIEF="show system brief" unless const_defined?(:CMD_SHOW_SYSTEM_BRIEF)

  CMD_SHOW_IP_INTERFACE_BRIEF="show ip interface brief | grep ManagementEthernet" unless const_defined?(:CMD_SHOW_IP_INTERFACE_BRIEF)
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

    base.register_param ['system_management_unit','system_management_unit_serial_number','system_management_unit_part_number','system_management_unit_service_tag'] do
      match /^\*\s+(\d+)\s+\S+\s+(\S+)\s+(\S+)\s+\S+\s+\S+\s+\S+\s+(\S+)\s+.*$/
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

    base.register_module_after 'system_type', 's_series', 'hardware' do
      base.facts['system_type'].value =~ /S4810/i ||  base.facts['system_type'].value =~ /S5000/i ||  base.facts['system_type'].value =~ /S6000/i
    end

    base.register_module_after 'system_type', 'm_series', 'hardware' do
      base.facts['system_type'].value =~ /I\/O-Aggregator/i || base.facts['system_type'].value =~ /MXL/i
    end

  end

end

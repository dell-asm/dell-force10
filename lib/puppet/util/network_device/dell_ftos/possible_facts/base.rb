require 'puppet/util/network_device/dell_ftos/possible_facts'

module Puppet::Util::NetworkDevice::Dell_ftos::PossibleFacts::Base

  # Module Constants
  CMD_SHOW_INVENTORY = "show inventory"

  CMD_SHOW_VERSION = "show version"

  CMD_SHOW_ENVIRONMENT = "show environment"

  CMD_SHOW_VLAN  ="show vlan"

  CMD_SHOW_SYSTEM_BRIEF="show  system brief"
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

    base.register_param '48_port_interfaces' do
      #match /(.*)\s48-port E\/FE\/GE \(SD\)/
      match do |txt|
        item = txt.scan(/(.*)\s48-port E\/FE\/GE \(SD\)/).flatten.first
        item.strip unless item.nil?
      end
      cmd CMD_SHOW_VERSION
    end

    base.register_param '52_port_interfaces' do
      #match /(.*)\s52-port GE\/TE\/FG \(SE\)/
      match do |txt|
        item = txt.scan(/(\d*)\s52-port GE\/TE\/FG \(SE\)/).flatten.first
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

    base.register_param ['system_management_unit_status'] do
      match /^.*Management\s*(\w*\b).*/
      cmd   CMD_SHOW_SYSTEM_BRIEF
    end

    base.register_param ['system_image'] do
      match /^System image file is\s*"(.*)"/
      cmd "sh ver"
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
      match /^[sS]ystem\s+Type:\s+(\S+)\s+$/
      cmd CMD_SHOW_VERSION
    end

    base.register_param 'control_processor' do
      match /^Control\s+Processor:\s+(.*?)$/
      cmd CMD_SHOW_VERSION
    end

    base.register_param 'software_protocol_configured' do
      match do |txt|
        res = Hash.new
        txt.split(/^$/).map do |line|
          if line =~ /^Software\s+Protocol\s+Configured\s+$/ then
            i=0
            line.split(/\r?\n/).map do |item|
              #Puppet.debug("Item******: OUT #{item}")
              #removed "-" since it is valid char in protocol like Spanning-Tree
              special = "?<>',?[]}{=)(*&^%$#`~{}"
              regexSpecial = /[#{special.gsub(/./){|char| "\\#{char}"}}]/
              if item.nil? || item.empty? || item =~ regexSpecial || item =~ /^Software\s+Protocol\s+Configured\s+$/ || item =~ /^\s+$/ || item =~ /^-{2,}+$/ then
                next
              else
                #Puppet.debug("Match Protocol******: OUT #{item}")
                i=i+1
                res["software_protocol_configured_#{i}"] = item.strip
              end
            end
          end
        end
        res
      end
      cmd CMD_SHOW_INVENTORY
    end

  end
end

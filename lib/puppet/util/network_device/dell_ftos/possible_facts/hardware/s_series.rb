require 'puppet/util/network_device/dell_ftos/possible_facts'
require 'puppet/util/network_device/dell_ftos/possible_facts/hardware'

module Puppet::Util::NetworkDevice::Dell_ftos::PossibleFacts::Hardware::S_series

  # Module Constants
  CMD_SHOW_SYSTEM_BRIEF="show system brief"

  CMD_SHOW_VLAN  ="show vlan"

  CMD_SHOW_INTERFACES  ="show interfaces switchport"

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

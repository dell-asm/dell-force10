require 'puppet/util/network_device/dell_ftos/possible_facts'
require 'puppet/util/network_device/dell_ftos/possible_facts/hardware'

module Puppet::Util::NetworkDevice::Dell_ftos::PossibleFacts::Hardware::S_series

  # Module Constants
  CMD_SHOW_SYSTEM_BRIEF="show system brief"

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

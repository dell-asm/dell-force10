require 'puppet/util/network_device/dell_ftos/possible_facts'
require 'puppet/util/network_device/dell_ftos/possible_facts/hardware'

module Puppet::Util::NetworkDevice::Dell_ftos::PossibleFacts::Hardware::M_series

  # Module Constants
  CMD_SHOW_SYSTEM_STACK_UNIT = "show system stack-unit" unless const_defined?(:CMD_SHOW_SYSTEM_STACK_UNIT)
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

  end
end

require 'puppet/util/network_device/dell_ftos/possible_facts'
require 'puppet/util/network_device/dell_ftos/possible_facts/hardware'

module Puppet::Util::NetworkDevice::Dell_ftos::PossibleFacts::Hardware::Ioa

  # Module Constants
  CMD_SHOW_SYSTEM_STACK_UNIT = "show system stack-unit 0"
  def self.register(base)

    base.register_param 'system_power_status' do
      power_status = 'Unknown'
      match do |txt|
        item = txt.scan(/^.*Switch Power\s+:\s+(.*)$/).flatten.first
        status = item.strip unless item.nil?
        #Puppet.debug("Switch Power: #{status}")
        if status.to_s.eql?('GOOD') then
          power_status = 'up'
        elsif status.to_s.eql?('BAD') then
          power_status = 'down'
        end
      end
      cmd CMD_SHOW_SYSTEM_STACK_UNIT
    end

    base.register_param 'asset_tag' do
      match do |txt|
        item = txt.scan(/\A.*Asset tag\s+:\s+(.*)\z/).flatten.first
        #Puppet.debug("Asset Tag: #{item}")
        item.strip unless item.nil?
      end
      cmd CMD_SHOW_SYSTEM_STACK_UNIT
    end

    base.register_param 'product_name' do
      match do |txt|
        item = txt.scan(/^.*Product Name\s+:\s+(.*)$/).flatten.first
        item.strip unless item.nil?
      end
      cmd CMD_SHOW_SYSTEM_STACK_UNIT
    end

  end
end

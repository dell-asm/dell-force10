require 'puppet/util/network_device/dell_ftos/possible_facts'
require 'puppet/util/network_device/dell_ftos/possible_facts/hardware'

module Puppet::Util::NetworkDevice::Dell_ftos::PossibleFacts::Hardware::M_series

  # Module Constants
  CMD_SHOW_SYSTEM_STACK_UNIT = "show system stack-unit 0"
  def self.register(base)

    base.register_param 'system_power_status' do
      power_status = 'Unknown'
      match do |txt|
        item = txt.scan(/^.*Switch Power\s+:\s+(.*)$/).flatten.first
        status = item.strip unless item.nil?
        #Puppet.debug("Switch Power: #{status}")
        if status =~ /GOOD/i then
          power_status = 'up'
        elsif status =~ /BAD/i then
          power_status = 'down'
        end
      end
      cmd CMD_SHOW_SYSTEM_STACK_UNIT
    end

    base.register_param 'asset_tag' do
      match do |txt|
        item = txt.scan(/^.*Asset tag\s+:\s+(.*)$/).flatten.first
        #Puppet.debug("Asset Tag: #{item}")
        asset_tag = item.strip unless item.nil?
        if asset_tag !~ /PSOC/ then
          asset_tag
        end
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

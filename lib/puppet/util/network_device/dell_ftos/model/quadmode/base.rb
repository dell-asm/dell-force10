#Quad Mode configuration

require 'puppet/util/network_device/dell_ftos/model'
require 'puppet/util/network_device/dell_ftos/model/quadmode'

module Puppet::Util::NetworkDevice::Dell_ftos::Model::Quadmode::Base
  def self.ifprop(base, param, base_command = param, &block)
    Puppet.debug("Base: #{base}, param: #{param}, base_command: #{base_command}")
    base.register_scoped param, /^(stack-unit 0 port (\d+) portmode quad)/m do
      cmd 'show running-config | grep quad'
      match /^(stack-unit 0 port (\d+) portmode quad)/
      add do |transport, value|
        transport.command("#{base_command} #{value}")
      end
      remove do |transport, old_value|
        transport.command("no #{base_command} #{old_value}")
      end
      evaluate(&block) if block
    end
  end

  def self.register(base)
    txt = ''
    ifprop(base, :ensure) do
      Puppet.debug("TXT to match: #{match}")
      port_num = @resource[:name].scan(/(\d+)/).flatten.last
      match do |txt|
        unless txt.nil?
          txt.match(/stack-unit 0 port \d+ portmode quad/) ? :present : :absent
        else
          :absent
        end
      end
      default :absent
      add { |*_| }
      remove { |*_| }
    end
    
  end

end

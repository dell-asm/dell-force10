require 'puppet/util/network_device/dell_ftos/model'
require 'puppet/util/network_device/dell_ftos/model/interface'

module Puppet::Util::NetworkDevice::Dell_ftos::Model::Interface::Base
  def self.ifprop(base, param, base_command = param, &block)
    base.register_scoped param, /^(interface\s+(\S+\s\S+).*?shutdown)/m do
      cmd 'sh run'
      match /^\s*#{base_command}\s+(.*?)\s*$/
      add do |transport, value|
        Puppet.debug(" command #{base_command} value  #{value}" )
        transport.command("#{base_command} #{value}")
      end
      remove do |transport, old_value|
        Puppet.debug(" No  command #{base_command} value  #{value}" )
        transport.command("no #{base_command} #{old_value}")
      end
      evaluate(&block) if block
    end
  end

  def self.register(base)

    txt = ''
    ifprop(base, :ensure) do
      match do |txt|
        unless txt.nil?
          txt.match(/\S+/) ? :present : :absent
        else
          :absent
        end
      end
      default :absent
      add { |*_| }
      remove { |*_| }
    end

    ifprop(base, :portchannel) do
      match /^  port-channel (\d+)\s+.*$/
      add do |transport, value|
        transport.command("port-channel-protocol lacp")
        transport.command("port-channel #{value} mode active")
      end
      remove { |*_| }
    end

    ifprop(base, :shutdown) do
      shutdowntxt=''
      match do |shutdowntxt|
        unless shutdowntxt.nil?
          if shutdowntxt.include? "no shutdown"
            :false
          else
            :true
          end
        end
      end
      add do |transport, value|
        if value==:true
          transport.command("shutdown")
        else
          transport.command("no shutdown")
        end
      end
      remove { |*_| }
    end

    ifprop(base, :mtu) do
      match /^\s*mtu\s+(.*?)\s*$/
      add do |transport, value|
        transport.command("mtu #{value}")
      end
      remove { |*_| }
    end

    ifprop(base, :switchport) do
      switchporttxt=''
      match do |switchporttxt|
        unless switchporttxt.nil?
          if switchporttxt.include? "switchport"
            :true
          else
            :false
          end
        end
      end
      add do |transport, value|
        if value == :true
          transport.command("switchport")do |out|
            if out =~/Error:\s*(.*)/
              Puppet.debug "#{$1}"
            end
          end
        end
        if value == :false
          transport.command("no switchport") do |out|
            if out =~/Error:\s*(.*)/
              Puppet.debug "#{$1}"
            end
          end
        end

      end
      remove { |*_| }
    end
    
    ifprop(base, :dcb_map) do
      match /^\s*dcb-map\s+(.*?)\s*$/
      add do |transport, value|
        transport.command("dcb-map #{value}")
      end
      remove { |*_| }
    end
    
    ifprop(base, :fcoe_map) do
      match /^\s*fcoe-map\s+(.*?)\s*$/
      add do |transport, value|
        transport.command("fcoe-map #{value}")
      end
      remove { |*_| }
    end
    
  end
end

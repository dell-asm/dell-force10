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
        if value.to_i == 0
          transport.command("no port-channel-protocol lacp")
        else
          transport.command("port-channel-protocol lacp")
          transport.command("port-channel #{value} mode active")
        end
      end
      remove do |transport, value|
        transport.command("no port-channel-protocol lacp")
      end
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
        # Commands to remove the dcb ets and pfc settings
        # Without these settings removed, DCB is not applied
        transport.command("no dcb-policy input pfc")
        transport.command("no dcb-policy output ets")
        
        # Command to enable the spanning tree edge port
        transport.command("spanning-tree estp edge-port")
        
        # Command to associate DCB map with the interface
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
    
    ifprop(base, :fabric) do
      match /^\s*fabric\s+(.*?)\s*$/
      add do |transport, value|
        transport.command("fabric #{value}")
      end
      remove { |*_| }
    end

    ifprop(base, :portmode) do
      match /^\s*portmode\s+(.*?)\s*$/
      add do |transport, value|
        #transport.command("fabric #{value}")
        Puppet.debug('Need to remove existing configuration')
        existing_config=(transport.command('show config') || '').split("\n").reverse
        updated_config = existing_config.find_all {|x| x.match(/dcb|switchport|spanning/)}
        updated_config.each do |remove_command|
          transport.command("no #{remove_command}")
        end
        transport.command('portmode hybrid')
        updated_config.reverse.each do |remove_command|
          transport.command("#{remove_command}")
        end
      end
      remove { |*_| }
    end

    ifprop(base, :portfast) do
      match /^\s*spanning-tree 0 (.*?)\s*$/
      add do |transport, value|
        transport.command("spanning-tree 0 #{value}")
      end
      remove { |*_| }
    end

    ifprop(base, :edge_port) do
      match /^\s*spanning-tree pvst\s+(.*?)\s*$/
      add do |transport, value|
        transport.command("spanning-tree pvst #{value}")
      end
      remove { |*_| }
    end

  end
end

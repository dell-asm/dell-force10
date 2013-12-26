require 'puppet/util/network_device/dell_ftos/model'
require 'puppet/util/network_device/dell_ftos/model/portchannel'

module Puppet::Util::NetworkDevice::Dell_ftos::Model::Portchannel::Base
  def self.register(base)
    portchannel_scope = /^(L*\s*(\d+)\s+(.*))/
    description_scope = /(^.*Description:\s*(.*\b)$)/
    mtu_scope = /(^.*MTU\s*(.*\b) bytes .*$)/
    shutdown_scope = /(^.*Shutdown:\s*(.*\b)$)/

    base.register_scoped :ensure, portchannel_scope do
      match do |txt|
        unless txt.nil?
          txt.match(/\S+/) ? :present : :absent
        else
          :absent
        end
      end
      cmd 'show interface port-channel brief'
      default :absent
      add { |*_| }
      remove { |*_| }
    end

    base.register_scoped :mtu, mtu_scope do
      match do |txt|
        unless txt.nil?
          txt.match(/\S+/) ? :present : :absent
        else
          :absent
        end
      end
      cmd 'show interface port-channel'
      default :absent
      add do |transport, value|
        transport.command("mtu #{value}")
      end
      remove { |*_| }
    end

    base.register_scoped :shutdown, shutdown_scope do
      match do |txt|
        unless txt.nil?
          txt.match(/\S+/) ? :present : :absent
        else
          :absent
        end
      end
      cmd 'show interface port-channel'
      default :absent
      add do |transport, value|
        if value == :false
          transport.command("no shutdown")
        else
          transport.command("shutdown")
        end
      end
      remove { |*_| }
    end

    base.register_scoped :desc, description_scope do
      match do |txt|
        unless txt.nil?
          txt.match(/\S+/) ? :present : :absent
        else
          :absent
        end
      end

      cmd 'show interface port-channel'
      add do |transport, value|
        transport.command("desc #{value}")
      end
      remove { |*_| }
    end

  end
end

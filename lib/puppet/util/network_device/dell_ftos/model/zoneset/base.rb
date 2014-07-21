require 'puppet/util/network_device/dell_ftos/model'
require 'puppet/util/network_device/dell_ftos/model/zoneset'

module Puppet::Util::NetworkDevice::Dell_ftos::Model::Zoneset::Base
  def self.register(base)
    zonesetname_scope = /^(\S+)\s+/
    zonesetmember_scope = /^\s+(\S+)$/m
    activezonesetmember_scope = /^Active Zoneset:\s+(.*?)\s*$/
    zonesetnameval = base.name

    base.register_scoped :ensure, zonesetname_scope do
      match do |txt|
        unless txt.nil?
          txt.match(/\S+/) ? :present : :absent
        else
          :absent
        end
      end
      cmd 'show fc zoneset'
      default :absent
      add { |*_| }
      remove { |*_| }
    end

    base.register_scoped :zone, zonesetmember_scope do
#      match do |txt|
#        paramsarray=txt.match(/^\s+ (\d+)/)
#        if paramsarray.nil?
#          param1 = :absent
#        else
#          param1 = paramsarray[1]
#        end
#      end
      param = ":absent"
      cmd "show fc zoneset #{zonesetnameval}"
      default :absent
      add do |transport, value|
        Puppet.debug("Value: #{value}")
        members = value.split(",")
        members.each do |member|
          transport.command("member #{member}")
        end
        
      end
      remove { |*_| }
    end
    
    base.register_scoped :activate, activezonesetmember_scope do
      match do |txt|
        paramsarray=txt.match("/^Active Zoneset:\s+(#{zonesetnameval})\s*$/")
        if paramsarray.nil?
          param = :absent
        else
          param = paramsarray[1]
        end
      end
      #param = ":absent"
      cmd "show fc zoneset #{zonesetnameval}"
      default :absent
      add do |transport, value|
        if value == :true
          transport.command("fcoe-map default_full_fabric")
          transport.command("fc-fabric")
          transport.command("active-zoneset #{zonesetnameval}")
          transport.command("exit")
        end
      end
      remove do |transport, old_value|
        if value == :false
          transport.command("fcoe-map default_full_fabric")
          transport.command("fc-fabric")
          transport.command("no active-zoneset #{zonesetnameval}")
          transport.command("exit")
        end
        
      end
    end

  end
end

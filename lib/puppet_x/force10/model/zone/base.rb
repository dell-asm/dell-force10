require 'puppet_x/force10/model'
require 'puppet_x/force10/model/zone'

module PuppetX::Force10::Model::Zone::Base
  def self.register(base)
    zonename_scope = /^(\S+)\s+/
    zonemember_scope = /^\s+(\S+)$/m
    zonenameval = base.name

    base.register_scoped :ensure, zonename_scope do
      match do |txt|
        unless txt.nil?
          txt.match(/\S+/) ? :present : :absent
        else
          :absent
        end
      end
      cmd 'show fc zone'
      default :absent
      add { |*_| }
      remove { |*_| }
    end

    base.register_scoped :zonemember, zonemember_scope do
      cmd "show fc zone #{zonenameval}"
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

  end
end

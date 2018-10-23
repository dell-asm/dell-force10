require 'puppet_x/force10/model'
require 'puppet_x/force10/model/portchannel'
require 'puppet_x/force10/model/portchannel/generic'
require 'puppet_x/force10/model/interface/base'

module PuppetX::Force10::Model::Portchannel::Base
  extend PuppetX::Force10::Model::Portchannel::Generic

  def self.register(base)
    portchannel_scope = /^(L*\s*(\d+)\s+(.*))/

    register_main_params(base)

    base.register_scoped(:untagged_vlan, portchannel_scope) do
      cmd "show interface port-channel %s" % base.name
      match do |empty_match|
        unless empty_match.nil?
          :false #This is so we always go through the "add" swimlane
        end
      end
      add do |transport, value|
        vlans = PuppetX::Force10::Model::Interface::Base.vlans_from_list(value)

        if value != vlans.first && base.params[:inclusive_vlans].value == :true
          Puppet.warning("skipping Untagged Vlan config, it cannot be changed when server is deployed and inclusive vlan is true")
          next
        end
        inclusive_vlans = base.params[:inclusive_vlans].value
        PuppetX::Force10::Model::Interface::Base.update_vlans(transport, vlans, false, ["po", base.name], inclusive_vlans)
      end
      remove {|*_|}
    end

    base.register_scoped(:tagged_vlan, portchannel_scope) do
      cmd "show interface port-channel %s" % base.name
      match do |empty_match|
        unless empty_match.nil?
          :false
        end
      end
      add do |transport, value|
        vlans = PuppetX::Force10::Model::Interface::Base.vlans_from_list(value)
        inclusive_vlans = base.params[:inclusive_vlans].value
        PuppetX::Force10::Model::Interface::Base.update_vlans(transport, vlans, true, ["po", base.name], inclusive_vlans)
      end
      remove { |*_| }
    end

    base.register_scoped(:inclusive_vlans, portchannel_scope) do
      cmd "show interface port-channel %s" % base.name
      match do |txt|
        paramsarray = txt.match(/^T\s+(\S+)/)
        paramsarray.nil? ? :absent : paramsarray[1]
      end

      add {|*_|}
      remove { |*_| }
    end
  end

end

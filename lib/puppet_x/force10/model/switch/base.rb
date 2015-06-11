require 'puppet_x/force10/model'
require 'puppet_x/force10/model/model_value'
require 'puppet_x/force10/model/switch'
require 'puppet_x/force10/model/interface'
require 'puppet_x/force10/model/feature'
require 'puppet_x/force10/model/zone'
require 'puppet_x/force10/model/zoneset'
require 'puppet_x/force10/model/fcoemap'
require 'puppet_x/force10/model/dcbmap'
require 'puppet_x/force10/model/uplinkstategroup'
require 'puppet_x/force10/model/quadmode'

module PuppetX::Force10::Model::Switch::Base
  def self.register(base)

    base.register_model(:vlan, PuppetX::Force10::Model::Vlan, /^(\d+)\s\S+/, 'show vlan brief')
    base.register_model(:interface, PuppetX::Force10::Model::Interface, /^interface\s+(\S+)\r*$/, 'show running-config')
    base.register_model(:portchannel, PuppetX::Force10::Model::Portchannel, /^L*\s*(\d+)\s+.*/, 'show interfaces port-channel brief')
    base.register_model(:feature, PuppetX::Force10::Model::Feature, /feature*\s*(\S+)/, 'show running-config')
    base.register_model(:zone, PuppetX::Force10::Model::Zone, /^(\S+)\s+/, 'show fc zone')
    base.register_model(:zoneset, PuppetX::Force10::Model::Zoneset, /^(\S+)\s+/, 'show fc zoneset')
    base.register_model(:fcoemap, PuppetX::Force10::Model::Fcoemap, /^fcoe-map\s+(\S+)/, 'show running-config')
    base.register_model(:dcbmap, PuppetX::Force10::Model::Dcbmap, /^dcb-map\s+(\S+)/, 'show running-config')
    base.register_model(:uplinkstategroup, PuppetX::Force10::Model::Uplinkstategroup, /^uplink-state-group\s+(\S+)/, 'show running-config')
    base.register_model(:quadmode, PuppetX::Force10::Model::Quadmode, /^stack-unit 0 port\s+(\d+)/, 'show running-config | grep quad')
  end
end

require 'puppet/provider/dell_ftos'

Puppet::Type.type(:force10_portchannel).provide :dell_ftos, :parent => Puppet::Provider::Dell_ftos do

  desc "Dell Force10 switch provider for port-channel configuration."

  mk_resource_methods

  def self.get_current(name)
    transport.switch.portchannel(name).params_to_hash
  end

  def flush
    transport.switch.portchannel(name).update(former_properties, properties)
    super
  end
end

require 'puppet/provider/dell_ftos'

Puppet::Type.type(:force10_portchannel).provide :dell_ftos, :parent => Puppet::Provider::Dell_ftos do

  desc "Dell force10 switch provider for port channel configuration."

  mk_resource_methods
  def initialize(device, *args)
    super
  end

  def self.lookup(device, name)
    device.switch.portchannel(name).params_to_hash
  end

  def flush
    device.switch.portchannel(name).update(former_properties, properties)
    super
  end
end

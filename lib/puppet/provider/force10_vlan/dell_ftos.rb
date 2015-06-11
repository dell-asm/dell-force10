#Provide for force10 'VLAN' Type

require 'puppet/provider/dell_ftos'

Puppet::Type.type(:force10_vlan).provide :dell_ftos, :parent => Puppet::Provider::Dell_ftos do

  desc "Dell Force10 switch provider for vlan configuration."

  mk_resource_methods

  def self.get_current(name)
    transport.switch.vlan(name).params_to_hash
  end

  def flush
    transport.switch.vlan(name).update(former_properties, properties)
    super
  end
end

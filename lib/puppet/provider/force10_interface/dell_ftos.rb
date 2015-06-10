require 'puppet/provider/dell_ftos'

Puppet::Type.type(:force10_interface).provide :dell_ftos, :parent => Puppet::Provider::Dell_ftos do
  desc "Dell Force10 switch provider for interface configuration."
  mk_resource_methods

  def self.get_current(name)
    if !name.nil?
      name=name.gsub(/te |tengigabitethernet /i, "TenGigabitEthernet ")

      name=name.gsub(/fo |fortygige /i, "fortyGigE ")
    end
    transport.switch.interface(name).params_to_hash
  end

  def flush
    transport.switch.interface(name).update(former_properties, properties)
    super
  end
end

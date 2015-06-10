#Provide for force10 'FCoE MAP' Type

require 'puppet/provider/dell_ftos'

Puppet::Type.type(:force10_fcoemap).provide :dell_ftos, :parent => Puppet::Provider::Dell_ftos do

  desc "This represents Dell Force10 switch fcoe-map configuration."

  mk_resource_methods

  def self.get_current(name)
    transport.switch.fcoemap(name).params_to_hash
  end

  def flush
    transport.switch.fcoemap(name).update(former_properties, properties)
    super
  end
  
  
end

Puppet::Type.newtype(:force10_portchannel) do
  @doc = "This represents a VLAN configuration on a Dell force10 switch."

  apply_to_device

  ensurable

  newparam(:name) do
    isnamevar
    newvalues(/^\d+$/)

    validate do |value|
      return if value == :absent
      raise ArgumentError, "'Port Channel' value  must be between 1-128" unless value.to_i >=1 &&	value.to_i <= 128
    end
 
  end



  newproperty(:desc) do
    newvalues(/^\S+$/)
  end


  newproperty(:mtu) do
    newvalues(/^\d+$/)

    validate do |value|
      return if value == :absent
      raise ArgumentError, "'MTU' value  must be between 594-12000" unless value.to_i >=594 && value.to_i <= 12000
    end
  end

  newproperty(:shutdown) do
    defaultto(:false)
    newvalues(:false,:true)
  end


end

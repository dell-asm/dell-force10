Puppet::Type.newtype(:dell_vlan) do
  @doc = "This represents a vlan configuration on a router or switch."

  apply_to_device

  ensurable

  newparam(:name) do
    isnamevar
  end

  newproperty(:vlanid) do
    newvalues(/^\d+$/)

    validate do |value|
      raise ArgumentError, "Must only contain Integers" unless value.to_s.match(/^\d+$/)
    end
  end
end

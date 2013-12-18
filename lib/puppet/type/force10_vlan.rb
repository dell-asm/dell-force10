Puppet::Type.newtype(:force10_vlan) do
  @doc = "This represents a VLAN configuration on a Dell PowerConnect switch."

  apply_to_device

  ensurable

  newparam(:name) do
    isnamevar
    newvalues(/^\d+$/)
  end

  newproperty(:desc) do
    newvalues(/^\S+$/)
  end
end

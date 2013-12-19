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

  newproperty(:tagged_interfaces, :array_matching => :all) do
    desc "The interfaces names to tag to this VLAN."     
  end

  newproperty(:un_tagged_interfaces, :array_matching => :all) do
    desc "The interfaces names to untag from this VLAN."   
  end
end

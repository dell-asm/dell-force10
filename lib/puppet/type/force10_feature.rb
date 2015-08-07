# Type for force10 VLAN
# Parameters are
#     name - VLAN ID

Puppet::Type.newtype(:force10_feature) do
  @doc = "This represents Dell Force10 switch add-on features that needs to enabled/disabled."

  ensurable

  newparam(:name) do
    desc "feature that needs to be enabled / disabled on the switch"
    isnamevar
    isrequired
    newvalues('fip-snooping','fc')
  end

end

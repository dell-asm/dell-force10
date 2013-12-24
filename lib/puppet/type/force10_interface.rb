Puppet::Type.newtype(:force10_interface) do
  @doc = "This represents a switch interface."

  apply_to_device

  newparam(:name) do
    desc "The interface's name."
    isrequired
    newvalues(/^\A+tengigabitethernet\s*\S+/i, /te\s*\S+$/i,/^fortygige\s*\S+$/i,/^fo\s*\S+$/i)
    isnamevar
  end

  newproperty(:portchannel) do
    desc "Set port channel for the interface."
    newvalues(/^\d+$/)
    validate do |value|
      raise ArgumentError, "'portchannel' value must be between 1-128" unless value.to_i >=1 && value.to_i <= 128
    end
  end

  newproperty(:mtu) do
    desc "Set mtu of the interface."
    defaultto(:absent)
    newvalues(:absent, /^\d+$/)
    validate do |value|
      return if value == :absent
      raise ArgumentError, "'mtu' value must be between 594-12000" unless value.to_i >=594 && value.to_i <= 12000
    end
  end

  newproperty(:shutdown) do
    desc "Enable or disable  the interface."
    defaultto(:false)
    newvalues(:false,:true)
  end

  newproperty(:switchport) do
    desc "Enable or disable  the switchport"
    defaultto(:false)
    newvalues(:false,:true)
  end

end


Puppet::Type.newtype(:force10_interface) do
  @doc = "This represents Dell force10 switch interface."

  apply_to_device

  newparam(:name) do
    @doc = "Interface name"
    isrequired
    newvalues(/^\Atengigabitethernet\s*\S+/i, /te\s*\S+$/i,/^fortygige\s*\S+$/i,/^fo\s*\S+$/i)
    isnamevar
  end

  newproperty(:portchannel) do
    @doc = "Port-channel Name"
    newvalues(/^\d+$/)
    validate do |value|
      raise ArgumentError, "An invalid 'portchannel' value is entered. The 'portchannel' value must be between 1 and 128." unless value.to_i >=1 && value.to_i <= 128
    end
  end

  newproperty(:mtu) do
    @doc = "MTU value"
    defaultto(:absent)
    newvalues(:absent, /^\d+$/)
    validate do |value|
      return if value == :absent
      raise ArgumentError, "An invalid 'mtu' value is entered. The 'mtu' value must be between 594 and 12000" unless value.to_i >=594 && value.to_i <= 12000
    end
  end

  newproperty(:shutdown) do
    @doc = "Boolean value denotes Shutdown /no shutdown"
    desc "Enable or disable  the interface."
    defaultto(:false)
    newvalues(:false,:true)
  end

  newproperty(:switchport) do
    @doc = "Boolean value denotes enable Switchport"
    desc "Enable or disable  the switchport"
    defaultto(:false)
    newvalues(:false,:true)
  end

end


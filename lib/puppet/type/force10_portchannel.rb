Puppet::Type.newtype(:force10_portchannel) do
  @doc = "This represents Dell Force10 switch port-channel."

  apply_to_device

  ensurable

  newparam(:name) do
    desc "Port-channel name, represents Port-channel"
    isnamevar
    newvalues(/^\d+$/)

    validate do |value|
      return if value == :absent
      raise ArgumentError, "An invalid 'portchannel' value is entered. The 'portchannel' value must be between 1 and 128." unless value.to_i >=1 &&	value.to_i <= 128
    end

  end

  newproperty(:desc) do
    desc "Port-channel description"
    newvalues(/^(\w\s*)*?$/)
  end

  newproperty(:mtu) do
    desc "MTU value"
    newvalues(/^\d+$/)

    validate do |value|
      return if value == :absent
      raise ArgumentError, "An invalid 'mtu' value is entered. The 'mtu' value must be between 594 and 12000." unless value.to_i >=594 && value.to_i <= 12000
    end
  end

  newproperty(:switchport) do
    desc "The switchport flag of the port-channel, true means move the port-channel to Layer2, else interface will be in Layer1"
    defaultto(:false)
    newvalues(:false,:true)
  end

  newproperty(:shutdown) do
    desc "The shutdown flag of the port-channel, true means Shutdown else no shutdown"
    defaultto(:false)
    newvalues(:false,:true)
  end

end

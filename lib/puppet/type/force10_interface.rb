Puppet::Type.newtype(:force10_interface) do
  @doc = "This represents Dell Force10 switch interface."

  ensurable  # Setting to absent will remote interface from all vLAN's

  newparam(:name) do
    desc "Interface name, represents an interface"
    isrequired
    newvalues(/^\Atengigabitethernet\s*\S+/i, /te\s*\S+$/i, /^fortygige\s*\S+$/i, /^fo\s*\S+$/i, /^twentyfivegige\s*\S+$/i, /tf\s*\S+$/i, /^hundredgige\s*\S+$/i, /hu\s*\S+$/i)
    isnamevar
  end

  newproperty(:portchannel) do
    desc "Port-channel Name, which needs to be associated with this interface"
    newvalues(/^\d+$/)
    validate do |value|
      raise ArgumentError, "An invalid 'portchannel' value is entered. The 'portchannel' value must be between 1 and 128." unless value.to_i >=1 && value.to_i <= 128
    end
  end

  newproperty(:mtu) do
    desc "MTU value"
    defaultto(:absent)
    newvalues(:absent, /^\d+$/)
    validate do |value|
      return if value == :absent
      raise ArgumentError, "An invalid 'mtu' value is entered. The 'mtu' value must be between 594 and 12000" unless value.to_i >=594 && value.to_i <= 12000
    end
  end

  newproperty(:shutdown) do
    desc "The shutdown flag of the interface, true means Shutdown else no shutdown"
    defaultto(:false)
    newvalues(:false,:true)
  end

  newproperty(:switchport) do
    desc "The switchport flag of the interface, true means move the interface to Layer2, else interface will be in Layer1"
    defaultto(:false)
    newvalues(:false,:true)
  end
  
  newproperty(:fcoe_map) do
    desc "fcoe map that needs to be associated with the interface"
    validate do |value|
      all_valid_characters = value =~ /^[A-Za-z0-9_]+$/
      raise ArgumentError, "Invalid fcoe-map name" unless all_valid_characters
    end
  end
  
  newproperty(:dcb_map) do
    desc "dcb map that needs to be associated with the interface"
    validate do |value|
      all_valid_characters = value =~ /^[A-Za-z0-9_]+$/
      raise ArgumentError, "Invalid fcoe-map name" unless all_valid_characters
    end
  end

  newproperty(:portmode) do
    desc "property to set the portmode hybrid setting on the port"
    newvalues('hybrid')
  end

  newproperty(:portfast) do
    desc "property to set the spanning tree portfast setting"
    newvalues('portfast')
  end

  newproperty(:edge_port) do
    desc "property to set the spanning-tree edge-port setting"
    validate do |value|
      return if value.empty?
    end
  end

  newproperty(:protocol) do
    desc "property to set protcol lldp"
    newvalues('lldp')
  end

  newproperty(:tagged_vlan) do
    desc "comma-separated list of vlans"
  end

  newproperty(:untagged_vlan) do
    desc "untagged vlan"
  end

  newproperty(:inclusive_vlans) do
    desc "Flag to indicate if existing vlans needs to be included"
    newvalues(:true, :false)
  end
end


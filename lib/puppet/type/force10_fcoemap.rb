# Type for force10 fcoe map configuration
# Parameters are

Puppet::Type.newtype(:force10_fcoemap) do
  @doc = "This represents Dell Force10 fcoemap configuration."

  ensurable

  newparam(:name) do
    desc "This parameter describes the fcoe-map name to be created on the Force10 switch.
          The valid zoneset name does not allow blank value, special character except _ ,numeric char at the start, and length above 64 chars"
    isnamevar
    validate do |value|
      all_valid_characters = value =~ /^[A-Za-z0-9_]+$/
      raise ArgumentError, "Invalid fcoe-map name" unless all_valid_characters
    end
  end

  newproperty(:fcoe_map) do
    desc "FC-MAP ID assocciated with the fcoe-map"
    validate do |value|
      all_valid_characters = value =~ /^0EFC[A-Z0-9]+/i
      raise ArgumentError, "Invalid fcoe-map ID" unless all_valid_characters
    end
  end

  newproperty(:fcoe_vlan) do
      desc "FCOE VLAN that needs to be configured"
      validate do |value|
        all_valid_characters = value =~ /^[0-9]+$/
        raise ArgumentError, "Invalid FCoE VLAN" unless all_valid_characters
      end
    end

  newproperty(:fabric_type) do
    desc "FCoE Fabric Type"
  end

 end

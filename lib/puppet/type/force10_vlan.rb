# Type for force10 VLAN
# Parameters are
#     name - any unique string
# Properties are
#   desc - TFTP url for the startup configuration
#   tagged_tengigabitethernet - TenGigabitEthernet interface names need to be added to VLAN as tagged
#   tagged_gigabitethernet - GigabitEthernet interface names need to be added to VLAN tagged
#   tagged_portchannel - Port-channel interface names need to be added to VLAN as tagged
#   tagged_sonet - Sonet interface names need to be added to VLAN tagged
#   tagged_tengigabitethernet - TenGigabitEthernet interface names need to be added to VLAN as untagged
#   tagged_gigabitethernet - GigabitEthernet interface names need to be added to VLAN untagged
#   tagged_portchannel - Port-channel interface names need to be added to VLAN as untagged
#   tagged_sonet - Sonet interface names need to be added to VLAN untagged

Puppet::Type.newtype(:force10_vlan) do
  @doc = "This represents a VLAN configuration on a Dell Force10 switch."

  apply_to_device

  ensurable

  newparam(:name) do
    isnamevar
    validate do |value|
      return if value == :absent
      raise ArgumentError, "An invalid VLAN ID is entered. The VLAN ID must be between 1 and 4094." unless value.to_i >= 1 && value.to_i <= 4094
    end
    newvalues(/^\d+$/)
  end

  newproperty(:vlan_name) do
    validate do |url|
      raise ArgumentError, "An invalid name is entered for the VLAN ID. The name must be a string." unless vlan_name.is_a? String
    end

    validate do |value|
      return if value == :absent
      raise ArgumentError, "An invalid name is entered for the VLAN ID. The name cannot exceed 100 characters." unless value.length <= 100
    end
    newvalues(/^(\w\s*)*?$/)
  end

  newproperty(:desc) do
    validate do |url|
      raise ArgumentError, "An invalid description is entered for the VLAN ID. The description must be a string." unless desc.is_a? String
    end

    validate do |value|
      return if value == :absent
      raise ArgumentError, "An invalid description is entered for the VLAN ID. The description cannot exceed 100 characters." unless value.length <= 100
    end
    newvalues(/^(\w\s*)*?$/)
  end

  newproperty(:tagged_tengigabitethernet) do
    desc "The TenGigabitEthernet interfaces names to add as tagged to this VLAN."
  end

  newproperty(:tagged_fortygigabitethernet) do
    desc "The fortyGigE interfaces names to add as tagged to this VLAN."
  end

  newproperty(:tagged_portchannel) do
    desc "The Port-channel interfaces names to add as tagged to this VLAN."
  end

  newproperty(:tagged_gigabitethernet) do
    desc "The GigabitEthernet interfaces names to add as tagged to this VLAN."
  end

  newproperty(:tagged_sonet) do
    desc "The SONET interfaces names to add as tagged to this VLAN."
  end

  newproperty(:untagged_tengigabitethernet) do
    desc "The TenGigabitEthernet interfaces names to add as untagged to this VLAN."
  end

  newproperty(:untagged_fortygigabitethernet) do
    desc "The fortyGigE interfaces names to add as untagged to this VLAN."
  end

  newproperty(:untagged_portchannel) do
    desc "The Port-channel interfaces names to add as untagged to this VLAN."
  end

  newproperty(:untagged_gigabitethernet) do
    desc "The GigabitEthernet interfaces names to add as untagged to this VLAN."
  end

  newproperty(:untagged_sonet) do
    desc "The SONET interfaces names to add as untagged to this VLAN."
  end
end

# Type for force10 VLAN
# Parameters are
#     name - any unique string
# Properties are
#   desc - description for VLAN
#   mtu - mtu value for VLAN
#   shutdown - enaable or disable VLAN
#   tagged_tengigabitethernet - TenGigabitEthernet interface names need to be added to VLAN as tagged
#   tagged_gigabitethernet - GigabitEthernet interface names need to be added to VLAN tagged
#   tagged_portchannel - Port-channel interface names need to be added to VLAN as tagged
#   tagged_sonet - Sonet interface names need to be added to VLAN tagged
#   tagged_tengigabitethernet - TenGigabitEthernet interface names need to be added to VLAN as untagged
#   tagged_gigabitethernet - GigabitEthernet interface names need to be added to VLAN untagged
#   tagged_portchannel - Port-channel interface names need to be added to VLAN as untagged
#   tagged_sonet - Sonet interface names need to be added to VLAN untagged

Puppet::Type.newtype(:force10_vlan) do
  @doc = "This represents Dell Force10 switch VLAN."

  apply_to_device

  ensurable

  newparam(:name) do
    @doc = "VLAN ID"
    isnamevar
    validate do |value|
      return if value == :absent
      all_valid_characters = value =~ /^[0-9]+$/
      raise ArgumentError, "An invalid VLAN ID is entered. The VLAN ID must be between 1 and 4094." unless all_valid_characters && value.to_i >= 1 && value.to_i <= 4094
    end
    newvalues(/^\d+$/)
  end

  newproperty(:vlan_name) do
    @doc = "VLAN Name"
    validate do |value|
      return if value == :absent
      start_with_letter = value =~ /\A[a-zA-Z]/
      all_valid_characters = value =~ /^[a-zA-Z0-9_\s]+$/
      raise ArgumentError, "An invalid name is entered for the VLAN ID. The name should start with alphabet and should contain only alphanumeric, space and underscore." unless (start_with_letter and all_valid_characters)
      raise ArgumentError, "An invalid name is entered for the VLAN ID. The name cannot exceed 32 characters." unless value.length <= 32
    end
    newvalues(/^(\w\s*)*?$/)
  end

  newproperty(:desc) do
    @doc = "VLAN Description"
    validate do |value|
      return if value == :absent
      raise ArgumentError, "An invalid description is entered for the VLAN ID. The description cannot exceed 100 characters." unless value.length <= 100
    end
    newvalues(/^(\w\s*)*?$/)
  end

  newproperty(:mtu) do
    @doc = "MTU value"
    desc "Set mtu of the VLAN."
    defaultto(:absent)
    newvalues(:absent, /^\d+$/)
  end

  newproperty(:shutdown) do
    @doc = "Boolean value denotes Shutdown /no shutdown"
    defaultto(:false)
    newvalues(:false,:true)
  end

  newproperty(:tagged_tengigabitethernet) do
    @doc = "The TenGigabitEthernet interfaces names to add as tagged to this VLAN."
  end

  newproperty(:tagged_fortygigabitethernet) do
    @doc = "The fortyGigE interfaces names to add as tagged to this VLAN."
  end

  newproperty(:tagged_portchannel) do
    @doc = "The Port-channel interfaces names to add as tagged to this VLAN."
  end

  newproperty(:tagged_gigabitethernet) do
    @doc = "The GigabitEthernet interfaces names to add as tagged to this VLAN."
  end

  newproperty(:tagged_sonet) do
    @doc = "The SONET interfaces names to add as tagged to this VLAN."
  end

  newproperty(:untagged_tengigabitethernet) do
    @doc = "The TenGigabitEthernet interfaces names to add as untagged to this VLAN."
  end

  newproperty(:untagged_fortygigabitethernet) do
    @doc = "The fortyGigE interfaces names to add as untagged to this VLAN."
  end

  newproperty(:untagged_portchannel) do
    @doc = "The Port-channel interfaces names to add as untagged to this VLAN."
  end

  newproperty(:untagged_gigabitethernet) do
    @doc = "The GigabitEthernet interfaces names to add as untagged to this VLAN."
  end

  newproperty(:untagged_sonet) do
    @doc = "The SONET interfaces names to add as untagged to this VLAN."
  end
end

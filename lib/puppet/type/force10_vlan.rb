Puppet::Type.newtype(:force10_vlan) do
  @doc = "This represents a VLAN configuration on a Dell Force10 switch."

  apply_to_device

  ensurable

  newparam(:name) do
    isnamevar     
    validate do |value|
      return if value == :absent
     raise ArgumentError, "'name(VLAN ID)' vlaue must be between 1-4094" unless value.to_i >= 1 && value.to_i <= 4094
    end
	newvalues(/^\d+$/)
end

  newproperty(:desc) do
   validate do |url|
      raise ArgumentError, "desc(VLAN ID)' should be a string" unless url.is_a? String
    end  
 
   validate do |value|
    return if value == :absent
    raise ArgumentError, "'desc(VLAN ID)' should be a string with max 100 characters" unless value.length <= 100
    end 
   newvalues(/^(\w\s*)*?$/)	
  end


  newproperty(:tagged_tengigabitethernet) do
    desc "The TenGigabitEthernet interfaces names to tag to this VLAN."     
  end

  newproperty(:tagged_portchannel) do
    desc "The Port-channel interfaces names to tag to this VLAN."   
  end
  
  newproperty(:tagged_gigabitethernet) do
    desc "The GigabitEthernet interfaces names to tag to this VLAN."     
  end

  newproperty(:tagged_sonet) do
    desc "The SONET interfaces names to tag to this VLAN."   
  end
end

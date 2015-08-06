# Type for force10 zone configuration
# Parameters are
#     name - zonename

Puppet::Type.newtype(:force10_zone) do
  @doc = "This represents Dell Force10 zone configuration."

  ensurable

  newparam(:name) do
    desc "This parameter describes the zone name to be created on the Force10 switch.
          The valid zone name does not allow blank value, special character except _ ,numeric char at the start, and length above 64 chars"
    isnamevar
    validate do |value|
      all_valid_characters = value =~ /^[A-Za-z0-9_]+$/
      raise ArgumentError, "Invalid zone name" unless all_valid_characters
    end
  end

  newproperty(:zonemember) do
    desc "Zone members that needs to be added while creating the zone"
  end

 end

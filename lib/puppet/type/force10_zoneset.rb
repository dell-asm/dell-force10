# Type for force10 zone configuration
# Parameters are
#     name - zonename

Puppet::Type.newtype(:force10_zoneset) do
  @doc = "This represents Dell Force10 zoneset configuration."

  ensurable

  newparam(:name) do
    desc "This parameter describes the zoneset name to be created on the Force10 switch.
          The valid zoneset name does not allow blank value, special character except _ ,numeric char at the start, and length above 64 chars"
    isnamevar
    validate do |value|
      all_valid_characters = value =~ /^[A-Za-z0-9_]+$/
      raise ArgumentError, "Invalid zoneset name" unless all_valid_characters
    end
  end

  newproperty(:ensure) do
    newvalues(:present, :absent)
    defaultto(:present)
  end

  newproperty(:zone) do
    desc "zones that needs to be added to the zoneset"
    end

  newproperty(:activate) do
    desc "activate / de-activate the zoneset"
    newvalues(:true,:false)
  end

 end

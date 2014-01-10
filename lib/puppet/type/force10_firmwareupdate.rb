Puppet::Type.newtype(:force10_firmwareupdate) do
  @doc = "This will execute firmware Update on Dell force10 switch."

  apply_to_device

  newparam(:name) do
    desc "Firmware name, can be any unique name"
    isnamevar
  end

  newparam(:forceupdate) do
    desc "This flag denotes force apply of firmware"
    newvalues(:true, :false)
    defaultto :false
  end

  newproperty(:firmwarelocation) do
    desc "URL of Firmware location "
    validate do |firmwarelocation|
      raise ArgumentError, "Command must be a String, got value of class #{firmwarelocation.class}" unless firmwarelocation.is_a? String
    end

  end

  newproperty(:returns, :event => :executed_command) do |property|
    munge do |value|
      value.to_s
    end

    def event_name
      :executed_command
    end

    defaultto "#"

    def change_to_s(currentvalue, newvalue)
      Puppet.debug(" current value: #{currentvalue} new value is : #{newvalue}")
      "executed successfully"
    end

    def retrieve
    end

    def sync
      event = :executed_command
      out = provider.run(self.resource[:firmwarelocation], self.resource[:forceupdate])
      event
    end
  end

  @isomorphic = false

  def self.instances
    []
  end

end

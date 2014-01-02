# Type for force10 configuration
# Parameters are
#     name - any unique string
#   url - TFTP url for the startup configuration
#   startup_config - boolean value, if true means it's 'startup config' else 'running config'
#   force - boolean value, if true means forcefully apply the configuration though there is no configuration change

Puppet::Type.newtype(:force10_config) do
  @doc = "Apply configuration on force10 switch."

  apply_to_device

  newparam(:name) do
    isnamevar
    validate do |value|
      return if value == :absent
      all_valid_characters = value =~ /^[a-zA-Z0-9_\s]+$/
      raise ArgumentError, "An invalid configuration name is entered. The configuration name should contain only alphanumeric, space and underscore and also should not exceed 100 characters." unless all_valid_characters && value.length <= 100
    end
    newvalues(/^(\w\s*)*?$/)
  end

  newparam(:url) do
    validate do |value|
      raise ArgumentError, "An invalid url is entered.Url must be a in format of tftp://${deviceRepoServerIPAddress}/${fileLocation}." unless value.start_with?('tftp://')
    end
  end

  newparam(:startup_config) do
    desc "Whether the provided configuration is startup configuration or running configuration"
    newvalues(:true, :false)
    defaultto :false
  end

  newparam(:force) do
    desc "Whether the provided configuration has to be applied in force"
    newvalues(:true, :false)
    defaultto :false
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
      "executed successfully"
    end

    def retrieve

    end

    def sync

      event = :executed_command
      out = provider.run(self.resource[:url], self.resource[:startup_config],self.resource[:force])
      event
    end
  end

  @isomorphic = false

  def self.instances
    []
  end
end

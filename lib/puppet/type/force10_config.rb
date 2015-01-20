# Type for force10 configuration
# Parameters are
#     name - any unique string
#   url - TFTP url for the startup configuration
#   startup_config - boolean value, if true means it's 'startup config' else 'running config'
#   force - boolean value, if true means forcefully apply the configuration though there is no configuration change

Puppet::Type.newtype(:force10_config) do
  @doc = "This will apply configuration on Dell Force10 switch."

  apply_to_device

  newparam(:name) do
    desc "Configuration name, can be any unique name"
    isnamevar
    #newvalues(/^(\w\s*)*?$/)
  end

  newparam(:url) do
    desc 'Configuration TFTP URL'
    validate do |value|
      if value.length > 0
        raise ArgumentError, "An invalid url is entered.Url must be a in format of tftp://${deviceRepoServerIPAddress}/${fileLocation}." unless value.start_with?('tftp://')
      end
    end
    defaultto ''
  end

  newparam(:startup_config) do
    desc "This Flag denotes startup-config or running-config"
    newvalues(:true, :false)
    defaultto :false
  end

  newparam(:source_server) do
    "Server where configuration files are located"
    defaultto []
  end

  newparam(:source_file_path) do
    'absolute location where source configuaration file located'
    defaultto []
  end

  newparam(:copy_to_tftp) do
    "2 element array, ['path to tftp share','path under tftp share']\nFor example: ['/var/lib/tftpshare','catalog1/firmware.cmc']"
    defaultto ''
  end

  newparam(:force) do
    desc "This Flag denotes force configuration apply"
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

    defaultto "-Configuration Change-"

    def change_to_s(currentvalue, newvalue)
      "executed successfully"
    end

    def retrieve

    end

    def sync

      event = :executed_command
      out = provider.run(self.resource[:url],
                         self.resource[:startup_config],
                         self.resource[:force],
                         self.resource[:source_server],
                         self.resource[:source_file_path],
                         self.resource[:copy_to_tftp])
      event
    end
  end

  @isomorphic = false

  def self.instances
    []
  end
end

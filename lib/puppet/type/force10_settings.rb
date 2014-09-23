Puppet::Type.newtype(:force10_settings) do
  @doc = "A generic way to setup various settings on Dell Force10 switch."

  apply_to_device

  newparam(:name) do
    desc "Name, can be any unique name"
    isnamevar
  end

  newproperty(:ntp_server1) do
    desc "The first NTP server to setup"
    validate do |value|
      raise ArgumentError, "Command must be a String, got value of class #{value.class}" unless value.is_a? String
    end
  end

  newproperty(:ntp_server2) do
    desc "The second NTP server to setup (if passed)"
    validate do |value|
      raise ArgumentError, "Command must be a String, got value of class #{value.class}" unless value.is_a? String
    end
  end

  newproperty(:hostname) do
    desc "The hostname to give this switch"
  end

  newproperty(:syslog_destination) do
    desc "The remote syslog location"
  end

end

require 'puppet_x/force10/transport'
require 'puppet/provider/network_device'

# This is the base Class of all prefetched Dell Force10 device providers
# Extends NetworkDevice since there are some predefined methods there that are handy, even though this isn't technically a puppet device.
class Puppet::Provider::Dell_ftos < Puppet::Provider::NetworkDevice
  attr_accessor :transport

  def initialize(*args)
    super(nil, *args)
    @transport = @property_hash.delete(:transport)
    @properties.delete(:transport)
  end

  def self.transport
    @transport ||= PuppetX::Force10::Transport.new(Puppet[:certname])
  end

  def self.prefetch(resources)
    resources.each do |name, resource|
      result = get_current(name)
      #We want to pass the transport through so we don't keep initializing new ssh connections for every single resource
      if result
        result[:transport] = transport
        resource.provider = new(result)
      else
        resource.provider = new(:ensure => :absent, :transport => transport)
      end
    end
  end
end
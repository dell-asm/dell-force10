#This class is called by the puppet frame work for retrieving the facts .it  retrieve the facts and initialize the switch variables.
require 'puppet'
require 'puppet/util'
require 'puppet/util/network_device/base_ftos'
require 'puppet/util/network_device/dell_ftos/facts'
require 'puppet/util/network_device/dell_ftos/model'
require 'puppet/util/network_device/dell_ftos/model/switch'

class Puppet::Util::NetworkDevice::Dell_ftos::Device < Puppet::Util::NetworkDevice::Base_ftos

  attr_accessor :enable_password, :switch
  def initialize(url, options = {})
    super(url)
    @enable_password = options[:enable_password] || parse_enable(@url.query)
    @initialized = false
    transport.default_prompt = /[#>]\s?\z/n
  end

  def parse_enable(query)
    return $1 if query =~ /enable=(.*)/
  end

  def connect_transport
    transport.connect
    login
    transport.command("terminal length 0", :noop => false) do |out|
      enable if out =~ />\s?\z/n
    end
  end

  def login
    return if transport.handles_login?
    if @transport.user != ''
      transport.command(@transport.user, {:prompt => /^Password:/, :noop => false})
    else
      transport.expect(/^Password:/)
    end
    transport.command(@transport.password, :noop => false)
  end

  def enable
    raise "Can't issue \"enable\" to enter privileged, no enable password set" unless enable_password
    transport.command("enable", {:prompt => /^Password:/, :noop => false})
    transport.command(enable_password, :noop => false)
  end

  def init
    unless @initialized
      connect_transport
      init_facts
      init_switch
      @initialized = true
    end
    return self
  end

  def init_switch
    @switch ||= Puppet::Util::NetworkDevice::Dell_ftos::Model::Switch.new(transport, @facts.facts_to_hash)
    @switch.retrieve
  end

  def init_facts
    @facts ||= Puppet::Util::NetworkDevice::Dell_ftos::Facts.new(transport)
    @facts.retrieve
  end

  def facts
    # This is here till we can fork Puppet
    init
    #Puppet.debug("Host******: OUT #{@url.host}")
    facts = @facts.facts_to_hash
    # inject switch ip or fqdn info.
    facts['fqdn'] = @url.host
    # inject manufacturer info.
    facts['manufacturer'] = "Dell"
    # inject switch model info.
    facts['model'] = facts['system_type']
    facts
  end
end

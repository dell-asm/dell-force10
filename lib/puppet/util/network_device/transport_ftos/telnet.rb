#This class is responsible for telnet specific transport to the switch  
require 'puppet/util/network_device'
require 'puppet/util/network_device/transport_ftos'
require 'puppet/util/network_device/transport_ftos/base_ftos'
require 'net/telnet'

class Puppet::Util::NetworkDevice::Transport_ftos::Telnet < Puppet::Util::NetworkDevice::Transport_ftos::Base_ftos
  def initialize()
    super()
  end

  def handles_login?
    false
  end

  def connect
    begin
      Puppet.debug "Trying to connect to #{host} as #{user}"
      @telnet = Net::Telnet::new("Host" => host, "Port" => port || 23,
      "Timeout" => 10000,
      "Prompt" => default_prompt)
    rescue TimeoutError
      raise TimeoutError, "Telnet timed out while trying to connect to #{host}"
    rescue => error
      #raise Puppet::Error, "Unable to connect to #{host}: #{error.message}"
      raise Puppet::Error, "Telnet connection failure to #{host}"
    end
  end

  def close
    @telnet.close if @telnet
    @telnet = nil
  end

  def expect(prompt)
    lines = ''
    @telnet.waitfor(prompt) do |out|
      lines << out.gsub(/\r\n/no, "\n")
      yield out if block_given?
    end
    lines.split(/\n/).each do |line|
      Puppet.debug("Telnet: IN #{line}") if Puppet[:debug]
      Puppet.fail "Executed invalid Command! For a detailed output add --debug to the next Puppet run!" if line.match(/^% Invalid input detected at '\^' marker\.$/n)
    end
    lines
  end

  def send(line, noop = false)
    Puppet.debug("Telnet: OUT #{line}") if Puppet[:debug]
    @telnet.puts(line) unless noop
  end
end

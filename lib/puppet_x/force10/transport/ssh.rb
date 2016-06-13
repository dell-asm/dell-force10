require 'puppet/util/network_device/transport/ssh'
require 'timeout'

class PuppetX::Force10::Transport::Ssh < Puppet::Util::NetworkDevice::Transport::Ssh

  def initialize
    @timeout = 10
    @cache = {}
    super(true)
  end

  # This method is (unfortunately) mostly copied from Puppet's SSH transport class.
  # Hard to add the known hosts file fix without having the rest of the code copied along with it :(
  def connect(&block)
    begin
      Puppet.debug "Trying to connect to #{host} as #{user}"
      @ssh = Net::SSH.start(host, user, :port => port, :password => password, :timeout => timeout,
                            :paranoid => Net::SSH::Verifiers::Null.new,
                            :global_known_hosts_file=>"/dev/null")
    rescue TimeoutError
      raise TimeoutError, "SSH timed out while trying to connect to #{host}"
    rescue Net::SSH::AuthenticationFailed
      raise Puppet::Error, "SSH auth failed while trying to connect to #{host} as #{user}"
    rescue Net::SSH::Exception => error
      raise Puppet::Error, "SSH connection failure to #{host}"
    end

    @buf      = ''
    @eof      = false
    @channel  = nil
    @ssh.open_channel do |channel|
      channel.request_pty {|ch, success| raise "Failed to open PTY" unless success}

      channel.send_channel_request('shell') do |ch, success|
        raise 'Failed to open SSH SHELL Channel' unless success

        ch.on_data {|ch, data| @buf << data}
        ch.on_extended_data {|ch, type, data| @buf << data if type == 1}
        ch.on_close {@eof = true}

        @channel = ch
        expect(default_prompt, &block)
        return
      end
    end
    @ssh.loop
  end


  def sendwithoutnewline(line, noop = false)
    Puppet.debug "SSH send: #{line}" if @verbose
    @channel.send_data(line) unless noop
  end

  def send(cmd, noop=false)
    Puppet.debug "SSH send: #{cmd}" if @verbose
    @channel.send_data(cmd + "\r") unless noop
  end

  def expect(prompt)
    time_out = 1200 #20 min timeout to allow for the firmware update command to finish
    result = Timeout::timeout(time_out) do
      super
    end
  end

  def command(cmd, options = {})
    noop = options[:noop].nil? ? Puppet[:noop] : options[:noop]
    if options[:cache]
      return @cache[cmd] if @cache[cmd]
      send(cmd, noop)
      unless noop
        @cache[cmd] = expect(options[:prompt] || default_prompt)
        txt = @cache[cmd]
        if !txt.nil?
          raise(ArgumentError, "Invalid Command:\t #{cmd} while configuring switch") if txt =~ /\sError: ((Invalid input)|(Incomplete command))\s/
        end
      end
    else
      send(cmd, noop)
      unless noop
        expect(options[:prompt] || default_prompt) do |output|
          if !output.nil?
            raise(ArgumentError, "Invalid Command:\t #{cmd} while loading facts") if txt =~ /\sError: ((Invalid input)|(Incomplete command))\s/
          end
          yield output if block_given?
        end
      end
    end
  end
end
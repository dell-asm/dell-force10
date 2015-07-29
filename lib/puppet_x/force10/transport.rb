require 'uri'
require 'openssl'
require 'cgi'

module PuppetX
  module Force10
    class Transport
      attr_accessor :session, :enable_password, :switch
      @initialized = false

      def initialize(certname, options={})
        if options[:device_config]
          device_conf = options[:device_config]
        else
          require 'asm/device_management'
          device_conf = ASM::DeviceManagement.parse_device_config(certname)
        end

        device_conf[:arguments] ||= {}
        @enable_password = options[:enable_password] || device_conf[:arguments]['enable']

        unless @session
          require "puppet_x/force10/transport/ssh"
          @session = PuppetX::Force10::Transport::Ssh.new
          @session.host = device_conf[:host]
          @session.port = device_conf[:port] || 22
          if device_conf[:arguments]['credential_id']
            require 'asm/cipher'
            cred = ASM::Cipher.decrypt_credential(device_conf[:arguments]['credential_id'])
            @session.user = cred.username
            @session.password = cred.password
          else
            @session.user = device_conf[:user]
            @session.password = device_conf[:password]
          end
        end

        @session.default_prompt = /[#>]\s?\z/n
        connect_session
        init_facts
        init_switch
      end

      def connect_session
        session.connect
        login
        session.command("terminal length 0", :noop => false) do |out|
          enable if out =~ />\s?\z/n
        end
      end

      def login
        return if session.handles_login?
        if @session.user != ''
          session.command(@session.user, {:prompt => /^Password:/, :noop => false})
        else
          session.expect(/^Password:/)
        end
        session.command(@session.password, :noop => false)
      end

      def enable
        raise "Can't issue \"enable\" to enter privileged, no enable password set" unless enable_password
        session.command("enable", {:prompt => /^Password:/, :noop => false})
        session.command(enable_password, :noop => false)
      end

      def init_switch
        require 'puppet_x/force10/model/switch'
        @switch ||= PuppetX::Force10::Model::Switch.new(session, @facts.facts_to_hash)
        @switch.retrieve
      end

      #WE use these facts to do certain workflows in some of the providers/force10.
      def init_facts
        require 'puppet_x/force10/facts'
        @facts ||= PuppetX::Force10::Facts.new(session)
        @facts.retrieve
      end

      def facts
        # This is here till we can fork Puppet
        facts = @facts.facts_to_hash
        # inject switch ip or fqdn info.
        #facts['fqdn'] = @url.host
        # inject manufacturer info.
        facts['manufacturer'] = "Dell"
        # inject switch model info.
        facts['model'] = facts['system_type']
        facts
      end
    end
  end
end

class Array
  def to_ranges(seperator='..')
    compact.sort.uniq.inject([]) do |r,x|
      r.empty? || r.last.last.succ != x ? r << (x..x) : r[0..-2] << (r.last.first..x)
    end
  end
end

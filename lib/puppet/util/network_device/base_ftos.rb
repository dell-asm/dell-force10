require 'uri'
require 'openssl'
require 'cgi'
require 'puppet/util/network_device/transport_ftos'
require 'puppet/util/network_device/transport_ftos/base_ftos'
require '/etc/puppetlabs/puppet/modules/asm_lib/lib/security/encode'

class Puppet::Util::NetworkDevice::Base_ftos
  attr_accessor :url, :transport, :crypt
  def initialize(url)
    @url = URI.parse(url)
    @query = CGI.parse(@url.query) if @url.query

    require "puppet/util/network_device/transport_ftos/#{@url.scheme}"

    unless @transport
      @transport = Puppet::Util::NetworkDevice::Transport_ftos.const_get(@url.scheme.capitalize).new
      @transport.host = @url.host
      @transport.port = @url.port || case @url.scheme ; when "ssh" ; 22 ; when "telnet" ; 23 ; else ;23 ; end
      if @query && @query['crypt'] && @query['crypt'] == ['true']
        self.crypt = true
        # FIXME: https://github.com/puppetlabs/puppet/blob/master/lib/puppet/application/device.rb#L181
        master = File.read(File.join('/etc/puppet', 'networkdevice-secret'))
        master = master.strip
        @transport.user = decrypt(master, [@url.user].pack('h*')) unless @url.user.nil? || @url.user.empty?
        @transport.password = decrypt(master, [@url.password].pack('h*')) unless @url.password.nil? || @url.password.empty?
      else
        @transport.user = URI.decode(@url.user) unless @url.user.nil? || @url.user.empty?
        @transport.password = URI.decode(asm_decrypt(@url.password)) unless @url.password.nil? || @url.password.empty?
      end
    end
  end

  def decrypt(master, str)
    cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
    cipher.decrypt
    cipher.key = key = OpenSSL::Digest::SHA512.new(master).digest
    out = cipher.update(str)
    out << cipher.final
    return out
  end
end

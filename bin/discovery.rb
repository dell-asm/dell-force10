#!/opt/puppet/bin/ruby

require 'trollop'
require 'pathname'
require 'timeout'
require 'puppet'

modules_path = File.expand_path(Pathname.new(__FILE__).parent.parent.parent)
$LOAD_PATH << File.join(modules_path, 'dell_iom/lib')
$LOAD_PATH << File.join(modules_path, 'force10/lib')
require 'puppet_x/force10/transport'

facts = {}
opts = Trollop::options do
  opt :server, 'switch address', :type => :string
  opt :port, 'switch port', :default => 443
  opt :username, 'switch username', :type => :string
  opt :password, 'switch password', :type => :string
  opt :timeout, 'command timeout', :default => 240
  opt :credential_id, 'credential id in database', :type => :string
  opt :asm_decrypt, 'dummy value for ASM, not used'
  opt :community_string, 'dummy value for ASM, not used'
end

begin
  if (opts[:server].nil? || opts[:username].nil? || opts[:password].nil?) && opts[:credential_id].nil?
    raise "Must give server,username,and password parameters, or a valid credential id parameter."
  end
  Timeout.timeout(opts[:timeout]) do
    device_conf = {:scheme => 'ssh', :host => opts[:server], :port => opts[:port], :password => opts[:password],
                   :user=>opts[:username], :arguments=>{ :credential_id => opts[:credential_id] } }
    transport = PuppetX::Force10::Transport.new(nil, {:device_config => device_conf})
    facts = transport.facts
  end
rescue Timeout::Error
  puts "Timed out getting facts."
  exit 1
rescue Exception => e
  puts "#{e}\n#{e.backtrace.join("\n")}"
  exit 1
else
  if facts.empty?
    puts "Could not get updated facts"
    exit 1
  else
    facts.each do |fact, value|
      facts[fact] = value.to_s
    end
    puts facts.to_json
    exit 0
  end
end
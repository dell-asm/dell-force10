#MXL QuadMode Resource

require 'puppet/util/network_device/dell_ftos/model'
require 'puppet/util/network_device/dell_ftos/model/base'
require 'puppet/util/network_device/dell_ftos/model/scoped_value'

class Puppet::Util::NetworkDevice::Dell_ftos::Model::Quadmode < Puppet::Util::NetworkDevice::Dell_ftos::Model::Base

  attr_reader :params, :name
  def initialize(transport, facts, options)
    super(transport, facts)
    # Initialize some defaults
    @params         ||= {}
    @name           = options[:name] if options.key? :name
    @options        = options  

    # Register all needed Modules based on the availiable Facts
    register_modules
  end

  def update(is = {}, should = {})
    return unless configuration_changed?(is, should, :keep_ensure => true)
    missing_commands = [is.keys, should.keys].flatten.uniq.sort - @params.keys.flatten.uniq.sort
    missing_commands.delete(:ensure)
    raise Puppet::Error, "Undefined commands for #{missing_commands.join(', ')}" unless missing_commands.empty?
    [is.keys, should.keys].flatten.uniq.sort.each do |property|
      next if property == :acl_type
      next if should[property] == :undef
      @params[property].value = :absent if should[property] == :absent || should[property].nil?
      @params[property].value = should[property] unless should[property] == :absent || should[property].nil?
    end
    before_update
    perform_update(is, should)
    after_update
  end

  def before_update
    transport.command("show interfaces #{@name}")do |out|
      if out =~/Error:\s*(.*)/
        Puppet.debug "errror msg ::::#{$1}"
        raise "The entered interface does not exist. Enter the correct interface."
      end
    end
    super
  end
  
  def after_update
    transport.command("exit")
    super
  end
  
  def perform_update(is, should)
    interface_num = @name.scan(/(\d+)/).flatten.last
    case @params[:ensure].value
    when :present
      out = transport.command("stack-unit 0 port #{interface_num} portmode quad")
      transport.command("exit")
    when :absent
      transport.command("no stack-unit 0 port #{interface_num} portmode quad")
      transport.command("end")
	  else
      Puppet.debug("No value given for ensure")
    end
    # Reload switch
    if @reload_switch == :true
      Puppet.debug("Reload the switch to apply the configuration changes")
      tryrebootswitch
    else
      Puppet.debug("Skip reload operation")
    end
    
  end

  def mod_path_base
    return 'puppet/util/network_device/dell_ftos/model/quadmode'
  end

  def mod_const_base
    return Puppet::Util::NetworkDevice::Dell_ftos::Model::Quadmode
  end

  def param_class
    return Puppet::Util::NetworkDevice::Dell_ftos::Model::ScopedValue
  end

  def register_modules
    register_new_module(:base)
  end

  def tryrebootswitch()
   #Some times sending reload command returning with console prompt without doing anything; in that case retry reload, for max 3 times
   for i in 0..2
     if rebootswitch()
       break
     end
   end
 end

 def rebootswitch()
   dev = Puppet::Util::NetworkDevice.current
   flagfirstresponse=false
   flagsecondresponse=false
   flagthirdresponse=false

   dev.transport.command("reload")  do |out|
     firstresponse =out.scan("System configuration has been modified")
     secondresponse = out.scan("Proceed with reload")
     unless firstresponse.empty?
       flagfirstresponse=true
       break
     end
     unless secondresponse.empty?
       flagsecondresponse=true
       break
     end
   end

   #Some times sending reload command returning with console prompt without doing anything, in that case retry reload
   if !flagfirstresponse && !flagsecondresponse
     return false
   end

   if flagfirstresponse
     dev.transport.command("yes") do |out|
       thirdresponse = out.scan("Proceed with reload")
       unless thirdresponse.empty?
         flagthirdresponse=true
         break
       end
     end
     if flagthirdresponse
       dev.transport.command("yes") do |out|
         #without this block expecting for prompt and so hanging
         break
       end
     else
       Puppet.debug "ELSE BLOCK1.2"
     end
   else
     Puppet.debug "ELSE BLOCK1.1"
   end
   if flagsecondresponse
     dev.transport.command("yes") do |out|
       #without this block expecting for prompt and so hanging
       break
     end
   else
     Puppet.debug "ELSE BLOCK2"
   end

   #Sleep for 5 mins to wait for switch to come up
   Puppet.info("Going to sleep for 5 minutes, for switch reboot...")
   sleep 300

   Puppet.info("Checking if switch is up, pinging now...")
   for i in 0..20
     if pingable?(dev.transport.host)
       Puppet.info("Ping Succeeded, trying to reconnect to switch...")
       break
     else
       Puppet.info("Switch is not up, will retry after 1 min...")
       sleep 60
     end
   end

   #Re-esatblish transport session
   dev.connect_transport
   dev.switch.transport=dev.transport
   Puppet.info("Session established...")
   return true
 end

 def pingable?(addr)
   output = `ping -c 4 #{addr}`
   !output.include? "100% packet loss"
 end
end

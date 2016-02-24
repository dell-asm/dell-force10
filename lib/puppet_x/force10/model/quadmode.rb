#MXL QuadMode Resource
require 'puppet_x/force10/model/base'

class PuppetX::Force10::Model::Quadmode < PuppetX::Force10::Model::Base

  attr_reader :params, :name
  def initialize(transport, facts, options)
    super(transport, facts)
    # Initialize some defaults
    @params         ||= {}
    @name           = options[:name] if options.key? :name
    @options        = options  
    Puppet.debug("Options: #{@options.inspect}")

    # Register all needed Modules based on the availiable Facts
    register_modules
  end

  def update(is = {}, should = {}, reboot_required = false)
    Puppet.debug("Value of resource: #{reboot_required}")
    Puppet.debug("Is: #{is}, should = #{should}")
    before_update
    perform_update(is, should, reboot_required)
    after_update
  end

  def after_update
    transport.command("exit")
    super
  end
  
  def perform_update(is, should, reboot_required)
    interface_num = @name.scan(/(\d+)/).flatten.last
    if should[:ensure] == :present and is[:ensure] == :absent
      transport.command("stack-unit 0 port #{interface_num} portmode quad", :prompt => /confirm.*|conf.*/)
      transport.command("yes")
    elsif should[:ensure] == :absent and is[:ensure] == :present
      # Ensure that we are on the normal prompt
      transport.command("end")
      transport.command("conf")
      transport.command("no stack-unit 0 port #{interface_num} portmode quad", :prompt => /confirm.*|conf.*/)
      transport.command("yes")
    end
        
    # Reload switch
    if reboot_required == :true
      Puppet.debug("Reload the switch to apply the configuration changes")
      tryrebootswitch
    else
      Puppet.debug("Skip reload operation")
    end
    
  end

  def mod_path_base
    return 'puppet_x/force10/model/quadmode'
  end

  def mod_const_base
    return PuppetX::Force10::Model::Quadmode
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
   flagfirstresponse=false
   flagsecondresponse=false
   flagthirdresponse=false
   
   transport.command("end")
   Puppet.debug("We are inside the switch reboot loop")
   out = transport.command("show version")
   Puppet.debug("Version out : #{out}")

   transport.connect
   transport.command("reload", :prompt => /System configuration has been modified.*|Proceed with reload.*/ )
   transport.command("yes", :prompt => /Proceed with reload.*|.*#/)
   begin
     transport.command("yes")
   rescue
     Puppet.debug("Connection closed")
   end

   #Sleep for 5 mins to wait for switch to come up
   Puppet.info("Going to sleep for 2 minutes, for switch reboot...")
   sleep 120

   Puppet.info("Checking if switch is up, pinging now...")
   for i in 0..20
     if pingable?(transport.host)
       Puppet.info("Ping Succeeded, trying to reconnect to switch...")
       break
     else
       Puppet.info("Switch is not up, will retry after 1 min...")
       sleep 60
     end
   end

   #Re-esatblish transport session
   transport.connect
   # Ensure that connection is not closed by super class "exit"
   transport.command("conf")
   sleep(30)
   return true
 end

 def pingable?(addr)
   output = `ping -c 4 #{addr}`
   !output.include? "100% packet loss"
 end
end

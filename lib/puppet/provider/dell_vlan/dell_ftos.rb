require 'puppet/provider/dell_ftos'

Puppet::Type.type(:dell_vlan).provide :dell_ftos, :parent => Puppet::Provider::Dell_ftos do
  desc "Dell Switch / Router Provider for VLAN Configuration."
  mk_resource_methods

  def exists?
	Puppet.debug("Puppet::Provider::in checking for existence for resource #{@resource[:vlanid]}.")
	Puppet.debug("ensure = #{@resource[:ensure]}") 
	dev = Puppet::Util::NetworkDevice.current	
    	txt = ''    	
      	dev.transport.command('show vlan id '+ resource[:vlanid])  do |out|      
       txt << out
	end
	condcheck=txt.match(/(.*)Error: No such interface(.*)/)
	if condcheck
	 Puppet.debug("Puppet::VLAN NOT exist") 	
	 false
	else	
	  #Record exist, can delete!, this is entry flag for destroy operation
 	  @property_hash[:ensure] = :absent
	  true
	end		
  end

 def create  
	Puppet.debug("Puppet::Provider::in create for resource #{@resource[:vlanid]}.")
       fail "create vlan require vlanid parameter" unless resource[:vlanid]	
       Puppet.debug("ensure = #{@resource[:ensure]}") 	
	dev = Puppet::Util::NetworkDevice.current	 
    	txt = ''    	
      	dev.transport.command('conf')
       dev.transport.command('interface vlan ' + resource[:vlanid]) do |out|
         txt << out
	end
	dev.transport.command('end')	
  end

  def destroy	
    # Check required resource state
    if @property_hash[:ensure] == :absent	
	Puppet.debug("Puppet::Provider::in destroy for resource #{@resource[:vlanid]}.")
       fail "delete vlan require vlanid parameter" unless resource[:vlanid]   	
    	Puppet.debug("ensure = #{@resource[:ensure]}")    	 
	 dev = Puppet::Util::NetworkDevice.current	
    	 txt = ''    	
      	 dev.transport.command('conf')
        dev.transport.command('no interface vlan ' + resource[:vlanid]) do |out|
         txt << out
	 end
	dev.transport.command('end')
    end
  end
end
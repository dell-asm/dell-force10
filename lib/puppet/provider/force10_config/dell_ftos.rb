require 'puppet/util/network_device'
require 'puppet/provider/dell_ftos'
require 'digest/md5'
  
Puppet::Type.type(:force10_config).provide :dell_ftos, :parent => Puppet::Provider do
  mk_resource_methods

  def run(url, startup_config, force)
    if startup_config == :true
       return applyconfig(url,'startup-config',force)
    else
       return applyconfig(url,'running-config',force)      
    end    
  end
  
  def applyconfig(url, config, force)
    dev = Puppet::Util::NetworkDevice.current
    txt = ''
	digesttftpfile=''
	digestlocalfile=''
		
	   #delete temporary configuration files if exists
	   dev.transport.command('delete flash://temp-config no-confirm')
	   dev.transport.command('delete flash://last-config no-confirm')	
		
	   #Calculate MD5 for running configuration, if exists 
       localfilecontent	=''	   
	   if config=='startup-config'
			dev.transport.command('show file flash://startup-config') do |out|  
			 localfilecontent<< out
			 end
	   else
		   dev.transport.command('copy running-config flash://last-config') 
		   dev.transport.command('show file flash://last-config') do |out|  
			 localfilecontent<< out
		   end 
	   end
	   if localfilecontent =~/ERROR:\s*(.*)/
			Puppet.error "No current configuration exists "
	   else	   
		   #Remove the command string(show file flash://last-config) from output
		   if config=='running-config'
			localfilecontent.slice!(0..30)	
		   else
			localfilecontent.slice!(0..33)	
           end		   
		   digestlocalfile = Digest::MD5.hexdigest(localfilecontent) 
	   end
		   
	   #Copy TFTP file to local
	   tftpcopytxt=''
       dev.transport.command('copy ' +url+' temp-config') do |out|
	   tftpcopytxt<< out       
	   end
	   parseforerror(tftpcopytxt,'copying TFTP file')
	   
	   #Calculate MD5 for TFTP config file 
	   tftpfilecontent=''
	   dev.transport.command('show file flash://temp-config') do |out| 
        tftpfilecontent<< out
       end 
	   parseforerror(tftpfilecontent,'TFTP config MD5 caliculation')
	   #Remove the command string from output
       tftpfilecontent.slice!(0..30)		
	   digesttftpfile = Digest::MD5.hexdigest(tftpfilecontent)
	
	   Puppet.debug "MD5 for Local:"+digesttftpfile
	   Puppet.debug "MD5 for Tftp:"+digestlocalfile
	   
	  #Compare MD5 and so apply config if required 
	   if digesttftpfile==digestlocalfile && force == :false
			Puppet.info "No Configuration change"
	   else	    
	        #dev.transport.command('send * applying configuration on this switch')
			dev.transport.command('copy flash://temp-config '+config) do |out|			
			  txt<< out
		    end
	   end
	   
	   dev.transport.command('delete flash://last-config no-confirm')
       dev.transport.command('delete flash://temp-config no-confirm') 
	   if config=='startup-config' 
		#Reboot the switch
	      #dev.transport.command('send * rebooting now')
	      dev.transport.command('reload')
	   end
	return txt
  end
  
  def parseforerror(outtxt,placestr)
   if outtxt =~/ERROR:\s*(.*)/
			Puppet.error "#{$1}"
			raise "error occurred while doing switch configuration"
     end
  end
end
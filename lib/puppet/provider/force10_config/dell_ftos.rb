#Provide for force10 'CONFIG' Type
#Compares provided configuration MD5 with existing configuration MD5 and so apply the configuration if any change found
#Can use Force option for applying configuration always

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
	startupconfigexists=true
	startupconfigchanged=false
		
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
	   if localfilecontent =~/Error:\s*(.*)/
			Puppet.info "No current configuration exists "
			startupconfigexists=false
	   else	   
		   #Remove the command string(show file flash://last-config) from output		  
		   localfilecontent.slice!(0..localfilecontent.index('!'))		
  
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
	   parseforerror(tftpfilecontent,'retrieving local stored TFTP config file')
	   #Remove the command string from output
       tftpfilecontent.slice!(0..tftpfilecontent.index('!'))
		   
	   digesttftpfile = Digest::MD5.hexdigest(tftpfilecontent)
	
	   Puppet.debug "MD5 for Local:"+digesttftpfile
	   Puppet.debug "MD5 for Tftp:"+digestlocalfile
	   
	  #Compare MD5 and so apply config if required 
	   if digesttftpfile==digestlocalfile && force == :false
			Puppet.info "No Configuration change"
	   else	    
			#TODO:Sending notification to all opened terminals
			dev.transport.command('send *', :prompt => /.\n/)
			dev.transport.send("Applying configuration now!!! \x1A")
			dev.transport.send("\r")
			
			#Taking Backup of existing configuration
			#Delete existing backup file
			dev.transport.command('delete flash://'+config+'-backup  no-confirm')
			dev.transport.command('copy '+config+' flash://'+config+'-backup')			
			
			Puppet.debug startupconfigexists
			#In case startup-config already exists it will prompt for overwrite confirmation
			if config=='startup-config' && startupconfigexists						
				dev.transport.command('copy flash://temp-config '+config, :prompt => /.\n/)
				dev.transport.command("yes")
				startupconfigchanged=true				
			else			
				dev.transport.command('copy flash://temp-config '+config) do |out|			
				  txt<< out
				end
				 parseforerror(txt,"applying running configuration")
			end
	   end
	   
	  
	
	
	#ensure: Always delete the temporary files
	ensure	
	   dev.transport.command('delete flash://last-config no-confirm')
       dev.transport.command('delete flash://temp-config no-confirm') 
	   
	    if startupconfigchanged	
		  #TODO:Sending notification to all opened terminals
		  dev.transport.command('send *', :prompt => /.\n/)
		  dev.transport.send("Rebooting the switch Now!!! \x1A")
		  dev.transport.send("\r")
			
		  #Reboot the switch
		  dev.transport.command('reload', :prompt => /.\n/)
		  #For reload it will prompt for configuration modified confirmation
		  dev.transport.send("yes")
		  #For reload it will prompt for reload confirmation
		  dev.transport.send("yes")
	   end	
	return txt
  end
  
   def parseforerror(outtxt,placestr)
   if outtxt =~/Error:\s*(.*)/
			Puppet.info "ERROR:#{$1}"
			raise "Error occurred in - "+placestr+", Error:#{$1}"
     end
  end   
end
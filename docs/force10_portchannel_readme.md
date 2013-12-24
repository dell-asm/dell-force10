
#-------------------------------------------------------------------------------
# Functionality Supported
#-------------------------------------------------------------------------------

- Create Portchannels
- Remove Portchannels

#-------------------------------------------------------------------------------
# Description
#-------------------------------------------------------------------------------

The Portchannel type/provider supports the functionality to create and delete the Portchannels 
on the Dell Force10 switch.

#-------------------------------------------------------------------------------
# Summary of Properties
#-------------------------------------------------------------------------------

    name: (Required)This parameter defines the name of the port channel to be created/removed.
	
	desc:Description for the port channel
				
	mtu:	  - This parameter set mtu for the interface.
				If the value exists it set that value to mtu properties of thr  interface.
				If the value does not exists property remains unchanged (default or old values).
				value must be between  594-12000.
		
	shutdown: - This parameter defines whether or not to shut down the interface. 
				The possible values are true or false. The default value is "false".
				If the value is true it shut down the interface .
				value must be between 594-12000
				
	ensure: - This parameter defines whether to create the given port channel or delete the given port channel from the switch.
	           The possible values are present or absent.
	
    
# -------------------------------------------------------------------------
# Parameter signature 
# -------------------------------------------------------------------------

#Provide transport and Map properties

    force10_portchannel {
						'128':
						desc  => 'Port Channel for server connectivity',
						mtu=>'600',
						shutdown=>true,
						ensure=>present;
	

					} 

# --------------------------------------------------------------------------
# Usage
# --------------------------------------------------------------------------
   Refer to the examples in the manifest directory.
  The following files capture the details for the sample init.pp and the supported files:
   
    - sample_portchannel.pp
   
   A user can create a init.pp file based on the above sample files and call the "puppet device" command , for example: 
   # puppet device

#-------------------------------------------------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------------------------------------------------	

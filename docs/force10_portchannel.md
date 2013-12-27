# --------------------------------------------------------------------------
# Access Mechanism 
# --------------------------------------------------------------------------

The Dell Force10 switch module uses telnet/SSH to access Dell Force10 switches.

#-------------------------------------------------------------------------------
# Functionality Supported
#-------------------------------------------------------------------------------

- Create Portchannels
- Remove Portchannels

#-------------------------------------------------------------------------------
# Description
#-------------------------------------------------------------------------------

The Port Channel type/provider supports the functionality to create and delete the port channels 
on the Dell Force10 switches.

#-------------------------------------------------------------------------------
# Summary of Properties
#-------------------------------------------------------------------------------

    name: (Required)This parameter defines the name of the port channel to be created or removed.
	
	desc: This parameter defines the description for the port channel.
				
	mtu:	  - This parameter sets the mtu for the interface.
				If the value exist, it sets the value to the mtu properties of the interface.
				If the value does not exists, the property remains unchanged (default or old values).
				The mtu value must be between  594 and 12000.
		
	shutdown: - This parameter defines whether or not to shut down the interface. 
				The possible values are true or false. The default value is "false".
				If the value is "true", it shuts down the interface.
				The value must be between 594 and 12000.
				
	ensure: - This parameter defines whether to create the specified port channel or delete the specified port channel from the switch.
	          The possible values are "present" or "absent".
	
    
# -------------------------------------------------------------------------
# Parameter Signature 
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
  The following file contains the details for the sample init.pp and the supported files:
   
    - sample_portchannel.pp
   
   A user can create a init.pp file based on the above sample files and call the "puppet device" command , for example: 
   # puppet device

#-------------------------------------------------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------------------------------------------------	

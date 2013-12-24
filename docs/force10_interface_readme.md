# --------------------------------------------------------------------------
#  Supported Functionality
# --------------------------------------------------------------------------

	- Add port channel to interface

# -------------------------------------------------------------------------
# Functionality Description
# -------------------------------------------------------------------------


  1. Add port channel to interface

     The method map the port channel with a given interface.If  port channel does not exists it creates and map it to the interface. 


# -------------------------------------------------------------------------
# Summary of parameters.
# -------------------------------------------------------------------------

    name: (Required)This parameter defines the name of the interface for which port channel to be mapped.
	
	portchannel:This parameter defines the name of the port channel that is to be mapped.
				If the port channel exists it maps to the interface.
				If port channel does not exists it creates and add to the interface.
				value must be between 1-128
				
	mtu:This parameter set mtu for the interface.
		If the value exists it set that value to mtu properties of thr  interface.
		If the value does not exists property remains unchanged (default or old values).
		value must be between  594-12000.
		
	shutdown: - This parameter defines whether or not to shut down the interface. 
				The possible values are true or false. The default value is "false".
				If the value is true it shut down the interface .
				value must be between 594-12000
				
	switchport: - This parameter defines whether to enable or disable  the switch port. 
				The possible values are true or false. The default value is "false".
				If the value is true it enable the switch port.
	
    
# -------------------------------------------------------------------------
# Parameter signature 
# -------------------------------------------------------------------------

#Provide transport and Map properties

    force10_interface {
						'te 0/6':
						switchport  => true,
						portchannel=>'124',
						mtu=>'600',
						shutdown=>true;
	

					} 

# --------------------------------------------------------------------------
# Usage
# --------------------------------------------------------------------------
   Refer to the examples in the manifest directory.
  The following files capture the details for the sample init.pp and the supported files:
   
    - sample_interface_mapportchannel.pp
   
   A user can create a init.pp file based on the above sample files and call the "puppet device" command , for example: 
   # puppet device

#-------------------------------------------------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------------------------------------------------	

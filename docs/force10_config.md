# --------------------------------------------------------------------------
# Access Mechanism 
# --------------------------------------------------------------------------

The Dell Force10 switch module uses telnet/ssh to access Dell Force10 switch device.

# --------------------------------------------------------------------------
#  Supported Functionality
# --------------------------------------------------------------------------

	- Add/Update switch 'running' configuration
	- Add/Update switch 'startup' configuration

# -------------------------------------------------------------------------
# Functionality Description
# -------------------------------------------------------------------------


  1. Add/Update switch running configuration

     The method add or update the switch 'running' configuration. 
  2. Add/Update switch startup configuration

     The method add or update the switch 'startup' configuration. 


# -------------------------------------------------------------------------
# Summary of parameters.
# -------------------------------------------------------------------------

    name: (Required)This parameter defines the name of the operation.
		   Should be a string value with maximum 100 characters
	
	url:This parameter defines the TFTP turl of the configuration file.				
				
	force:This parameter enables configuration force apply.
		If the value true it will forcefully apply the configuration, if no configuration changes appear also.
		If the value false it will not apply the configuration if no configuration changes present.
		value must be either true or false.		
    
# -------------------------------------------------------------------------
# Parameter signature 
# -------------------------------------------------------------------------

#Provide transport and Map properties

   force10_config{
	'apply config':    	
		url     => 'tftp://172.152.0.36/running-config',    
		startup_config => false,
		force=>false; 
	}


# --------------------------------------------------------------------------
# Usage
# --------------------------------------------------------------------------
   Refer to the examples in the manifest directory.
  The following files capture the details for the sample init.pp and the supported files:
   
    - sample_config.pp
   
   A user can create a init.pp file based on the above sample files and call the "puppet device" command , for example: 
   # puppet device

#-------------------------------------------------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------------------------------------------------	

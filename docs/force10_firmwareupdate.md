# --------------------------------------------------------------------------
# Access Mechanism 
# --------------------------------------------------------------------------

The Force10 Firmware Update module uses telent/ssh to access Force10 device. The firmware update binary should be accessed by tftp protocol

# --------------------------------------------------------------------------
#  Supported Functionality
# --------------------------------------------------------------------------

	- Firmware Update

# -------------------------------------------------------------------------
# Functionality Description
# -------------------------------------------------------------------------


  1. Firmware Update

     This features updates the firmware in Force10 switch.

   
# -------------------------------------------------------------------------
# Summary of parameters.
# -------------------------------------------------------------------------

    locationurl: (Required) This path of the firmware binary.

	forceupdate: (Required) If it is set to true firmware update will run for any condition. Like even if the new firmware version is same as the existing firmware version,
				 firmware upgrade will happen.
    Possible values: true/false (default: false)
    
# -------------------------------------------------------------------------
# Parameter signature 
# -------------------------------------------------------------------------

#Provide firmwarelocation and forceupdate properties

  force10_firmwareupdate {
  'firmware_update':
    forceupdate => false,
    firmwarelocation => "tftp://172.152.0.89/Force10/FTOS-SE-9.1.0.0.bin"
}



# --------------------------------------------------------------------------
# Usage
# --------------------------------------------------------------------------
   Refer to the examples in the manifest directory.
   The following files capture the details of the sample init.pp and the supported files:

    - sample_init.pp_server
    - sample_force10_firmwareupdate.pp
   
   A user can create an init.pp file based on the above sample files, and call the "puppet device" command , for example: 
   # puppet device

#-------------------------------------------------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------------------------------------------------	

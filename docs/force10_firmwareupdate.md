# --------------------------------------------------------------------------
# Access Mechanism 
# --------------------------------------------------------------------------

The Dell Force10 switch module uses telnet/SSH to access the Dell Force10 switches. Use TFTP protocol to access the firmware update binary.

# --------------------------------------------------------------------------
#  Supported Functionality
# --------------------------------------------------------------------------

	- Firmware Update

# -------------------------------------------------------------------------
# Functionality Description
# -------------------------------------------------------------------------


  1. Firmware Update

     This features updates the firmware in the Dell Force10 switches.

   
# -------------------------------------------------------------------------
# Summary of Parameters.
# -------------------------------------------------------------------------

    locationurl: (Required) This parameter defines the path of the firmware binary.

	forceupdate: (Required) Use this parameter to force the firmware update irrespective of the firmware
	version configured on the switch. For example, if this parameter is set to "true", the firmware is updated on the switch 
	even if the firmware version that you want to update is same as the existing firmware version configured on the switch.
    Possible values: true/false (default: false)
    
# -------------------------------------------------------------------------
# Parameter Signature 
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
   The following file contains the details of the sample init.pp and the supported files:
   
    - sample_firmwareupdate.pp
   
   A user can create an init.pp file based on the above sample files, and call the "puppet device" command , for example: 
   # puppet device

#-------------------------------------------------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------------------------------------------------	

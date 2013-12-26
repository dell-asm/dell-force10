# --------------------------------------------------------------------------
# Access Mechanism 
# --------------------------------------------------------------------------

The Dell Force10 switch module uses telnet/ssh to access Dell Force10 switch device.

# --------------------------------------------------------------------------
#  Supported Functionality
# --------------------------------------------------------------------------

	- Create VLAN
	- Delete VLAN
	- Add interface to VLAN
	- Delete interface to VLAN
	- Add port-channel to VLAN
	- Delete port-channel to VLAN

# -------------------------------------------------------------------------
# Functionality Description
# -------------------------------------------------------------------------


  1. Create VLAN

     The method create a VLAN with given VLAN ID and supported information(for the time being only desc, tagged and untagged attributes available). 
  2. Delete VLAN

     The method deletes a VLAN having given VLAN ID.  
  3. Add interface to VLAN (apply tagged/untagged for interface)

     The method add interface as tagged/untagged for a given VLAN.If  interface does not exists it will throw error. 
  4. Delete interface to VLAN(apply 'no tagged'/'no untagged' for interface)

     The method delete interface as 'no tagged'/'no untagged' for a given VLAN.If  interface does not exists it will throw error.
  5. Add Port-channel to VLAN(apply tagged/untagged for port-channel)

     The method add port-channel tagged/untagged for a given VLAN.If  port-channel does not exists it will throw error. 
  4. Delete Port-channel to VLANapply 'no tagged'/'no untagged' for port-channel)

     The method delete port-channel as 'no tagged'/'no untagged' for a given VLAN.If  port-channel does not exists it will throw error.


# -------------------------------------------------------------------------
# Summary of parameters.
# -------------------------------------------------------------------------

    name: (Required)This parameter defines the vlanid of the VLAN.
		   Value should be between 1-4094
	
	desc: Name of the VLAN
		  Should be a string value with maximum 100 characters
	
	tagged_tengigabitethernet: TegGigabitEthernet interface need to be tagged(can provide as single or as range with comma seperated or Ex:0/16-0/17 or 0/18)
	
	tagged_gigabitethernet:GigabitEthernet interface need to be tagged(can provide as single or as range with comma seperated Ex:0/16-0/17 or 0/18)
	
	tagged_portchannel:Port-channel need to be tagged(can provide as single or multiple values with comma seperated Ex:1,2 or 3)
	
	tagged_sonet:SONET interface need to be tagged(can provide as single or multiple values with comma seperated Ex:1,2 or 3)
	
	untagged_tengigabitethernet: TegGigabitEthernet interface need to be untagged(can provide as single or as range with comma seperated or Ex:0/16-0/17 or 0/18)
	
	untagged_gigabitethernet:GigabitEthernet interface need to be untagged(can provide as single or as range with comma seperated Ex:0/16-0/17 or 0/18)
	
	untagged_portchannel:Port-channel need to be untagged(can provide as single or multiple values with comma seperated Ex:1,2 or 3)
	
	untagged_sonet:SONET interface need to be untagged(can provide as single or multiple values with comma seperated Ex:1,2 or 3)
		
    
# -------------------------------------------------------------------------
# Parameter signature 
# -------------------------------------------------------------------------

#Provide transport and Map properties

    #Add VLAN 180
	force10_vlan {
		  '180':    	
			desc     => 'test',
			ensure => present;
		}
		
    # This will add TenGigabitEthernet 0/16 and 0/17 interfaces to vlan 180 as tagged
	force10_vlan {
	  '180':    	
		desc     => 'test',
		ensure => present, 
		tagged_tengigabitethernet => '0/16-17';    
	}
	
	# This will add TenGigabitEthernet 0/16 and 0/17 Port-channel to vlan 180 as untagged
	force10_vlan {
	  '180':    	
		desc     => 'test',
		ensure => present, 
		untagged_portchannel => '1,20';   
	}


# --------------------------------------------------------------------------
# Usage
# --------------------------------------------------------------------------
   Refer to the examples in the manifest directory.
  The following files capture the details for the sample init.pp and the supported files:
   
    - sample_vlan.pp
	- sample_vlan_taginterface.pp
	- sample_vlan_untaginterface.pp
	- sample_vlan_tagportchannel.pp
	- sample_vlan_untagportchannel.pp
   
   A user can create a init.pp file based on the above sample files and call the "puppet device" command , for example: 
   # puppet device

#-------------------------------------------------------------------------------------------------------------------------
# End
#-------------------------------------------------------------------------------------------------------------------------	

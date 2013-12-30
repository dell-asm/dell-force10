# --------------------------------------------------------------------------
# Access Mechanism 
# --------------------------------------------------------------------------

The Dell Force10 switch module uses telnet/SSH to access Dell Force10 switches.

# --------------------------------------------------------------------------
# Supported Functionality
# --------------------------------------------------------------------------

	- Create VLAN
	- Delete VLAN
	- Add interface to VLAN
	- Delete interface to VLAN
	- Add port channel to VLAN
	- Delete port channel to VLAN

# -------------------------------------------------------------------------
# Functionality Description
# -------------------------------------------------------------------------


  1. Create VLAN

     This method creates a VLAN based on the VLAN ID specified and the supported information. The VLAN information that are currently supported are description, tagged, and untagged attributes. 
  2. Delete VLAN

     This method deletes a VLAN based on the VLAN ID specified.  
  3. Add interface to VLAN (apply tagged/untagged for interface)

     This method adds the interface to the VLAN specified as 'tagged' or 'untagged'. If the interface does not exist, then it will display an exception. 
  4. Delete interface to VLAN(apply 'no tagged'/'no untagged' for interface)

     This method deletes the interface of the VLAN specified as 'no tagged' or 'no untagged'. If the interface does not exist, then it will display an exception.
  5. Add port channel to VLAN(apply tagged/untagged for port-channel)

     This method adds the port channel to the VLAN specified as 'tagged' or 'untagged'. If the port channel does not exist, then it will display an exception. 
  4. Delete port channel to VLANapply 'no tagged'/'no untagged' for port channel)

     This method deletes the port channel of the VLAN specified as 'no tagged'/'no untagged'. If the port channel does not exist, then it will display an exception.


# -------------------------------------------------------------------------
# Summary of Parameters
# -------------------------------------------------------------------------

	name: (Required)This parameter defines the VLAN ID of the VLAN.
	      The value must be between 1 and 4094.
	
	desc: This parameter defines the description of the VLAN
	      The value must be a string and cannot exceed 100 characters.
	
	vlan_name:This parameter defines the name of the VLAN
	      The value must be a string and cannot exceed 100 characters.
	
	tagged_tengigabitethernet: This parameter defines the TegGigabitEthernet interface that needs to be tagged. You can enter a single interface or range of interfaces separated by commas or Ex:0/16-0/17 or 0/18
	
	tagged_gigabitethernet:This parameter defines the GigabitEthernet interface that needs to be tagged. You can enter a single interface or range of interfaces separated by commas or Ex:0/16-0/17 or 0/18
	
	tagged_portchannel: This parameter defines the port channel that needs to be tagged. You can enter a single interface or range of interfaces separated by commas or Ex:0/16-0/17 or 0/18
	
	tagged_sonet: This parameter defines the SONET interface that needs to be tagged. You can enter a single interface or range of interfaces separated by commas or Ex:0/16-0/17 or 0/18
	
	untagged_tengigabitethernet: This parameter defines the TegGigabitEthernet interface that needs to be untagged. You can enter a single interface or range of interfaces separated by commas or Ex:0/16-0/17 or 0/18
	
	untagged_gigabitethernet: This parameter defines GigabitEthernet interface that needs to be untagged. You can enter a single interface or range of interfaces separated by commas or Ex:0/16-0/17 or 0/18
	
	untagged_portchannel: This parameter defines the port channel that needs to be untagged. You can enter a single interface or range of interfaces separated by commas or Ex:0/16-0/17 or 0/18
	
	untagged_sonet: This parameter defines the SONET interface that needs to be untagged. You can enter a single interface or range of interfaces separated by commas or Ex:0/16-0/17 or 0/18
		
    
# -------------------------------------------------------------------------
# Parameter Signature 
# -------------------------------------------------------------------------

#Provide transport and Map properties

    #Add VLAN 180
	force10_vlan {
		  true:    	
			desc     => 'test',
			ensure => present;
		}
		
    # This will add TenGigabitEthernet 0/16 and 0/17 interfaces to VLAN 180 as tagged
	force10_vlan {
	  '180':    	
		desc     => 'test',
		ensure => present, 
		tagged_tengigabitethernet => '0/16-17';    
	}
	
	# This will add TenGigabitEthernet 0/16 and 0/17 Port-channel to VLAN 180 as untagged
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
  The following files contain the details of the sample init.pp and the supported files:
   
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

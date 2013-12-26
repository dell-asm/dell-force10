# Dell Force10 switch module

**Table of Contents**

- [Dell Force10 switch module](#Dell-Force10-switch-module)
	- [Overview](#overview)
	- [Features](#features)
	- [Requirements](#requirements)
	- [Usage](#usage)
		- [Device Setup](#device-setup)
		- [Dell Force10 operations](#Dell-Force10-operations)

## Overview
The Dell Force10 switch module is designed to extend the support for managing Dell Force10 switch configuration using Puppet and its Network Device functionality.

The Dell Force10 switch module has been written and tested against the following Dell Force10 switch models:
- S4810(software version 9.2(0.2)) 
However, this module may be compatible with other models & their software versions.


## Features
This module supports the following functionality:

 * VLAN creation and deletion.
 * Interface configuration.
 * Portchannel creation and deletion.
 * Add interface to VLAN
 * Delete interface from VLAN
 * Add Port-channel to VLAN
 * Remove Port-channel from VLAN
 * Configuration updates.
 * Firmware updates.

## Requirements
As a Puppet agent cannot be directly installed on the Dell Force10 switch, it can either be managed from the Puppet Master server,
or through an intermediate proxy system running a puppet agent. The requirements for the proxy system are as under:

 * Puppet 2.7.+

## Usage

### Device Setup
To configure a Dell Force10 switch, the device *type* must be `dell_ftos`.
The device can either be configured within */etc/puppet/device.conf*, or, preferably, create an individual config file for each device within a sub-folder.
This is preferred as it allows the user to run the puppet against individual devices, rather than all devices configured...

In order to run the puppet against a single device, you can use the following command:

    puppet device --deviceconfig /etc/puppet/device/[device].conf

Example configuration `/etc/puppet/device/force10.example.com.conf`:

      [force10.example.com]
      type dell_ftos
      url ssh://admin:P@ssw0rd@force10.example.com/?enable=P@ssw0rd

### Dell Force10 operations
This module can be used to configure vlans, interfaces and port-channels on Dell Force10 switch.
For example: 

#This creates a portchannel `128`, as per the values defined for various parameters in the above definition.
node "force10.example.com" {
    force10_portchannel { '128':
      desc     => 'Port Channel for server connectivity',
      mtu      => '600',
      shutdown => true,
      ensure   => present;
    }
  }

# This creates VLAN 180 and add TenGigabitEthernet 0/16 and 0/17 interfaces as tagged
node "force10.example.com" {
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
}


You can also use any of the above operations individually, or create new defined types, as required. The details of each operation and parameters 
are mentioned in the following readme files, that are shipped with the module:

  - force10_interface.md
  - force10_portchannel.md
  - force10_firmwareupdate.md
  - force10_vlan.md
  - force10_config.md



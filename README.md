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

The Dell Force10 switch module has been written and tested against the following Dell Force10 switch models. However, this module may be compatible with other models and 
their software versions.

-S4810(software version 9.2(0.2)) 


## Features
This module supports the following functionality:

 * VLAN Creation and Deletion
 * Interface Configuration
 * Port Channel Creation and Deletion
 * Configuration Updates
 * Firmware Updates

## Requirements
Because the Puppet agent cannot be directly installed on a Dell Force10 switch, the agent can be managed either using the Puppet Master server,
or through an intermediate proxy system running a Puppet agent. The following are the requirements for the proxy system:

 * Puppet 2.7.+

## Usage

### Device Setup
To configure a Dell Force10 switch, the device *type* specified in `device.conf` must be `dell_ftos`.
The device can either be configured within */etc/puppet/device.conf*, or, preferably, create an individual config file for each device within a sub-folder.
This is preferred because it allows the user to run the Puppet against individual devices, rather than all devices configured.

To run the Puppet against a single device, use the following command:

    puppet device --deviceconfig /etc/puppet/device/[device].conf

Example configuration `/etc/puppet/device/force10.example.com.conf`:

      [force10.example.com]
      type dell_ftos
      url ssh://admin:password@force10.example.com/?enable=password

### Dell Force10 Operations
This module can be used to configure VLANs, interfaces, and port channels on Dell Force10 switch.
For example: 
```
node "force10.example.com" {
  force10_portchannel { '128':
    desc       => 'Port Channel for server connectivity',
    mtu        => '600',
    switchport => true,
    shutdown   => true,
    ensure     => present;
  }
}
```
This creates a port channel `128`, based on the values defined for various parameters in the above definition.
```
node "force10.example.com" {
  # Add VLAN 180
  force10_vlan { '180':
    desc   => 'test',
    ensure => present;
  }

  # This will add TenGigabitEthernet 0/16 and 0/17 interfaces to vlan 180 as tagged
  force10_vlan { '180':
    desc   => 'test',
    ensure => present,
    tagged_tengigabitethernet => '0/16-17';
  }
}
```
This creates VLAN `180` and add TenGigabitEthernet `0/16` and `0/17` interfaces as tagged in the above definition.

Can use `require` property to maintain order between resource configurations, as below
```
node "force10.example.com" {
  # Apply startup-configuration
  force10_config { 'apply config':
    url            => 'tftp://172.152.0.36/startup-config',
    startup_config => true,
    force          => true;
  }

  # Create VLAN 180 after applying configuration, order maintained using 'require'
  force10_vlan { '180':
    desc      => 'test',
    ensure    => present,
    vlan_name => 'test name',
    require   => force10_config['apply config'];
  }
}
```

You can also use any of the above operations individually, or create new defined types, as required.

For additional examples, see tests folder.

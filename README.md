## Dell Force10 Networkdevice Module


## Overview

The Dell Force10 Networkdevice Module provides a common way to manage various configuration properties with Puppet and was initially based on the network_device utility provided by Puppet.

## Currently implemented / tested Puppet Types


## Partially implemented


## Tested with the following Force10 Switchtypes

* S4810


## Tested with the following Software Versions for S4810
  * Dell Force10 Real Time Operating System Software
  * Dell Force10 Operating System Version: 2.0
  * Dell Force10 Application Software Version: 9.2(0.2)


## Usage

device.conf

    [$switch_fqdn]
    type dell_ftos
    url ssh://$user:$pass@$switch_fqdn:$ssh_port/?$flags


Note: If you want to see the Communication with the Switch append --debug to the Puppet device Command

## Who ?


## Code Status



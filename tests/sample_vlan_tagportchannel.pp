# Tagging or 'no Tagging' Port-channel
# Tagging always OVERRIDES the existing tagged Port-channels, means will apply 'no tagged' for all existed tagged Port-channel for
# this vlan and add newly provided Port-channels ad tagged
# Can remove all tagged Port-channel by passing value 'absent'

# This will add TenGigabitEthernet 0/16 and 0/17 Port-channel to vlan 180 as tagged
force10_vlan { '180':
  desc               => 'test',
  ensure             => present,
  tagged_portchannel => '1,20';
}

# Remove all existed tagged Port-channel from vlan 180
force10_vlan { '180':
  desc               => 'test',
  ensure             => present,
  tagged_portchannel => absent;
}
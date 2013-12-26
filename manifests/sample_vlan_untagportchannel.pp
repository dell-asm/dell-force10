# Untagging or 'no Untagging' Port-channel
# Untagging always OVERRIDES the existing Untagged Port-channel, means will apply 'no untagged' for all existed untagged
# Port-channel for this vlan and so add newly provided Port-channel as untagged
# Can remove all untagged Port-channel by passing value 'absent'

# This will add TenGigabitEthernet 0/16 and 0/17 Port-channel to vlan 180 as untagged
force10_vlan { '180':
  desc                 => 'test',
  ensure               => present,
  untagged_portchannel => '1,20';
}

# Remove all existed untagged Port-channel from vlan 180
force10_vlan { '180':
  desc                 => 'test',
  ensure               => present,
  untagged_portchannel => absent;
}
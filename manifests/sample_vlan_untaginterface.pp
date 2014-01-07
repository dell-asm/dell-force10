# Untagging or 'no Untagging' interface
# UnTagging always OVERRIDES the existing UnTagged interfaces, means will apply 'no untagged' for all existed untagged interfaces
# for this vlan and so add newly provided interfaces as untagged
# Can remove all untagged interfaces by passing value 'absent'

# This will tag TenGigabitEthernet 0/16 and 0/17 interfaces to vlan 180
force10_vlan { '180':
  desc   => 'test',
  ensure => present,
  untagged_tengigabitethernet => '0/16-17';
}

# This will add GigabitEthernet 0/16 and 0/17 interfaces to vlan 180 as untagged
force10_vlan { '180':
  desc                   => 'test',
  ensure                 => present,
  tagged_gigabitethernet => '0/16-17';
}

# This will add SONET 0/16 and 0/17 interfaces to vlan 180 as untagged
force10_vlan { '180':
  desc           => 'test',
  ensure         => present,
  untagged_sonet => '0/16-17';
}

# Remove all existed untagged TegGigabitEthernet interfaces from vlan 180
force10_vlan { '180':
  desc   => 'test',
  ensure => present,
  untagged_tengigabitethernet => absent;
}
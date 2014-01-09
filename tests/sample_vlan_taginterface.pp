# Tagging or 'no Tagging' interface
# Tagging always OVERRIDES the existing tagged interfaces, means will apply 'no tagged' for all existed tagged interfaces for this
# vlan and so add newly provided interfaces as tagged
# Can remove all tagged interfaces by passing value 'absent'

# This will add TenGigabitEthernet 0/16 and 0/17 interfaces to vlan 180 as tagged
force10_vlan { '180':
  desc   => 'test',
  ensure => present,
  tagged_tengigabitethernet => '0/16-17';
}

# This will add GigabitEthernet 0/16 and 0/17 interfaces to vlan 180 as tagged
force10_vlan { '180':
  desc                   => 'test',
  ensure                 => present,
  tagged_gigabitethernet => '0/16-17';
}

# This will add SONET 0/16 and 0/17 interfaces to vlan 180 as tagged
force10_vlan { '180':
  desc         => 'test',
  ensure       => present,
  tagged_sonet => '0/16-17';
}

# Remove all existed tagged TegGigabitEthernet interfaces from vlan 180
force10_vlan { '180':
  desc   => 'test',
  ensure => present,
  tagged_tengigabitethernet => absent;
}
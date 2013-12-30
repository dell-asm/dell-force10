# Add or delete a VLAN

# Add VLAN 180
force10_vlan { '180':
  desc   => 'test desc',
  vlan_name=> 'test name'
  ensure => present;
}

# Delete VLAN 180
force10_vlan { '180':
  desc   => 'test desc',
  vlan_name=> 'test name'
  ensure => absent;
}


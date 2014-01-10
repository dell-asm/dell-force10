force10_portchannel { '128':
  desc     => 'Port Channel for server connectivity',
  mtu      => '600',
  switchport => true,
  shutdown => true,
  ensure   => present;
}

force10_interface { 'te 0/6':
  switchport  => true,
  portchannel => '124',
  mtu         => '600',
  shutdown    => true;
}

    force10_portchannel {
						'128':
						desc  => 'Port Channel for server connectivity',
						mtu=>'600',
						shutdown=>true,
						ensure=>present;
	

					} 

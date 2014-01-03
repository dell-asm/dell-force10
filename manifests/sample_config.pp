# Applying running or startup configuration
# Checks MD5 value of existing configuration and provided configuration; if no change configuration will not be applied
# For calculation of MD5- trimming off version, last configuration changed date, startup configuration updated date sections from
# configuration file content and so calculating MD5 on remaining file content
# Can use force option for force apply of configuration
# This will take backup of existing configuration as flash://startup-config-backup or flash://running-config-backup
# If configuration is startup config, then switch will be rebooted and so re-establish transport session to handle further
# configurations provided in site.pp

# Applying running configuration
force10_config { 'apply config':
  url            => 'tftp://172.152.0.36/running-config',
  startup_config => false,
  force          => false;
}

# Applying startup configuration
force10_config { 'apply config':
  url            => 'tftp://172.152.0.36/startup-config',
  startup_config => true,
  force          => false;
}

# Force apply of startup configuration
force10_config { 'apply config':
  url            => 'tftp://172.152.0.36/startup-config',
  startup_config => true,
  force          => true;
}

# Can use 'require' property to maintain order between resource configurations, as below

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


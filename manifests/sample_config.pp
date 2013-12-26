# Applying running or startup configuration
# Checks MD5 value of existing configuration and provided configuration; if no change configuration will not be applied
# Can use force option for force apply of configuration
# **This will take backup of existing configuration as flash://startup-config-backup or flash://running-config-backup

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

class Force10_config_fixture_with_startupconfig

  attr_accessor :force10_config, :provider
  def initialize
    @force10_config = get_force10_config
    @provider = force10_config.provider
  end

  private

  def  get_force10_config
    Puppet::Type.type(:force10_config).new(
    :name => 'config1',
    :force => 'true',
    :startup_config => 'true',
    :url => 'tftp://10.10.10.10/sss.scr'
    )
  end

end

class Force10_config_fixture_with_runningconfig

  attr_accessor :force10_config, :provider
  def initialize
    @force10_config = get_force10_config
    @provider = force10_config.provider
  end

  private

  def  get_force10_config
    Puppet::Type.type(:force10_config).new(
    :name => 'config1',
    :force => 'true',
    :startup_config => 'false',
    :url => 'tftp://10.10.10.10/sss.scr'
    )
  end

end
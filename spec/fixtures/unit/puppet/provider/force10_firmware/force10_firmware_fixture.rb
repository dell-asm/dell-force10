class Force10_firmware_fixture

  attr_accessor :force10_firmware, :provider
  def initialize
    @force10_firmware = get_force10_firmware
    @provider = force10_firmware.provider
  end

  private

  def  get_force10_firmware
    Puppet::Type.type(:force10_firmwareupdate).new(
    :name               => 'image1',
    :url    => 'tftp://172.152.0.89/Force10/FTOS-SE-9.2.0.2.bin',
    :force        => true
    )
  end

  public

  def geturl
    force10_firmware[:url]
  end
end
  

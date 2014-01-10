#! /usr/bin/env ruby

require 'spec_helper'
require 'fixtures/unit/puppet/provider/force10_firmware/Force10_firmware_fixture'

describe Puppet::Type.type(:force10_firmwareupdate).provider(:dell_ftos) do

  context "when force10 firmware provider is created " do

    it "should have parent 'Puppet::Provider'" do
      described_class.new.should be_kind_of(Puppet::Provider)
    end

    it "should have updatestartupconfig method defined for updating startup config" do
      described_class.instance_method(:updatestartupconfig).should_not == nil
    end

    it "should have tryrebootswitch method defined for trying to reboot the switch" do
      described_class.instance_method(:tryrebootswitch).should_not == nil
    end

    it "should have reboot_switch method defined for rebooting  switch" do
      described_class.instance_method(:rebootswitch).should_not == nil
    end

    it "should have getfirmwareversion method defined for getting firmware version" do
      described_class.instance_method(:getfirmwareversion).should_not == nil
    end

  end

end


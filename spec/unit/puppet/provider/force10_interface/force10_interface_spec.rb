#! /usr/bin/env ruby
require 'spec_provider_helper'
require 'puppet/provider/force10_interface/dell_ftos'

provider_class = Puppet::Type.type(:force10_interface).provider(:dell_ftos)

describe provider_class do

  before do
    @interface = stub_everything 'interface'
    @interface.stubs(:name).returns('te 0/6')
    @interface.stubs(:params_to_hash)
    @interfaces = [ @interface ]

    @switch = stub_everything 'switch'
    @switch.stubs(:interface).returns(@interfaces)
    @switch.stubs(:params_to_hash).returns({})

    @device = stub_everything 'device'
    @device.stubs(:switch).returns(@switch)

    @resource = stub('resource', :desc => "INT")

    @provider = provider_class.new(@device, @resource)

  end

  it "should have a parent of Puppet::Provider::Dell_ftos" do
    provider_class.should < Puppet::Provider::Dell_ftos
  end

  it "should have an instances method" do
    provider_class.should respond_to(:instances)
  end

  describe "when looking up instances at prefetch" do
    before do
      @device.stubs(:command).yields(@device)
    end

    it "should delegate to the device interface fetcher" do
      @device.expects(:switch).returns(@switch)
      @switch.expects(:interface).with('te 0/6').returns(@interface)
      @interface.expects(:params_to_hash)
      provider_class.lookup(@device, 'te 0/6')
    end

    it "should return the given configuration data" do
      @device.expects(:switch).returns(@switch)
      @switch.expects(:interface).with('te 0/6').returns(@interface)
      @interface.expects(:params_to_hash).returns({ :desc => "INT" })
      provider_class.lookup(@device, 'te 0/6').should == { :desc => "INT" }
    end
  end

  describe "when the configuration is being flushed" do
    it "should call the device configuration update method with current and past properties" do
      @instance = provider_class.new(@device, :ensure => :present, :name => 'te 0/6', :mtu => '1110')
      @instance.resource = @resource
      @resource.stubs(:[]).with(:name).returns('te 0/6')
      @instance.stubs(:device).returns(@device)
      @switch.expects(:interface).with('te 0/6').returns(@interface)
      @switch.stubs(:facts).returns({})
      @interface.expects(:update).with({:ensure => :present, :name => 'te 0/6', :mtu => '1110'},
      {:ensure => :present, :name => 'te 0/6', :mtu => '1110'})
      @interface.expects(:update).never

      #@instance.desc = "FOOBAR"
      @instance.flush
    end
  end

end


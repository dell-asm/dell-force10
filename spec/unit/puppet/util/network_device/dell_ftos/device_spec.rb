#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/util/network_device/dell_ftos/device'

describe Puppet::Util::NetworkDevice::Dell_ftos::Device do
  before(:each) do
    @transport = stub_everything 'transport', :is_a? => true, :command => '',:user => 'user',:password => 'password'
    @dell = Puppet::Util::NetworkDevice::Dell_ftos::Device.new('ssh://user:password@localhost:22/')
    @dell.transport = @transport
  end

  describe 'when creating the device' do
    it 'should find the enable password from the url' do
      dell = Puppet::Util::NetworkDevice::Dell_ftos::Device.new('ssh://user:password@localhost:22/?enable=enable_password')
      dell.enable_password == 'enable_password'
    end

    it 'should prefer the enable password from the options' do
      dell = Puppet::Util::NetworkDevice::Dell_ftos::Device.new('ssh://user:password@localhost:22/?enable=enable_password', :enable_password => 'mypass')
      dell.enable_password == 'mypass'
    end

    it 'should find the crypt bool from the url' do
      File.stubs(:read).with('/etc/puppet/networkdevice-secret').returns('foobar')
      dell = Puppet::Util::NetworkDevice::Dell_ftos::Device.new('ssh://96cc073a43df48098b6b4cae9366c677:7d211471517adf2821bd88ced8e8d378@localhost:22/?enable=enable_password&crypt=true')
      dell.crypt == true
    end

    it 'should decrypt the provided user and password' do
      Puppet.stubs(:[]).with(:confdir).returns('/etc/puppet')
      File.stubs(:read).with('/etc/puppet/networkdevice-secret').returns('foobar')
      dell = Puppet::Util::NetworkDevice::Dell_ftos::Device.new('ssh://96cc073a43df48098b6b4cae9366c677:7d211471517adf2821bd88ced8e8d378@localhost:22/?enable=enable_password&crypt=true')
      dell.transport.user.should == 'user'
      dell.transport.password.should == 'pass'
    end

  end

  describe "when connecting to the physical device" do
    it "should connect to the transport" do
      @transport.expects(:connect)
      @dell.connect_transport
    end

    it "should attempt to login" do
      @dell.expects(:login)
      @dell.connect_transport
    end

    it "should tell the device to not page" do
      @transport.expects(:command).with("terminal length 0", :noop => false)
      @dell.connect_transport
    end

    it "should enter the enable password if returned prompt is not privileged" do
      @transport.stubs(:command).yields("Switch>").returns("")
      @dell.expects(:enable)
      @dell.connect_transport
    end

    it "should create the switch object" do
      Puppet::Util::NetworkDevice::Dell_ftos::Model::Switch.expects(:new).with(@transport, {}).returns(stub_everything('switch'))
      # TODO: Convert it to Method calls
      # Dont't access IVars directly
      @facts = stub_everything 'facts'
      @facts.stubs(:facts_to_hash).returns({})
      @dell.instance_variable_set(:@facts, @facts)
      @dell.init_switch
    end

    describe "when login in" do
      it "should not login if transport handles login" do
        @transport.expects(:handles_login?).returns(true)
        @transport.expects(:command).never
        @transport.expects(:expect).never
        @dell.login
      end

      it "should send username if one has been provided" do
        @transport.expects(:command).with("user", {:prompt => /^Password:/, :noop => false})
        @dell.login
      end

      it "should send password after the username" do
        @transport.expects(:command).with("user", {:prompt => /^Password:/, :noop => false})
        @transport.expects(:command).with("password", :noop => false)
        @dell.login
      end

      #it "should expect the Password: prompt if no user was sent" do
      #@transport.user = ''
      #@transport.expects(:expect).with(/^Password:/)
      #@transport.expects(:command).with("password", :noop => false)
      #@dell.login
      #end

    end

    describe "when entering enable password" do
      it "should raise an error if no enable password has been set" do
        @dell.enable_password = nil
        lambda{ @dell.enable }.should raise_error
      end

      it "should send the enable command and expect an enable prompt" do
        @dell.enable_password = 'mypass'
        @transport.expects(:command).with("enable", {:prompt => /^Password:/, :noop => false})
        @dell.enable
      end

      it "should send the enable password" do
        @dell.enable_password = 'mypass'
        @transport.stubs(:command).with("enable", {:prompt => /^Password:/, :noop => false})
        @transport.expects(:command).with("mypass", :noop => false)
        @dell.enable
      end
    end

    describe "when having parsed a configuration" do
      before do
        @data = <<END
!
interface TenGigabitEthernet 0/0
 no ip address
 mtu 12000
 dcb-policy input pfc
 dcb-policy output ets
!
 port-channel-protocol LACP
  port-channel 10 mode active
!
 protocol lldp
 no shutdown
!
interface TenGigabitEthernet 0/1
 no ip address
 mtu 12000
 dcb-policy input pfc
 dcb-policy output ets
!
 port-channel-protocol LACP
  port-channel 10 mode active
!
 protocol lldp
 no shutdown
!
END
        @transport.stubs(:command).with("show running-config", {:cache => true, :noop => false}).returns(@data)
        #@facts = Puppet::Util::NetworkDevice::Dell_ftos::Facts.new(@transport)
        @facts = stub_everything 'facts'
        @facts.stubs(:facts_to_hash).returns({})
        @dell.instance_variable_set(:@facts, @facts)
        @dell.init_switch
      end

      #it "should have interfaces" do
      #@dell.switch.params[:interfaces].value.should_not be_empty
      #end

      it "should be able to lookup interfaces" do
        @dell.switch.interface('TenGigabitEthernet 0/1').should_not be_nil
      end
    end

  end
end

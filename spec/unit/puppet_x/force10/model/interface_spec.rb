#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet_x/force10/model'
require 'puppet_x/force10/model/interface'

provider_class = Puppet::Type.type(:force10_interface).provider(:dell_ftos)

describe PuppetX::Force10::Model::Interface do

  before do
    @config = File.read('spec/fixtures/config.out')
    @transport = double('transport').as_null_object
    @transport.stub(:command)
    @transport.stub(:command).with("sh run", :cache => true, :noop => false).and_return(@config)
    PuppetX::Force10::Transport::Ssh.any_instance.stub(:send).and_return("")
    PuppetX::Force10::Model::Interface.any_instance.stub(:before_update)
    PuppetX::Force10::Model::Interface.any_instance.stub(:after_update)
  end

  describe 'when looking up an interface' do
    it 'finds existing interface' do
      name = 'TenGigabitEthernet 0/1'
      interface = PuppetX::Force10::Model::Interface.new(@transport, @config, {:name=>name})
      params = interface.retrieve
      params[:ensure].should == :present
    end

    it 'finds existing interface with downcased/unspaced name' do
      name = 'tengigabitethernet0/1'
      interface = PuppetX::Force10::Model::Interface.new(@transport, @config, {:name=>name})
      config = interface.retrieve
      config[:ensure].should == :present
    end
  end

  describe 'when configuration needs updating' do
    it 'should enable switchport' do
      name = 'TenGigabitEthernet 0/1'
      interface = PuppetX::Force10::Model::Interface.new(@transport, @config, {:name=>name})
      interface.retrieve
      old_params = interface.params_to_hash
      new_params = old_params.dup
      new_params[:switchport] = :true
      @transport.should_receive(:command).with("switchport")
      interface.update(old_params, new_params)
    end

    it 'should disable switchport' do
      name = 'TenGigabitEthernet 0/2'
      interface = PuppetX::Force10::Model::Interface.new(@transport, @config, {:name=>name})
      interface.retrieve
      old_params = interface.params_to_hash
      new_params = old_params.dup
      new_params[:switchport] = :false
      @transport.should_receive(:command).with("no switchport")
      interface.update(old_params, new_params)
    end

    it 'should enable hybrid mode' do
      name = 'TenGigabitEthernet 0/3'
      interface = PuppetX::Force10::Model::Interface.new(@transport, @config, {:name=>name})
      interface.retrieve
      old_params = interface.params_to_hash
      new_params = old_params.dup
      new_params[:portmode] = :true
      @transport.should_receive(:command).with("portmode hybrid")
      interface.update(old_params, new_params)
    end

    it 'should setup portchannel' do
      name = 'TenGigabitEthernet 0/4'
      interface = PuppetX::Force10::Model::Interface.new(@transport, @config, {:name=>name})
      interface.retrieve
      old_params = interface.params_to_hash
      new_params = old_params.dup
      new_params[:portchannel] = 20
      PuppetX::Force10::Model::Interface::Base.should_receive(:update_vlans).with(@transport, [], true, name.split)
      PuppetX::Force10::Model::Interface::Base.should_receive(:update_vlans).with(@transport, [], false, name.split)
      @transport.should_receive(:command).with("port-channel 20 mode active")
      @transport.should_receive(:command).with("port-channel-protocol lacp")
      interface.update(old_params, new_params)
    end

    it 'should change mtu size' do
      name = 'TenGigabitEthernet 0/5'
      interface = PuppetX::Force10::Model::Interface.new(@transport, @config, {:name=>name})
      interface.retrieve
      old_params = interface.params_to_hash
      new_params = old_params.dup
      new_params[:mtu] = 12000
      @transport.should_receive(:command).with("mtu 12000")
      interface.update(old_params, new_params)
    end

    it 'should setup spanning-tree portfast' do
      name = 'TenGigabitEthernet 0/6'
      interface = PuppetX::Force10::Model::Interface.new(@transport, @config, {:name=>name})
      interface.retrieve
      old_params = interface.params_to_hash
      new_params = old_params.dup
      new_params[:portfast] = 'portfast'
      @transport.should_receive(:command).with('spanning-tree 0 portfast')
      interface.update(old_params, new_params)
    end

    it 'should setup spanning-tree portfast' do
      name = 'TenGigabitEthernet 0/7'
      interface = PuppetX::Force10::Model::Interface.new(@transport, @config, {:name=>name})
      interface.retrieve
      old_params = interface.params_to_hash
      new_params = old_params.dup
      new_params[:edge_port] = 'pvst'
      @transport.should_receive(:command).with("show config")
      @transport.should_receive(:command).with("config")
      @transport.should_receive(:command).with("interface TenGigabitEthernet 0/7")
      @transport.should_receive(:command).with("spanning-tree pvst edge-port")
      interface.update(old_params, new_params)
    end
  end
end

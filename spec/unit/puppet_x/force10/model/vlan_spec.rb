#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet_x/force10/model'
require 'puppet_x/force10/model/vlan'

describe PuppetX::Force10::Model::Vlan do

  before do
    @config = File.read('spec/fixtures/config.out')
    @transport = double('transport').as_null_object
    @transport.stub(:command)
    @transport.stub(:command).with('sh run', :cache => true, :noop => false).and_return(@config)
    @transport.stub(:command).with('show running-config interface', :cache => true, :noop => false).and_return(@config)
    PuppetX::Force10::Transport::Ssh.any_instance.stub(:send).and_return("")
    PuppetX::Force10::Model::Vlan.any_instance.stub(:before_update)
    PuppetX::Force10::Model::Vlan.any_instance.stub(:after_update)
  end

  describe 'when looking up a vlan' do
    it 'finds existing vlan' do
      name = '1'
      vlan = PuppetX::Force10::Model::Vlan.new(@transport, @config, {:name=>name})
      params = vlan.retrieve
      params[:ensure].should == :present
    end
  end

  describe 'when configuration needs updating' do
    it 'should set shutdown' do
      name = '2'
      vlan = PuppetX::Force10::Model::Vlan.new(@transport, @config, {:name=>name})
      vlan.retrieve
      old_params = vlan.params_to_hash
      new_params = old_params.dup
      new_params[:shutdown] = :false
      @transport.should_receive(:command).with('no shutdown')
      vlan.update(old_params, new_params)
    end

    it 'should set mtu' do
      name = '2'
      vlan = PuppetX::Force10::Model::Vlan.new(@transport, @config, {:name=>name})
      vlan.retrieve
      old_params = vlan.params_to_hash
      new_params = old_params.dup
      new_params[:mtu] = 11000
      @transport.should_receive(:command).with('mtu 11000')
      vlan.update(old_params, new_params)
    end

    it 'should correctly set tagged interfaces' do
      name = '2'
      vlan = PuppetX::Force10::Model::Vlan.new(@transport, @config, {:name=>name})
      vlan.retrieve
      old_params = vlan.params_to_hash
      new_params = old_params.dup
      new_params[:tagged_tengigabitethernet] = '0/2'
      @transport.should_receive(:command).with('tagged TenGigabitEthernet 0/2')
      @transport.should_receive(:command).with('no untagged TenGigabitEthernet 0/2')
      vlan.update(old_params, new_params)
    end

    it 'should correctly set untagged interfaces' do
      name = '20'
      vlan = PuppetX::Force10::Model::Vlan.new(@transport, @config, {:name=>name})
      vlan.retrieve
      old_params = vlan.params_to_hash
      new_params = old_params.dup
      new_params[:untagged_tengigabitethernet] = '0/6'
      @transport.should_receive(:command).with('no tagged TenGigabitEthernet 0/6')
      @transport.should_receive(:command).with('untagged TenGigabitEthernet 0/6')
      vlan.update(old_params, new_params)
    end

    it 'should correctly set tagged portchannel' do
      name = '2'
      vlan = PuppetX::Force10::Model::Vlan.new(@transport, @config, {:name=>name})
      vlan.retrieve
      old_params = vlan.params_to_hash
      new_params = old_params.dup
      new_params[:tagged_portchannel] = '128'
      @transport.should_receive(:command).with('no untagged Port-channel 128')
      @transport.should_receive(:command).with('tagged Port-channel 128')
      vlan.update(old_params, new_params)
    end

    it 'should correctly set untagged portchannel' do
      name = '2'
      vlan = PuppetX::Force10::Model::Vlan.new(@transport, @config, {:name=>name})
      vlan.retrieve
      old_params = vlan.params_to_hash
      new_params = old_params.dup
      new_params[:untagged_portchannel] = '128'
      @transport.should_receive(:command).with('no tagged Port-channel 128')
      @transport.should_receive(:command).with('untagged Port-channel 128')
      vlan.update(old_params, new_params)
    end

    it 'should correctly set fc-map' do
      name = '2'
      vlan = PuppetX::Force10::Model::Vlan.new(@transport, @config, {:name=>name})
      vlan.retrieve
      old_params = vlan.params_to_hash
      new_params = old_params.dup
      new_params[:fc_map] = 'test'
      @transport.should_receive(:command).with('fip-snooping fc-map test', {:prompt=>/Changing fc-map deletes sessions using it.*/})
      @transport.should_receive(:command).with('fip-snooping enable')
      vlan.update(old_params, new_params)
    end
  end
end

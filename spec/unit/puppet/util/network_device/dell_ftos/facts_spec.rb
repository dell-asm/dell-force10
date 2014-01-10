#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/util/network_device'
require 'puppet/util/network_device/dell_ftos/facts'

describe Puppet::Util::NetworkDevice::Dell_ftos::Facts do

  before(:each) do
    @transport = stub_everything 'transport'
    @facts = Puppet::Util::NetworkDevice::Dell_ftos::Facts.new(@transport)
  end

  describe "when parsing the output of 'show version'" do
    ["s-series","m-series"].each do |switch_type|
      it "should parse the output for switchtype #{switch_type}" do
        out = File.read(File.join(File.dirname(__FILE__), "fixtures/show_version/#{switch_type}.out"))
        #print "command output: "+out
        expected = YAML.load_file(File.join(File.dirname(__FILE__), "fixtures/show_version/#{switch_type}.yaml"))
        @transport.stubs(:command).with("show version", {:cache => true, :noop => false}).returns(out)
        @facts.retrieve.should == expected
      end
    end
  end

  describe "when parsing the output of 'show inventory'" do
    ["s-series","m-series"].each do |switch_type|
      it "should parse the output for switchtype #{switch_type}" do
        out = File.read(File.join(File.dirname(__FILE__), "fixtures/show_inventory/#{switch_type}.out"))
        #print "command output: "+out
        expected = YAML.load_file(File.join(File.dirname(__FILE__), "fixtures/show_inventory/#{switch_type}.yaml"))
        @transport.stubs(:command).with("show inventory", {:cache => true, :noop => false}).returns(out)
        @facts.retrieve.should == expected
      end
    end
  end

end

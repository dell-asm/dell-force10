#! /usr/bin/env ruby

require 'spec_helper'

describe Puppet::Type.type(:force10_interface) do

  let :resource do
    described_class.new(
    :name        => 'te 0/6',
    :switchport  => 'true',
    :portchannel => '124',
    :mtu         => '600',
    :shutdown    => 'true'
    )
  end

  it "should have a 'name' parameter'" do
    described_class.new(:name => 'te 0/6')[:name].should == 'te 0/6'
  end

  #  it "should be applied on device" do
  #    described_class.new(:name => resource.name).must be_appliable_to_device
  #  end

  describe "when validating attributes" do
    [ :name ].each do |param|
      it "should have a #{param} param" do
        described_class.attrtype(param).should == :param
      end
    end

    [ :switchport, :portchannel, :mtu,:shutdown ].each do |property|
      it "should have a #{property} property" do
        described_class.attrtype(property).should == :property
      end
    end
  end

  describe "when validating attribute values" do
  

    describe "for name" do
      it "should allow a valid interface name" do
        resource.name.should eq( 'te 0/6')
      end
    end
 describe "for portchannel" do
      it "should allow a valid portchannel " do
        described_class.new(:name => resource.name, :portchannel => '124')[:portchannel].should == '124'
        end
    end

describe 'for portchannelinvalid input ' do

      it "should raise an exception on everything else" do
        expect { described_class.new(:name => resource.name, :portchannel=> 'xyz') }.to raise_error
        expect { described_class.new(:name => resource.name, :portchannel=> '130') }.to raise_error
        expect { described_class.new(:name => resource.name, :portchannel=> '0') }.to raise_error
       
      end
    end

 describe "for mtu " do
      it "should allow a valid mtu" do
        described_class.new(:name => resource.name, :mtu => '600')[:mtu].should == '600'
        end
    end
describe 'for mtu  invalid input ' do

      it "should raise an exception on everything else" do
        expect { described_class.new(:name => resource.name, :mtu => 'xyz') }.to raise_error
        expect { described_class.new(:name => resource.name, :mtu => '500') }.to raise_error
        expect { described_class.new(:name => resource.name, :mtu=> '13000') }.to raise_error
       
      end
    end


    describe 'for shutdown' do
      [ :true, :false ].each do |val|
        it "should allow the value #{val.inspect}" do
          described_class.new(:name => resource.name, :shutdown => val)
        end
      end

      it "should raise an exception on everything else" do
        expect { described_class.new(:name => resource.name, :shutdown => :foobar) }.to raise_error
      end
    end

    describe 'for switchport' do
      [ :true, :false ].each do |val|
        it "should allow the value #{val.inspect}" do
          described_class.new(:name => resource.name, :switchport => val)
        end
      end

      it "should raise an exception on everything else" do
        expect { described_class.new(:name => resource.name, :switchport => :foobar) }.to raise_error
      end
    end

  end

end

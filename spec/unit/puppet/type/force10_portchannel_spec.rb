require 'spec_helper'

describe Puppet::Type.type(:force10_portchannel) do
  let(:title) { 'force10_portchannel' }

   let :resource do
    described_class.new(
		:name          		=> 1,
		:desc        		=> 'vlan test spec',
		:mtu				=> 600,
		:switchport		 	=> 'true',
		:shutdown			=> 'false'
    )
   end

  context 'should compile with given test params' do
    it do
      expect {
        should compile
      }
    end
  end

    it "should have name as one of its parameters" do
      described_class.key_attributes.should == [:name]
    end 
    
    describe "when validating attributes" do   
      [:name].each do |param|
	 it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
     end
    [:desc, :mtu, :shutdown, :switchport].each do |property|
     it "should have a #{property} property" do
        described_class.attrtype(property).should == :property
      end
    end	  
  end
  
  describe "when validating values" do
  
    describe "for name" do
      it "should allow a valid port channel name" do
        described_class.new(:name => '1')[:name].should == '1'
      end

      it "should allow a valid port channel" do
        described_class.new(:name => '128')[:name].should == '128'
      end
	  
	  it "should not allow something else" do
        expect { described_class.new(:name => '200') }.to raise_error Puppet::Error, /An invalid 'portchannel' value is entered. The 'portchannel' value must be between 1 and 128./
      end
    end
  end
end
require 'spec_helper'

describe Puppet::Type.type(:force10_firmwareupdate) do
  let(:title) { 'force10_firmwareupdate' }

   let :resource do
    described_class.new(
		:name          		=> 'firmwareupdate',
		:url    	=> 'tftp://172.152.0.89/Force10/FTOS-SE-9.2.0.2.bin',
		:force		=> false,
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
      [:name,:force].each do |param|
	 it "should hava a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
     end
    [:url].each do |property|
     it "should have a #{property} property" do
        described_class.attrtype(property).should == :property
      end
    end	  
  end
end


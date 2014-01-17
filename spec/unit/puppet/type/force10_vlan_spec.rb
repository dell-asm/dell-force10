require 'spec_helper'

describe Puppet::Type.type(:force10_vlan) do
  let(:title) { 'force10_vlan' }

   let :resource do
    described_class.new(
		:name          		=> 1,
		:vlan_name          => 'vlantest',
		:desc        		=> 'vlan test spec',
		:mtu				=> 'absent',
		:shutdown			=> 'false',
		:tagged_tengigabitethernet  	=> '',
		:tagged_fortygigabitethernet	=> '',
		:tagged_portchannel		 		=> '',
		:tagged_gigabitethernet		 	=> '',
		:tagged_sonet		 			=> '',
		:untagged_tengigabitethernet	=> '',
		:untagged_fortygigabitethernet	=> '',
		:untagged_portchannel		 	=> '',
		:untagged_gigabitethernet		=> '',
		:untagged_sonet		 			=> ''
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
    [:vlan_name, :desc, :mtu, :shutdown, :tagged_tengigabitethernet, :tagged_fortygigabitethernet, :tagged_portchannel, :tagged_gigabitethernet, :tagged_sonet, :untagged_tengigabitethernet, :untagged_fortygigabitethernet, :untagged_portchannel, :untagged_gigabitethernet, :untagged_sonet].each do |property|
     it "should have a #{property} property" do
        described_class.attrtype(property).should == :property
      end
    end	  
  end
end


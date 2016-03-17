require 'puppet_x/force10/model/scoped_value'

describe PuppetX::Force10::Model::ScopedValue do
  let(:sv) { PuppetX::Force10::Model::ScopedValue.new("name", double("transport"), double("facts"), nil) }

  describe "#parseforerror" do
    it "should not raise on duplicate name errors" do
      sv.parseforerror("Error: Name already exists.", "add the property value for the parameter 'name'")
    end

    it "should raise for other errors" do
      expect {
        sv.parseforerror("Error: rspec error.", "add the property value for the parameter 'name'")
      }.to raise_error("Unable to add the property value for the parameter 'name'.Reason:rspec error.")
    end
  end

  describe "#parse_interface_value" do
    it "should return list of 3 interfaces" do
      interface_value = "0/1,3,5"
      expect(sv.parse_interface_value(interface_value)).to eq(["0/1","0/3","0/5"])
    end

    it "should return list of 1 interfaces" do
      interface_value = "0/1"
      expect(sv.parse_interface_value(interface_value)).to eq(["0/1"])
    end

    it "should return list of 2 interfaces" do
      interface_value = "0/1,1/2"
      expect(sv.parse_interface_value(interface_value)).to eq(["0/1","1/2"])
    end

    it "should return correct list when various stacks" do
      interface_value = "1,2,1/3,2/3"
      expect(sv.parse_interface_value(interface_value)).to eq(["0/1","0/2","1/3","2/3"])
    end
  end
end

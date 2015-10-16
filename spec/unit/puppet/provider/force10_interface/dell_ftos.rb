require 'rspec/expectations'
require 'json'
require 'puppet'

describe Puppet::Type.type(:force10_interface).provider(:dell_ftos) do
  let(:resource) {Puppet::Type.type(:force10_interface).new(
                                                          {
                                                              :name => 'Tengigabitethernet0/1',
                                                              # :switchport => 'true',
                                                              # :shutdown => 'false',
                                                              # :portmode => 'hybrid',
                                                              # :portfast => 'portfast',
                                                              # :edge_port => 'edge-port',
                                                              # :mtu => '12000',
                                                              # :protocol => 'lldp',
                                                              :ensure => 'absent'
                                                          }
  )}

  let(:provider) {resource.provider}

  before :each do
    @fixture_dir = File.join(Dir.pwd, 'spec', 'fixtures')
    @ifaces_to_destroy = {
        "16"=>["tagged_tengigabit"],
        "18"=>["untagged_tengigabit"],
        "20"=>["tagged_tengigabit"],
        "23"=>["tagged_tengigabit"],
        "24"=>["tagged_tengigabit"],
        "28"=>["tagged_tengigabit"]
    }
    @iface = '0/1'
  end

  describe '#destroy' do
    it 'issue vlan teardown commands' do
      session = double('session')
      transport = double('transport')
      provider.stub(:get_interfaces_to_destroy).and_return(@ifaces_to_destroy)
      provider.stub(:get_iface).and_return(@iface)
      provider.stub(:transport).and_return(transport)
      transport.stub(:session).and_return(session)
      session.should_receive(:command).once.ordered.with('configure', {:prompt=>/\(conf\)#\s?\z/n})
      session.should_receive(:command).once.ordered.with('interface vlan 16', :prompt => /\(conf-if-vl-16\)#\s?\z/n)
      session.should_receive(:command).once.ordered.with('no tagged tengigabitethernet 0/1')
      session.should_receive(:command).once.ordered.with('exit')
      session.should_receive(:command).once.ordered.with('interface vlan 18', :prompt => /\(conf-if-vl-18\)#\s?\z/n)
      session.should_receive(:command).once.ordered.with('no untagged tengigabitethernet 0/1')
      session.should_receive(:command).once.ordered.with('exit')
      session.should_receive(:command).once.ordered.with('interface vlan 20', :prompt => /\(conf-if-vl-20\)#\s?\z/n)
      session.should_receive(:command).once.ordered.with('no tagged tengigabitethernet 0/1')
      session.should_receive(:command).once.ordered.with('exit')
      session.should_receive(:command).once.ordered.with('interface vlan 23', :prompt => /\(conf-if-vl-23\)#\s?\z/n)
      session.should_receive(:command).once.ordered.with('no tagged tengigabitethernet 0/1')
      session.should_receive(:command).once.ordered.with('exit')
      session.should_receive(:command).once.ordered.with('interface vlan 24', :prompt => /\(conf-if-vl-24\)#\s?\z/n)
      session.should_receive(:command).once.ordered.with('no tagged tengigabitethernet 0/1')
      session.should_receive(:command).once.ordered.with('exit')
      session.should_receive(:command).once.ordered.with('interface vlan 28', :prompt => /\(conf-if-vl-28\)#\s?\z/n)
      session.should_receive(:command).once.ordered.with('no tagged tengigabitethernet 0/1')
      session.should_receive(:command).once.ordered.with('exit')
      session.should_receive(:command).once.ordered.with('exit')

      provider.destroy
    end
  end

  describe 'check_for_interface' do
    context 'when m_series device' do
      context 'when vlan contains interface' do
        it 'returns hash with list where interface exists' do
          iface = '0/1'
          type = 'tengigabit'
          vlan_data = eval(File.read(File.join(@fixture_dir,'vlan_information')))
          vlan_info = JSON.parse(vlan_data)
          vlans_to_remove = provider.check_for_interface(vlan_info, iface, type)
          expected_result = {
              "16"=>["tagged_tengigabit"],
              "18"=>["untagged_tengigabit"],
              "20"=>["tagged_tengigabit"],
              "23"=>["tagged_tengigabit"],
              "24"=>["tagged_tengigabit"],
              "28"=>["tagged_tengigabit"]
          }
          expect(vlans_to_remove).to eq(expected_result)
        end
      end
      context 'when vlans do not contain interface' do
        it 'returns empty hash' do
          iface = '0/7'
          type = 'tengigabit'
          vlan_data = eval(File.read(File.join(@fixture_dir,'vlan_information')))
          vlan_info = JSON.parse(vlan_data)
          vlans_to_remove = provider.check_for_interface(vlan_info, iface, type)
          expect(vlans_to_remove).to eq({})
        end
      end
    end
    context 'when s_series device' do
      context 'when vlan contains interfaces' do
        it 'returns hash with list where interface exists' do
          iface = '0/16'
          type = 'tengigabit'
          vlan_data = eval(File.read(File.join(@fixture_dir,'vlan_information_s')))
          vlan_info = JSON.parse(vlan_data)
          vlans_to_remove = provider.check_for_interface(vlan_info, iface, type)
          expected_results = {
              "1"=>["tagged_tengigabit"],
              "17"=>["tagged_tengigabit"],
              "18"=>["tagged_tengigabit"],
              "20"=>["tagged_tengigabit"],
              "22"=>["tagged_tengigabit"],
              "23"=>["tagged_tengigabit"],
              "25"=>["tagged_tengigabit"],
              "27"=>["tagged_tengigabit"],
              "28"=>["tagged_tengigabit"]
          }
          expect(vlans_to_remove).to eq(expected_results)
        end
      end
      context 'when vlans do not contain interface' do
        it 'returns empty hash' do
          iface = '0/1'
          type = 'tengigabit'
          vlan_data = eval(File.read(File.join(@fixture_dir,'vlan_information_s')))
          vlan_info = JSON.parse(vlan_data)
          vlans_to_remove = provider.check_for_interface(vlan_info, iface, type)
          expect(vlans_to_remove).to eq({})
        end
      end
    end
  end
end
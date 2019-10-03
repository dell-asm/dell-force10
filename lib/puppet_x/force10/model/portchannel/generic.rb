# This module exists because between IOAs and MXL/ToR, there are differences
# in how the portchannel is configured (notably with VLANs). There is enough
# similarity though in some settings that it doesn't make much sense to copy/paste
# the code in both portchannel and ioa_portchannel. So we put the parameters that
# can be configured the same between the different switches here, and add the
# non-generic ones in the specific models.
module PuppetX::Force10::Model::Portchannel::Generic
  def register_main_params(base)
    general_scope = /^(interface\s+Port-channel\s+(\d+).*?shutdown)/m
    general_cmd = "show running-config interface po %s" % base.name
    portchannelval = base.name

    base.register_scoped :ensure, general_scope do
      match do |txt|
        txt.nil? ? :absent : :present
      end
      cmd general_cmd
      default :absent
      add { |*_| }
      remove { |*_| }
    end

    base.register_scoped :mtu, general_scope do
      match /mtu (\d+)/
      cmd general_cmd
      default :absent
      add do |transport, value|
        transport.command("mtu #{value}")
      end
      remove { |*_| }
    end

    base.register_scoped :shutdown, general_scope do
      cmd general_cmd
      match do |txt|
        txt.scan(/^Port-channel (\d+) is up/).flatten.first || :absent
      end
      default :absent
      add do |transport, value|
        if value == :false
          transport.command("no shutdown")
        else
          transport.command("shutdown")
        end
      end
      remove { |*_| }
    end

    base.register_scoped :portmode, general_scope do
      cmd general_cmd
      match /^\s*portmode\s+(.*?)\s*$/
      add do |transport, value|
        #transport.command("fabric #{value}")
        #Remove existing config to allow to set portmode
        existing_config=(transport.command('show config') || '').split("\n").reverse
        updated_config = existing_config.find_all {|x| x.match(/dcb|switchport|spanning|vlan|portmode|vlt-peer-lag/)}
        updated_config.each do |remove_command|
          transport.command("no #{remove_command}")
        end
        transport.command('portmode hybrid')
        updated_config.reverse.each do |remove_command|
          transport.command("#{remove_command}")
        end
      end
    end

    base.register_scoped :switchport, general_scope do
      after :portmode
      cmd general_cmd
      match do |txt|
        txt =~ /switchport/ ? :true : :false
      end
      add do |transport, value|
        if value == :false
          transport.command("no switchport")
        else
          transport.command("portmode hybrid") unless base.params[:untagged_vlan].value == "none"
          transport.command("switchport")
        end
      end
      remove { |*_| }
    end

    base.register_scoped :fip_snooping_fcf, general_scope do
      match do |txt|
        txt =~ /fip-snooping port-mode fcf/ ? :true : :false
      end
      cmd general_cmd
      default :absent
      add do |transport, value|
        if value == :true
          transport.command("fip-snooping port-mode fcf")
        else
          transport.command("no fip-snooping port-mode fcf")
        end
      end
      remove { |*_| }
    end


    base.register_scoped :desc, general_scope do
      match do |txt|
        paramsarray=txt.match(/^Description: (.*)/)
        if paramsarray.nil?
          param1 = :absent
        else
          param1 = paramsarray[1]
        end
        param1
      end

      cmd general_cmd
      add do |transport, value|
        transport.command("desc #{value}")
      end
      remove { |*_| }
    end

    base.register_scoped :fcoe_map, general_scope do
      match do |txt|
        paramsarray=txt.match(/^fcoe-map\s+(\S+)/)
        if paramsarray.nil?
          param1 = :absent
        else
          param1 = paramsarray[1]
        end
        param1
      end

      cmd general_cmd
      add do |transport, value|
        transport.command("fcoe-map #{value}")
      end
      remove { |*_| }
    end

    base.register_scoped :vltpeer, general_scope do
      match do |txt|
        txt =~ /vlt-peer-lag port-channel (#{portchannelval})/ ? :true : :false
      end

      cmd general_cmd
      add do |transport, value|
        if value == :true
          transport.command("vlt-peer-lag po#{portchannelval}")
        end
      end
      remove { |*_| }
    end

    base.register_scoped(:ungroup, /(^lacp ungroup member-independent port-channel (\d)+)$/) do
      match do |txt|
        txt =~ /port-channel (#{portchannelval}$)/ ? :true : :false
      end
      cmd "show running-config | grep member-independent"
      add do |transport, _|
        # Needs to be configured at top level configuration mode
        transport.command("exit")
        transport.command("lacp ungroup member-independent port-channel %s" % portchannelval)
        transport.command("interface port-channel %s" % portchannelval)
      end
      default :false

      remove do |transport, _|
        transport.command("exit")
        transport.command("no lacp ungroup member-independent port-channel %s" % portchannelval)
        transport.command("interface port-channel %s" % portchannelval)
      end
    end

    base.register_scoped(:portfast, general_scope) do
      cmd general_cmd
      match /^\s*spanning-tree 0 (.*?)\s*$/
      add do |transport, value|
        transport.command("spanning-tree 0 #{value}")
      end
      remove { |*_| }
    end

    base.register_scoped(:edge_port, general_scope) do
      cmd general_cmd
      match /^\s*spanning-tree pvst\s+(.*?)\s*$/
      add do |transport, value|
        value = value.split(",")
        stp_val = PuppetX::Force10::Model::Interface::Base.show_stp_val(transport, scope_name)
        PuppetX::Force10::Model::Interface::Base.update_stp(transport, scope_name, stp_val, value)
      end
      remove { |*_| }
    end
  end
end
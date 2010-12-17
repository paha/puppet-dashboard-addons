#!/usr/bin/env ruby
#
# Remove prod groups and nodes from lab dashboard

require 'spk_dashboard'

SpkDashboard::SPK_POPS.each do |pop|
    group = SpkDashboard::LoadData.get_group_obj( pop )

    puts "Will remove nodes for #{pop} and nodes in the group."

    group.nodes.each do |node|
        puts SpkDashboard::LoadData.rm_node( node.name )
    end

    if group.destroy
        puts "Removed #{group.name}."
    else
        puts "FAILED to remove #{group.name}."
    end
end
